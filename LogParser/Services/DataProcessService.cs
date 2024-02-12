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
    ContentSafetyService contentSafetyService,
    Container container)
{
    private readonly TikTokenService tikTokenService = tikTokenService;
    private readonly ResultCacheService resultCacheService = resultCacheService;
    private readonly ContentSafetyService contentSafetyService = contentSafetyService;
    private readonly Container container = container;

    /// <summary>
    /// Process the data from Event Hub
    /// </summary>
    /// <param name="args"></param>
    /// <returns></returns>
    public async Task ProcessEventAsync(ProcessEventArgs args)
    {
        string eventBody = Encoding.UTF8.GetString(args.Data.EventBody);
        if (string.IsNullOrEmpty(eventBody) || eventBody.Count() < 5)
        {
            await args.UpdateCheckpointAsync();
            return;
        }

        string requestId = eventBody;// JToken.Parse(eventBody.Split("EventHubLog")[1])["RequestId"].ToString();
        QueryDefinition query = new(query: $"SELECT StringToObject(c.Properties.TempLog) AS TempLog FROM c WHERE c.requestId = '{requestId}'");
        using FeedIterator<JToken> feed = container.GetItemQueryIterator<JToken>(
            queryDefinition: query
        );
        List<JToken> items = new();
        while (feed.HasMoreResults)
        {
            FeedResponse<JToken> docs = await feed.ReadNextAsync();
            foreach (JToken doc in docs)
            {
                items.Add(doc);
            }
        }
        TempRequestLog? tempRequestLog = new();
        long elapsed = 0;
        int statusCode = 0;
        string statusReason = string.Empty;
        Request? request = new();
        Response? response = new();
        StringBuilder sb = new();
        foreach (JToken item in items)
        {
            if (item["TempLog"]["type"].ToString() == "Request")
            {
                tempRequestLog = JsonConvert.DeserializeObject<TempRequestLog>(item["TempLog"].ToString());
                request = item["TempLog"].ToString().GetRequest();
            }
            else if (item["TempLog"]["type"].ToString() == "Response")
            {
                TempResponseLog tempResponseLog = JsonConvert.DeserializeObject<TempResponseLog>(item["TempLog"].ToString());
                elapsed = tempResponseLog.Headers!["Elasped"];
                statusCode = tempResponseLog.Headers!["Status-Code"];
                statusReason = tempResponseLog.Headers!["Status-Reason"];
                response = await item["TempLog"].ToString().GetResponse(request!, tikTokenService, contentSafetyService);
            }
            else if (item["TempLog"]["type"].ToString() == "StreamResponse")
            {
                TempStreamResponseLog tempStreamResponseLog = JsonConvert.DeserializeObject<TempStreamResponseLog>(item["TempLog"].ToString());
                elapsed = tempStreamResponseLog.Headers!["Elasped"];
                statusCode = tempStreamResponseLog.Headers!["Status-Code"];
                statusReason = tempStreamResponseLog.Headers!["Status-Reason"];
                sb.Append(item["TempLog"]["response"].ToString()+ "\n\n");
            }
        }

        if(sb.Length > 0)
        {
            JObject token = new();
            token["response"] = sb.ToString();
            response = await token.ToString().GetResponse(request!, tikTokenService, contentSafetyService);
        }

        AOAILog aoaiLog = new()
        {
            ApiName = tempRequestLog.Headers!["Api-Name"],
            ApiRevision = tempRequestLog.Headers!["Api-Revision"],
            Elapsed = elapsed,
            Method = tempRequestLog.Headers!["Method"],
            Headers = tempRequestLog.Headers,
            OperationId = tempRequestLog.Headers!["Operation-Id"],
            OperationName = tempRequestLog.Headers!["Operation-Name"],
            Region = tempRequestLog.Headers!["Region"],
            RequestId = tempRequestLog.Headers!["Request-Id"],
            RequestIp = tempRequestLog.Headers!["Request-Ip"],
            Request = request!,
            Response = response!,
            ServiceName = tempRequestLog.Headers!["Service-Name"],
            SubscriptionId = tempRequestLog.Headers!["Subscription-Id"],
            SubscriptionName = tempRequestLog.Headers!["Subscription-Name"],
            StatusCode = statusCode,
            StatusReason = statusReason,
            Timestamp = tempRequestLog.Headers!["Timestamp"],
            Url = tempRequestLog.Headers!["Request-Url"]
        };

        // Send the log to WriteTo destinations.
        // As Serilog serializer cannot serialize dynamic type very well, we serialize the result here.
        // In Application Insights, you don't need to parse but for cosmos Db, you need to parse the json.
        Log.Logger.Debug("{@AOAILog}", JsonConvert.SerializeObject(aoaiLog, new JsonSerializerSettings() { NullValueHandling = NullValueHandling.Ignore }));

        //resultCacheService.RemoveRequestLog(eventHubResponseLog.RequestId);
        await args.UpdateCheckpointAsync();

        var res = await container.DeleteAllItemsByPartitionKeyStreamAsync(new PartitionKey(requestId));

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
