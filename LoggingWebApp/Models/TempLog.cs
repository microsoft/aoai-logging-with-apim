// Copyright (c) Microsoft. All rights reserved.

namespace LoggingWebApp.Models;

/// <summary>
/// Temporary Log
/// </summary>
public class TempLog
{
    /// <summary>
    /// Id for Cosmos DB
    /// </summary>
    [JsonProperty("id")]
    public Guid Id { get; } = Guid.NewGuid();

    /// <summary>
    /// Log Type
    /// </summary>
    [JsonProperty("type")]
    public virtual string Type { get; } = string.Empty;

    /// <summary>
    /// Request Id
    /// </summary>
    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    /// <summary>
    /// Headers
    /// </summary>
    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }
}