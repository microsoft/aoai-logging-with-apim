// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

/// <summary>
/// Temporary Log
/// </summary>
public class TempLog
{
    [JsonProperty("id")]
    public Guid Id { get; set; } 

    [JsonProperty("type")]
    public virtual string Type { get; } = string.Empty;

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }
}