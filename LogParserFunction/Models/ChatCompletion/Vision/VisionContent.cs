// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion.Vision;

/// <summary>
/// Vision Content
/// </summary>
public class VisionContent
{
    [JsonProperty("type")]
    public string Type { get; set; } = string.Empty;

    [JsonProperty("text")]
    public string? Text { get; set; }

    [JsonProperty("image_url")]
    public ImageUrl? ImageUrl { get; set; }
}