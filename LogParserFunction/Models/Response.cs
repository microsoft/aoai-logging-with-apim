// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

/// <summary>
/// ChatCompletion Response Message
/// </summary>
public class Response
{
    [JsonProperty("id")]
    public string Id { get; set; } = string.Empty;

    [JsonProperty("object")]
    public string Object { get; set; } = string.Empty;

    [JsonProperty("created")]
    public double Created { get; set; }

    [JsonProperty("model")]
    public string Model { get; set; } = string.Empty;

    [JsonProperty("usage")]
    public Usage Usage { get; set; } = new();

    [JsonProperty("error")]
    public dynamic? Error { get; set; }
}
