// Copyright (c) Microsoft. All rights reserved.

namespace LoggingWebApp.Models;

/// <summary>
/// Temporary Request Log
/// </summary>
public class TempRequestLog : TempLog
{
    /// <summary>
    /// Log Type
    /// </summary>
    [JsonProperty("type")]
    public override string Type { get; } = "Request";

    /// <summary>
    /// Request
    /// </summary>
    [JsonProperty("request")]
    public JObject Request { get; set; } = new();

    /// <summary>
    /// Request URL
    /// </summary>
    [JsonProperty("requestUrl")]
    public string RequestUrl { get; set; } = string.Empty;
}