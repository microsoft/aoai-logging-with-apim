// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Services;

/// <summary>
/// DataProcess Service that process the data from Event Hub
/// </summary>
/// <param name="tikTokenService">TikTokenService</param>
/// <param name="resultCacheService">ResultCacheService</param>
public class DataProcessService(
    TikTokenService tikTokenService, 
    ResultCacheService resultCacheService,
    ContentSafetyService contentSafetyService)
{
    private readonly TikTokenService tikTokenService = tikTokenService;
    private readonly ResultCacheService resultCacheService = resultCacheService;
    private readonly ContentSafetyService contentSafetyService = contentSafetyService;

    /// <summary>
    /// Process the data from Event Hub
    /// </summary>
    /// <param name="args"></param>
    /// <returns></returns>
    public async Task ProcessEventAsync(ProcessEventArgs args)
    {
        string eventBody = Encoding.UTF8.GetString(args.Data.EventBody);

        // There is a size limitation from APIM policy to Eventhub.
        // https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-log-event-hubs?tabs=PowerShell
        // If the size is larger than 200 KB, then we won't parse it.
        if (eventBody.Length > 200000)
        {
            await args.UpdateCheckpointAsync();
            return;
        }
        EventHubRequestLog? eventHubRequestLogData = JsonConvert.DeserializeObject<EventHubRequestLog>(eventBody);
        
        if (eventHubRequestLogData is null)
        {
            await args.UpdateCheckpointAsync();
            return;
        }

        eventHubRequestLogData.Request = eventBody.GetRequest();

        // Store the request data so that we can add it to the AOAILog later.
        if (eventHubRequestLogData.Type == "Request")
        {
            if (eventHubRequestLogData.Request is null)
            {
                await args.UpdateCheckpointAsync();
                return; 
            }

            resultCacheService.StoreRequestLog(eventHubRequestLogData);
            return;
        }
               
        EventHubResponseLog? eventHubResponseLog = JsonConvert.DeserializeObject<EventHubResponseLog>(eventBody);

        if (eventHubResponseLog is null || eventHubResponseLog.Response is null)
        {
            await args.UpdateCheckpointAsync();
            return;
        }

        // Restore the request by using the Request Id.
        EventHubRequestLog? cachedRequestLog = resultCacheService.GetRequestLog(eventHubResponseLog.RequestId);
        
        if (cachedRequestLog is null || cachedRequestLog.Request is null)
        {
            await args.UpdateCheckpointAsync();
            return;
        }

        Response? response = await eventBody.GetResponse(cachedRequestLog.Request, tikTokenService, contentSafetyService);

        if (response is null)
        {
            await args.UpdateCheckpointAsync();
            return;
        }

        AOAILog aoaiLog = new()
        {
            ApiName = cachedRequestLog.ApiName,
            ApiRevision = cachedRequestLog.ApiRevision,
            Elapsed = TimeSpan.FromTicks(eventHubResponseLog.Elapsed.Ticks).TotalMilliseconds,
            Method = cachedRequestLog.Method,
            Headers = cachedRequestLog.Headers,
            OperationId = cachedRequestLog.OperationId,
            OperationName = cachedRequestLog.OperationName,
            Region = cachedRequestLog.Region,
            RequestId = cachedRequestLog.RequestId,
            RequestIp = cachedRequestLog.RequestIp,
            Request = cachedRequestLog.Request,
            Response = response,
            ServiceName = cachedRequestLog.ServiceName,
            SubscriptionId = cachedRequestLog.SubscriptionId,
            SubscriptionName = cachedRequestLog.SubscriptionName,
            StatusCode = eventHubResponseLog.StatusCode,
            StatusReason = eventHubResponseLog.StatusReason,
            Timestamp = eventHubResponseLog.Timestamp,
            Url = cachedRequestLog.Url,
        };

        // Send the log to WriteTo destinations.
        // As Serilog serializer cannot serialize dynamic type very well, we serialize the result here.
        // In Application Insights, you don't need to parse but for cosmos Db, you need to parse the json.
        Log.Logger.Debug("{@AOAILog}", JsonConvert.SerializeObject(aoaiLog, new JsonSerializerSettings() { NullValueHandling = NullValueHandling.Ignore }));

        resultCacheService.RemoveRequestLog(eventHubResponseLog.RequestId);
        await args.UpdateCheckpointAsync();
        
        return;
    }

    /// <summary>
    /// Log the error when something went wrong.
    /// </summary>
    /// <param name="eventArgs"></param>
    /// <returns></returns>
    public Task ProcessErrorAsync(ProcessErrorEventArgs eventArgs)
    {
        Log.Logger.Error($"""
        Partition '{eventArgs.PartitionId}': an unhandled exception was encountered. This was not expected to happen.
        Exception: {eventArgs.Exception.Message}
        """);
        return Task.CompletedTask;
    }
}
