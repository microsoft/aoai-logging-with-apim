// Copyright (c) Microsoft. All rights reserved.

using Azure.Messaging.EventHubs.Producer;

namespace LoggingWebApp.Controllers;

/// <summary>
/// OpenAI controller that accepts any request and forwards it to the AOAI backend endpoint.
/// It logs both request and response as temporary logs to Cosmos DB for monitoring.
/// </summary>
/// <param name="factory">IHttpClientFactory</param>
/// <param name="accessor">IHttpContextAccessor</param>
/// <param name="container">Cosmos DB Container</param>
/// <param name="eventHubProducerClient">EventHubProducerClient</param>
[ApiController]
[Route("[controller]")]
public class OpenAI(IHttpClientFactory factory, IHttpContextAccessor accessor, Container container, EventHubProducerClient eventHubProducerClient) : ControllerBase
{
    private readonly IHttpContextAccessor accessor = accessor;
    private readonly Container container = container;
    private readonly EventHubProducerClient eventHubProducerClient = eventHubProducerClient;
    private readonly HttpClient httpClient = factory.CreateClient();
    private readonly string LINE_END = $"{Environment.NewLine}{Environment.NewLine}";

    /// <summary>
    /// Accept Post method for any path and query parameters, then forward the request to AOAI endpoint.
    /// Log both request and response as temporary logs to Cosmos DB for monitoring.
    /// </summary>
    /// <param name="path">URL Path</param>
    /// <param name="body">Request Body</param>
    /// <returns></returns>
    [HttpPost]
    [Route("{*path}")]
    public async Task<IActionResult> Post(string path, [FromBody] JObject body)
    {
        Stopwatch sw = Stopwatch.StartNew();
        sw.Start();
        HttpResponse response = accessor.HttpContext!.Response;
        HttpRequest request = accessor.HttpContext!.Request;
        string requestId = request.Headers["Request-Id"].ToString();
        
        // Default action result is Empty for SSE.
        IActionResult actionResult = new EmptyResult();
        List<TempLog> tempLogs = new List<TempLog>();

        // Log the request
        JObject headers = new();
        foreach (KeyValuePair<string, StringValues> header in request.Headers)
        {
            if (header.Key is "AOAI-Api-Key")
            {
                httpClient.DefaultRequestHeaders.Add("api-key", header.Value.ToString());
                continue; // Do not log key
            }
            else if (header.Key is "Backend-Url")
            {
                httpClient.BaseAddress = new Uri(header.Value.ToString());
            }
            else if (header.Key is "api-key")
            {
                continue;  // Do not log key
            }
            headers[header.Key] = string.Join(",", header.Value!);
        }
        headers["Request-Url"] = $"{request.Path}{request.QueryString}";
        TempRequestLog tempRequestLog = new()
        {
            RequestId = requestId,
            Headers = headers,
            Request = body,
            RequestUrl = $"{request.Path}{request.QueryString}",
        };

        tempLogs.Add(tempRequestLog);

        // Foward the request to AOAI endpoint
        HttpRequestMessage requestMessage = new(HttpMethod.Post, path + Request.QueryString);
        requestMessage.Content = new StringContent(body.ToString(), Encoding.UTF8, "application/json");
        HttpResponseMessage res = await httpClient.SendAsync(requestMessage, HttpCompletionOption.ResponseHeadersRead);

        // Log the response
        headers = new();
        headers["Status-Code"] = (int)res.StatusCode;
        headers["Status-Reason"] = res.ReasonPhrase;

        // Reply SSE as stream results.
        if (body["stream"] is not null && body["stream"]!.Value<bool>())
        {
            response.Headers.TryAdd(HeaderNames.ContentType, "text/event-stream");
            response.Headers.TryAdd(HeaderNames.CacheControl, "no-cache");
            response.Headers.TryAdd(HeaderNames.Connection, "keep-alive");

            using (StreamReader streamReader = new(await res.Content.ReadAsStreamAsync()))
            {
                while (!streamReader.EndOfStream)
                {
                    string? message = await streamReader.ReadLineAsync();
                    if (string.IsNullOrEmpty(message))
                    {
                        continue;
                    }

                    headers["Elasped"] = sw.ElapsedMilliseconds;

                    TempStreamResponseLog tempStreamResponseLog = new()
                    {
                        Headers = headers,
                        RequestId = requestId,
                        Response = message,
                    };

                    // Send SSE with LINE_END
                    await response.WriteAsync($"{message}{LINE_END}");
                    await response.Body.FlushAsync();
                    tempLogs.Add(tempStreamResponseLog);
                }
            }
        }
        // Handle non-streaming response
        else
        {
            JObject responseContent = JObject.Parse(await res.Content.ReadAsStringAsync());
            headers["Elasped"] = sw.ElapsedMilliseconds;
            TempResponseLog tempResponseLog = new()
            {
                Headers = headers,
                RequestId = requestId,
                Response = responseContent,
            };
            tempLogs.Add(tempResponseLog);

            actionResult = Ok(responseContent);
        }
                
        foreach(TempLog tempLog in tempLogs)
        {
            await container.CreateItemAsync(tempLog,
                new PartitionKey(requestId));
        }
        
        // Once all logging complete for the request, notifiy to EventHub.
        EventDataBatch eventBatch = await eventHubProducerClient.CreateBatchAsync();
        eventBatch.TryAdd(new Azure.Messaging.EventHubs.EventData(requestId));
        await eventHubProducerClient.SendAsync(eventBatch);
        
        return actionResult;
    }
}
