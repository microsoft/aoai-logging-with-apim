// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion;

/// <summary>
/// ChatCompletion Response Message
/// </summary>
public class ChatCompletionResponse : Response
{
    [JsonProperty("choices")]
    public List<Choice> Choices { get; set; } = new();

    [JsonProperty("prompt_filter_results")]
    public List<PromptFilterResult> PromptFilterResults { get; set; } = new();

}
