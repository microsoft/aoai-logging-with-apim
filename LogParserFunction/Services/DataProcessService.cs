// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Services;

/// <summary>
/// DataProcess Service that process the data from Event Hub
/// </summary>
/// <param name="tikTokenService">TikTokenService</param>
/// <param name="resultCacheService">ResultCacheService</param>
public class DataProcessService(
    TikTokenService tikTokenService, 
    ContentSafetyService contentSafetyService,
    Container container)
{
    private readonly TikTokenService _tikTokenService = tikTokenService;
    private readonly ContentSafetyService _contentSafetyService = contentSafetyService;
    private readonly Container _container = container;

    /// <summary>
    /// Process the data from Event Hub
    /// </summary>
    /// <param name="inputs"></param>
    /// <returns></returns>
    public async Task<AOAILog?> ProcessEventAsync(string eventBody)
    {
        if (string.IsNullOrEmpty(eventBody) || eventBody.Count() < 5)
        {
            return default;
        }

        string requestId = eventBody;// JToken.Parse(eventBody.Split("EventHubLog")[1])["RequestId"].ToString();
        QueryDefinition query = new(query: $"SELECT * FROM c WHERE c.requestId = '{requestId}'");
        using FeedIterator<JToken> feed = _container.GetItemQueryIterator<JToken>(
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
                elapsed = tempResponseLog.Headers!["Elasped"];
                statusCode = tempResponseLog.Headers!["Status-Code"];
                statusReason = tempResponseLog.Headers!["Status-Reason"];
                response = await item.ToString().GetResponse(request!, _tikTokenService, _contentSafetyService);
            }
            else if (item["type"].ToString() == "StreamResponse")
            {
                TempStreamResponseLog tempStreamResponseLog = JsonConvert.DeserializeObject<TempStreamResponseLog>(item.ToString());
                elapsed = tempStreamResponseLog.Headers!["Elasped"];
                statusCode = tempStreamResponseLog.Headers!["Status-Code"];
                statusReason = tempStreamResponseLog.Headers!["Status-Reason"];
                sb.Append(item["response"].ToString()+ "\n\n");
            }
        }

        Console.WriteLine($"records: {items.Count}");
        if(sb.Length > 0)
        {
            JObject token = new();
            token["response"] = sb.ToString();
            response = await token.ToString().GetResponse(request!, _tikTokenService, _contentSafetyService);
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

        var res = await _container.DeleteAllItemsByPartitionKeyStreamAsync(new PartitionKey(requestId));

        return aoaiLog;
    }
}
