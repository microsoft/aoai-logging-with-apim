// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.Embedding;

/// <summary>
/// EmbeddingResponse Response
/// </summary>
public class EmbeddingResponse : Response
{
    // We are not logging embbedded data on purpose
    //[JsonProperty("data")]
    //public string Data { get; set; } = new();
}
