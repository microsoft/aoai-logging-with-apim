// Copyright (c) Microsoft. All rights reserved.

namespace LoggingWebApp.Models;

/// <summary>
/// Temporary Stream Response Log
/// </summary>
public class TempStreamResponseLog : TempLog
{
    /// <summary>
    /// Log Type
    /// </summary>
    [JsonProperty("type")]
    public override string Type { get; } = "StreamResponse";

    /// <summary>
    /// Response
    /// </summary>
    [JsonProperty("response")]
    public string Response { get; set; } = string.Empty;
}
