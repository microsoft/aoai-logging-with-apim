// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.ChatCompletion.Stream;

/// <summary>
/// Chat Completion Streaming Response Message
/// </summary>
public class ChatCompletionStreamResponse : Response
{
    [JsonProperty("choices")]
    public List<Choice> Choices { get; set; } = new();

    [JsonProperty("prompt_filter_results")]
    public List<PromptFilterResult> PromptFilterResults { get; set; } = new();
}
