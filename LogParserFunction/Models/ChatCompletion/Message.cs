// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion;

/// <summary>
/// ChatCompletion Request Message
/// </summary>
public class Message
{
    [JsonProperty("content")]
    public dynamic? Content { get; set; }

    [JsonProperty("role")]
    public string Role { get; set; } = string.Empty;

    [JsonProperty("tool_calls")]
    public dynamic? ToolCalls { get; set; }

    [JsonProperty("contentPart")]
    public string? ContentPart { get; set; } 

    [JsonProperty("contentPartImage")]
    public string? ContentPartImage { get; set; }
}