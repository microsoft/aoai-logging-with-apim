// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion.Vision;

/// <summary>
/// Image Url
/// </summary>
public class ImageUrl
{
    [JsonProperty("url")]
    public string Url { get; set; } = string.Empty;

    [JsonProperty("detail")]
    public string? Details { get; set; }
}