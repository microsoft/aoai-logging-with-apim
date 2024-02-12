// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

public class TempResponseLog
{
    [JsonProperty("type")]
    public string Type { get; } = "Response";

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }
    
    [JsonProperty("response")]
    public JObject Response { get; set; } = new();
}
