// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

/// <summary>
/// Final log format to logging to Cosmos DB and Log Analytics Workspace
/// </summary>
public class AOAILog
{
    [JsonProperty("apiName")]
    public string ApiName { get; set; } = string.Empty;

    [JsonProperty("apiRevision")]
    public string ApiRevision { get; set; } = string.Empty;

    [JsonProperty("elapsed")]
    public double Elapsed { get; set; }

    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }
    
    [JsonProperty("method")]
    public string Method { get; set; } = string.Empty;

    [JsonProperty("operationId")]
    public string OperationId { get; set; } = string.Empty;
 
    [JsonProperty("operationName")]
    public string OperationName { get; set; } = string.Empty;
    
    [JsonProperty("region")]
    public string Region { get; set; } = string.Empty;

    [JsonProperty("request")]
    public Request Request { get; set; } = new();

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("requestIp")]
    public string RequestIp { get; set; } = string.Empty;

    [JsonProperty("response")]
    public Response Response { get; set; } = new();

    [JsonProperty("serviceName")]
    public string ServiceName { get; set; } = string.Empty;

    [JsonProperty("statusCode")]
    public int StatusCode { get; set; }

    [JsonProperty("statusReason")]
    public string StatusReason { get; set; } = string.Empty;

    [JsonProperty("subscriptionId")]
    public string SubscriptionId { get; set; } = string.Empty;

    [JsonProperty("subscriptionName")]
    public string SubscriptionName { get; set; } = string.Empty;
    
    [JsonProperty("timestamp")]
    public string Timestamp { get; set; } = string.Empty;

    [JsonProperty("url")]
    public string Url { get; set; } = string.Empty;
}