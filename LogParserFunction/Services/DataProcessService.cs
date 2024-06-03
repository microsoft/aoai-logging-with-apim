// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Services;

/// <summary>
/// DataProcess Service that process the data from Cosmos DB
/// </summary>
/// <param name="tikTokenService">TikTokenService</param>
/// <param name="resultCacheService">ResultCacheService</param>
public class DataProcessService(
    TikTokenService tikTokenService, 
    ContentSafetyService contentSafetyService,
    Container container)
{
    private readonly TikTokenService tikTokenService = tikTokenService;
    private readonly ContentSafetyService contentSafetyService = contentSafetyService;
    private readonly Container container = container;

    /// <summary>
    /// Process the log data from Cosmos DB
    /// </summary>
    /// <param name="requestId"></param>
    /// <returns>AOAILog</returns>
    public async Task<AOAILog?> ProcessLogsAsync(string requestId)
    {
        if (string.IsNullOrEmpty(requestId) || requestId.Count() < 5)
        {
            return default;
        }

        QueryDefinition query = new(query: $"SELECT * FROM c WHERE c.requestId = '{requestId}'");
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

        if (!items.Any())
        {
            return default;
        }

        foreach (JToken item in items)
        {
            if (item["type"].ToString() == "Request")
            {
                tempRequestLog = JsonConvert.DeserializeObject<TempRequestLog>(item.ToString());
                request = item.ToString().GetRequest();
            }
            else if (item["type"].ToString() == "Response")
            {
                TempResponseLog tempResponseLog = JsonConvert.DeserializeObject<TempResponseLog>(item.ToString());
                elapsed = tempResponseLog.Headers!["Elapsed"];
                statusCode = tempResponseLog.Headers!["StatusCode"];
                statusReason = tempResponseLog.Headers!["StatusReason"];
                response = await item.ToString().GetResponse(request!, tikTokenService, contentSafetyService);
            }
            else if (item["type"].ToString() == "StreamResponse")
            {
                TempStreamResponseLog tempStreamResponseLog = JsonConvert.DeserializeObject<TempStreamResponseLog>(item.ToString());
                elapsed = tempStreamResponseLog.Headers!["Elapsed"];
                statusCode = tempStreamResponseLog.Headers!["StatusCode"];
                statusReason = tempStreamResponseLog.Headers!["StatusReason"];
                sb.Append(item["response"].ToString()+ "\n\n");
            }
        }

        Console.WriteLine($"records: {items.Count}");
        if(sb.Length > 0)
        {
            JObject token = new();
            token["response"] = sb.ToString();
            response = await token.ToString().GetResponse(request!, tikTokenService, contentSafetyService);
        }

        AOAILog aoaiLog = new()
        {
            ApiName = tempRequestLog.Headers!["ApiName"],
            ApiRevision = tempRequestLog.Headers!["ApiRevision"],
            Elapsed = elapsed,
            Method = tempRequestLog.Headers!["Method"],
            Headers = tempRequestLog.Headers,
            OperationId = tempRequestLog.Headers!["OperationId"],
            OperationName = tempRequestLog.Headers!["OperationName"],
            Region = tempRequestLog.Headers!["Region"],
            RequestId = tempRequestLog.Headers!["RequestId"],
            RequestIp = tempRequestLog.Headers!["RequestIp"],
            Request = request!,
            Response = response!,
            ServiceName = tempRequestLog.Headers!["ServiceName"],
            SubscriptionId = tempRequestLog.Headers!["SubscriptionId"],
            SubscriptionName = tempRequestLog.Headers!["SubscriptionName"],
            StatusCode = statusCode,
            StatusReason = statusReason,
            Timestamp = tempRequestLog.Headers!["Timestamp"],
            Url = tempRequestLog.Headers!["RequestUrl"]
        };

        //https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/how-to-delete-by-partition-key?tabs=dotnet-example
        // Cosmos DB needs to support delete by partition key feature.
        await container.DeleteAllItemsByPartitionKeyStreamAsync(new PartitionKey(requestId));

        return aoaiLog;
    }
}
