// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion.Stream;

/// <summary>
/// Streaming Choice
/// </summary>
public class Choice
{
    [JsonProperty("finish_reason")]
    public string FinishReason { get; set; } = string.Empty;

    [JsonProperty("index")]
    public int Index { get; set; }

    [JsonProperty("delta")]
    public Message Delta { get; set; } = new();
}
