// Copyright (c) Microsoft. All rights reserved.

namespace LoggingWebApi.Models;

/// <summary>
/// Temporary Response Log
/// </summary>
public class TempResponseLog : TempLog
{
    /// <summary>
    /// Log Type
    /// </summary>
    [JsonProperty("type")]
    public override string Type { get; } = "Response";

    /// <summary>
    /// Response
    /// </summary>
    [JsonProperty("response")]
    public JObject Response { get; set; } = new();
}
