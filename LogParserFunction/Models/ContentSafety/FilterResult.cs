// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ContentSafety;

/// <summary>
/// Content Filter Result
/// </summary>
public class FilterResult
{
    [JsonProperty("filtered")]
    public bool Filtered { get; set; }

    [JsonProperty("severity")]
    public string Severity { get; set; } = "safe";
}
