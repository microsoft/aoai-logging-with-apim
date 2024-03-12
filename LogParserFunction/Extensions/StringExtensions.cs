// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Extensions;

/// <summary>
/// String Extensions
/// </summary>
public static class StringExtensions
{
    /// <summary>
    /// 
    /// </summary>
    /// <param name="body"></param>
    /// <returns></returns>
    public static Request? GetRequest(this string body)
    {
        dynamic requestBodyNode = JsonConvert.DeserializeObject(body);
        
        if (requestBodyNode is null || 
            requestBodyNode["request"] is null ||
            string.IsNullOrEmpty(requestBodyNode["request"]!.ToString()))
        {
            return default;
        }

        if (body.Contains("/chat/completions?api-version"))
        {
            return JsonConvert.DeserializeObject<ChatCompletionRequest>(
                   requestBodyNode!["request"].ToString());
        }
        else if (body.Contains("/completions?api-version"))
        {
            return JsonConvert.DeserializeObject<CompletionRequest>(
                requestBodyNode!["request"].ToString());
        }
        else if (body.Contains("embeddings?api-version"))
        {
            return JsonConvert.DeserializeObject<EmbeddingRequest>(
                requestBodyNode!["request"].ToString());
        }

        return default;
    }

    public static async Task<Response?> GetResponse(
        this string body, 
        Request request,
        TikTokenService tikTokenService,
        ContentSafetyService contentSafetyService)
    {
        dynamic? responseBodyNode = JsonConvert.DeserializeObject(body);

        if (responseBodyNode is null ||
            responseBodyNode["response"] is null ||
            string.IsNullOrEmpty(responseBodyNode["response"]!.ToString()))
        {
            return default;
        }

        string responseBody = responseBodyNode["response"]!.ToString();
        // Sream response consists of data list.
        if (request is ChatCompletionRequest)
        {
            if (responseBody.StartsWith("data"))
            {
                string responseBodyJson = responseBody
                    .Replace("[DONE]\n\n", "]")
                    .Replace("\n\ndata: ", ",")
                    .Replace("data: ", "[")
                    .Replace("},]", "}]");

                ChatCompletionStreamResponse[]? streamResponses = 
                    JsonConvert.DeserializeObject<ChatCompletionStreamResponse[]>(responseBodyJson);
                if (streamResponses is null || !streamResponses.Any())
                {
                    return default;
                }

                // Recreate the assistant response by combining all the stream delta contents.
                string concatenatedContent = string.Join("",
                    streamResponses.Select(x => x.Choices.FirstOrDefault()?.Delta.Content).ToList());
                string requestContent = string.Join(Environment.NewLine,
                             ((ChatCompletionRequest)request)!.Messages.Select(x => x.Content));
                // Check the content safety
                ContentFilterResults responseContentFilterResults = string.IsNullOrEmpty(concatenatedContent) ?
                    new() :
                    await contentSafetyService.GetContentFilterResultsAsync(concatenatedContent);
                ContentFilterResults requestContentFilterResults =
                    await contentSafetyService.GetContentFilterResultsAsync(requestContent);
                await contentSafetyService.GetContentFilterResultsAsync(requestContent);
                // Count the tokens for request
                //TODO: Need additional calculation for vision https://platform.openai.com/docs/guides/vision
                // promtTokens adjusted by adding 11 tokens to match the token count of the non stream mode. 
                int promptTokens = await tikTokenService.CountToken(((ChatCompletionRequest)request).Messages) + 11;
                // comletionTokens uses the token count of the concatenated content to match the token count of the non stream mode. 
                int comletionTokens = tikTokenService.CountToken(concatenatedContent);
                ChatCompletionStreamResponse streamResponse = streamResponses.Where(x => !string.IsNullOrEmpty(x.Id)).First();

                // Create idential response format with non-stream response.
                return new ChatCompletionResponse()
                {
                    Id = streamResponse.Id,
                    Object = streamResponse.Object,
                    Model = streamResponse.Model,
                    Created = streamResponse.Created,
                    Choices = new()
                {
                    new()
                    {
                        FinishReason = streamResponses.Last().Choices.First().FinishReason,
                        Index = 0,
                        Message = new()
                        {
                            Role = "assistant",
                            Content = concatenatedContent
                        },
                        ContentFilterResults = responseContentFilterResults
                    }
                },
                    Usage = new()
                    {
                        PromptTokens = promptTokens,
                        CompletionTokens = comletionTokens,
                        TotalTokens = promptTokens + comletionTokens,
                    },
                    PromptFilterResults = new()
                {
                    new()
                    {
                         PromptIndex = 0,
                         ContentFilterResults = requestContentFilterResults
                    }
                }
                };
            }
            else
            {
                return JsonConvert.DeserializeObject<ChatCompletionResponse>(responseBody)!;
            }
        }
        else if (request is CompletionRequest)
        {
            if (responseBody.StartsWith("data"))
            {
                string responseBodyJson = responseBody
                    .Replace("[DONE]\n\n", "]")
                    .Replace("\n\ndata: ", ",")
                    .Replace("data: ", "[")
                    .Replace("},]", "}]");

                CompletionResponse[]? streamResponses = JsonConvert.DeserializeObject<CompletionResponse[]>(responseBodyJson);
                if (streamResponses is null || !streamResponses.Any())
                {
                    return default;
                }

                // Recreate the assistant response by combining all the stream delta contents.
                string concatenatedContent = string.Join("",
                    streamResponses.Select(x => x.Choices.FirstOrDefault()?.Text).ToList());
                string requestContent = string.Join(Environment.NewLine, ((CompletionRequest)request).Prompt);
                // Check the content safety
                ContentFilterResults responseContentFilterResults = string.IsNullOrEmpty(concatenatedContent) ? 
                    new():
                    await contentSafetyService.GetContentFilterResultsAsync(concatenatedContent);
                ContentFilterResults requestContentFilterResults = 
                    await contentSafetyService.GetContentFilterResultsAsync(requestContent);
                 // Count the tokens for request
                int promptTokens = tikTokenService.CountToken(requestContent) + 11;
                int comletionTokens = tikTokenService.CountToken(concatenatedContent);
                CompletionResponse streamResponse = streamResponses.Where(x => !string.IsNullOrEmpty(x.Id)).First();

                // Create idential response format with non-stream response.
                return new CompletionResponse()
                {
                    Id = streamResponse.Id,
                    Object = streamResponse.Object,
                    Model = streamResponse.Model,
                    Created = streamResponse.Created,
                    Choices = new()
                    {
                        new()
                        {
                            FinishReason = streamResponses.Last().Choices.First().FinishReason,
                            Index = 0,
                            Text = concatenatedContent,
                            ContentFilterResults = responseContentFilterResults
                        }
                    },
                    Usage = new()
                    {
                        PromptTokens = promptTokens,
                        CompletionTokens = comletionTokens,
                        TotalTokens = promptTokens + comletionTokens,
                    },
                    PromptFilterResults = new()
                    {
                        new()
                        {
                             PromptIndex = 0,
                             ContentFilterResults = requestContentFilterResults
                        }
                    }
                };
            }
            else
            {
                return JsonConvert.DeserializeObject<CompletionResponse>(responseBody)!;
            }
        }
        else if (request is EmbeddingRequest)
        {
            return JsonConvert.DeserializeObject<EmbeddingResponse>(responseBody)!;
        }

        return default;
    }
}
