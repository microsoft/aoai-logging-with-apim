// Copyright (c) Microsoft. All rights reserved.

using System.Reflection.Metadata.Ecma335;

namespace LogParser.Models.ChatCompletion;

/// <summary>
/// ChatCompletion Request Message
/// </summary>
public class Tool
{
    [JsonProperty("type")]
    public string Type { get; set; } = string.Empty;

    [JsonProperty("function")]
    public Function Function { get; set; } = new();
}