// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

/// <summary>
/// EventHub log data sent from APIM Response
/// </summary>
public class EventHubResponseLog
{
    [JsonProperty("type")]
    public virtual string Type { get; set; } = string.Empty;

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("timestamp")]
    public string Timestamp { get; set; } = string.Empty;

    [JsonProperty("elapsed")]
    public TimeOnly Elapsed { get; set; }

    [JsonProperty("response")]
    public string? Response { get; set; }

    [JsonProperty("statusCode")]
    public int StatusCode { get; set; }

    [JsonProperty("statusReason")]
    public string StatusReason { get; set; } = string.Empty;
}