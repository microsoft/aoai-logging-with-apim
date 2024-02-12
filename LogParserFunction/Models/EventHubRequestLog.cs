// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

/// <summary>
/// EventHub log data sent from APIM Request
/// </summary>
public class EventHubRequestLog
{
    [JsonProperty("type")]
    public virtual string Type { get; set; } = string.Empty;

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("timestamp")]
    public string Timestamp { get; set; } = string.Empty;

    [JsonProperty("subscriptionId")]
    public string SubscriptionId { get; set; } = string.Empty;

    [JsonProperty("subscriptionName")]
    public string SubscriptionName { get; set; } = string.Empty;

    [JsonProperty("operationId")]
    public string OperationId { get; set; } = string.Empty;

    [JsonProperty("request")]
    public Request? Request { get; set; }

    [JsonProperty("serviceName")]
    public string ServiceName { get; set; } = string.Empty;
      
    [JsonProperty("requestIp")]
    public string RequestIp { get; set; } = string.Empty;

    [JsonProperty("url")]
    public string Url { get; set; } = string.Empty;

    [JsonProperty("operationName")]
    public string OperationName { get; set; } = string.Empty;

    [JsonProperty("region")]
    public string Region { get; set; } = string.Empty;

    [JsonProperty("apiName")]
    public string ApiName { get; set; } = string.Empty;

    [JsonProperty("apiRevision")]
    public string ApiRevision { get; set; } = string.Empty;

    [JsonProperty("method")]
    public string Method { get; set; } = string.Empty;

    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }
}