// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.Completion;

/// <summary>
/// ChatCompletion Request Message
/// </summary>
public class CompletionRequest : Request
{
    [JsonProperty("prompt")]
    public string? Prompt { get; set; } = "<\\|endoftext\\|>";

    [JsonProperty("logprobs")]
    public int? LogProbs { get; set; }

    [JsonProperty("best_of")]
    public int BestOf { get; set; } = 1;

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
}