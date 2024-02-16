// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Models.Completion;

/// <summary>
/// Completion Response 
/// </summary>
public class CompletionResponse : Response
{
    [JsonProperty("choices")]
    public List<Choice> Choices { get; set; } = new();

    [JsonProperty("prompt_filter_results")]
    public List<PromptFilterResult> PromptFilterResults { get; set; } = new();
}
