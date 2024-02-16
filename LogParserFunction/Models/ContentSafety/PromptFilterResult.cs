// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ContentSafety;

/// <summary>
/// Prompt Filter Result
/// </summary>
public class PromptFilterResult
{
    [JsonProperty("prompt_index")]
    public int PromptIndex { get; set; }

    [JsonProperty("content_filter_results")]
    public ContentFilterResults ContentFilterResults { get; set; } = new();
}