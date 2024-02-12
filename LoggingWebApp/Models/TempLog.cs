// Copyright (c) Microsoft. All rights reserved.

namespace ssetest.Models;

/// <summary>
/// Temporary Log
/// </summary>
public class TempLog
{
    [JsonProperty("type")]
    public virtual string Type { get; } = string.Empty;

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }
}