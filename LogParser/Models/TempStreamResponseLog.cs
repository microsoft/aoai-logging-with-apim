// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models;

public class TempStreamResponseLog
{
    [JsonProperty("type")]
    public string Type { get; } = "StreamResponse";

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }

    [JsonProperty("response")]
    public string Response { get; set; } = string.Empty;
}
