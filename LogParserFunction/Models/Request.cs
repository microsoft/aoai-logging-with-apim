// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

/// <summary>
/// Request Message
/// </summary>
public class Request
{
    [JsonProperty("id")]
    public string Id { get; set; } = string.Empty;
}