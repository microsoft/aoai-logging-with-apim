// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion;

/// <summary>
/// Function
/// </summary>
public class Function
{
    [JsonProperty("name")]
    public string Name { get; set; } = string.Empty;

    [JsonProperty("description")]
    public string Description { get; set; } = string.Empty;

    [JsonProperty("parameters")]
    public dynamic? Parameters { get; set; }

    [JsonProperty("required")]
    public List<string> Required { get; set; } = new();
}