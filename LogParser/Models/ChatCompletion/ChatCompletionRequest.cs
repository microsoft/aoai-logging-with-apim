// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion;

/// <summary>
/// ChatCompletion Request Message
/// </summary>
public class ChatCompletionRequest : Request
{
    [JsonProperty("messages")]
    public List<Message> Messages { get; set; } = new();

    [JsonProperty("max_tokens")]
    public int? MaxTokens { get; set; }

    [JsonProperty("temperature")]
    public int? Temperature { get; set; }

    [JsonProperty("top_p")]
    public int? TopP { get; set; }

    [JsonProperty("logit_bias")]
    public string? LogitBias { get; set; }

    [JsonProperty("user")]
    public string? User { get; set; }

    [JsonProperty("n")]
    public int? N { get; set; }

    [JsonProperty("stream")]
    public bool? Stream { get; set; }

    [JsonProperty("suffix")]
    public string? Suffix { get; set; }

    [JsonProperty("echo")]
    public bool? Echo { get; set; }

    [JsonProperty("stop")]
    public string? Stop { get; set; }

    [JsonProperty("presence_penalty")]
    public int? PresencePenalty { get; set; }

    [JsonProperty("frequency_penalty")]
    public int? FrequencyPenalty { get; set; }

    [JsonProperty("function_call")]
    public dynamic? FunctionCall { get; set; }

    [JsonProperty("functions")]
    public dynamic? Functions { get; set; }

    [JsonProperty("tools")]
    public dynamic? Tools { get; set; }

    [JsonProperty("tool_choice")]
    public dynamic? ToolChoice { get; set; }

    [JsonProperty("enhancements")]
    public dynamic? Enhancements { get; set; }

    [JsonProperty("dataSources")]
    public dynamic? DataSources { get; set; }
}