// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ContentSafety;

/// <summary>
/// Content Filter Results
/// </summary>
public class ContentFilterResults
{
    [JsonProperty("hate")]
    public FilterResult Hate { get; set; } = new();

    [JsonProperty("self_harm")]
    public FilterResult SelfHarm { get; set; } = new();

    [JsonProperty("sexual")]
    public FilterResult Sexual { get; set; } = new();

    [JsonProperty("violence")]
    public FilterResult Violence { get; set; } = new();
}
