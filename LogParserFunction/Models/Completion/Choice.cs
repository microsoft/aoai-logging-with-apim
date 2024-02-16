// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.Completion;

/// <summary>
/// Completion Choice
/// </summary>
public class Choice
{
    [JsonProperty("finish_reason")]
    public string FinishReason { get; set; } = string.Empty;

    [JsonProperty("index")]
    public int Index { get; set; }

    [JsonProperty("content_filter_results")]
    public ContentFilterResults ContentFilterResults { get; set; } = new();

    [JsonProperty("text")]
    public string Text { get; set; } = string.Empty;

    [JsonProperty("logprobs")]
    public int? Logprobs { get; set; }
}
