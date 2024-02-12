// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.Embedding;

/// <summary>
/// Request Message
/// </summary>
public class EmbeddingRequest : Request
{
    [JsonProperty("input")]
    public string Input { get; set; } = string.Empty;
}