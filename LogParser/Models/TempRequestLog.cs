// Copyright (c) Microsoft. All rights reserved.

using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Primitives;

namespace LogParser.Models;

public class TempRequestLog
{
    [JsonProperty("type")]
    public string Type { get; } = "Request";

    [JsonProperty("requestId")]
    public string RequestId { get; set; } = string.Empty;

    [JsonProperty("headers")]
    public dynamic? Headers { get; set; }

    [JsonProperty("request")]
    public JObject Request { get; set; } = new();
}
