// Copyright (c) Microsoft. All rights reserved.

using LogParser.Models.ContentSafety;

namespace LogParser.Models.ChatCompletion;

/// <summary>
/// ChatCompletion Response Choice
/// </summary>
public class Choice
{
    [JsonProperty("finish_reason")]
    public string FinishReason { get; set; } = string.Empty;

    [JsonProperty("index")]
    public int Index { get; set; }

    [JsonProperty("message")]
    public Message Message { get; set; } = new();

    [JsonProperty("content_filter_results")]
    public ContentFilterResults ContentFilterResults { get; set; } = new();
}
