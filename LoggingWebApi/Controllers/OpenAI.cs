// Copyright (c) Microsoft. All rights reserved.

namespace LoggingWebApi.Controllers;

/// <summary>
/// OpenAI controller that accepts any request and forwards it to the AOAI backend endpoint.
/// It logs both request and response as temporary logs to Cosmos DB for monitoring.
/// </summary>
/// <param name="factory">IHttpClientFactory</param>
/// <param name="accessor">IHttpContextAccessor</param>
/// <param name="container">Cosmos DB Container</param>
[ApiController]
[Route("[controller]")]
public class OpenAI(
    IHttpClientFactory factory,
    IHttpContextAccessor accessor, 
    Containers containers) : ControllerBase
{
    private readonly IHttpContextAccessor accessor = accessor;
    private readonly Containers containers = containers;
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
        string requestId = request.Headers["RequestId"].ToString();
        
        // Default action result is Empty for SSE.
        IActionResult actionResult = new EmptyResult();
        List<TempLog> tempLogs = new();

        // Log the request
        JObject headers = new();
        foreach (KeyValuePair<string, StringValues> header in request.Headers)
        {
            if (header.Key is "BackendUrl")
            {
                httpClient.BaseAddress = new Uri(header.Value.ToString());
            }
            else if (header.Key is "api-key")
            {
                continue;  // Do not log key
            }
            headers[header.Key] = string.Join(",", header.Value!);
        }
        headers["RequestUrl"] = $"{request.Path}{request.QueryString}";
        TempRequestLog tempRequestLog = new()
        {
            RequestId = requestId,
            Headers = headers,
            Request = body,
            RequestUrl = $"{request.Path}{request.QueryString}",
        };

        tempLogs.Add(tempRequestLog);

        // Foward the request to AOAI endpoint
        ManagedIdentityCredential managedIdentityCredential = new();
        AccessToken accessToken = await managedIdentityCredential.GetTokenAsync(new TokenRequestContext(new[] { "https://cognitiveservices.azure.com/" })).ConfigureAwait(false);
        httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken.Token);
        HttpRequestMessage requestMessage = new(HttpMethod.Post, path + Request.QueryString);
        requestMessage.Content = new StringContent(body.ToString(), Encoding.UTF8, "application/json");
        HttpResponseMessage res = await httpClient.SendAsync(requestMessage, HttpCompletionOption.ResponseHeadersRead);

        // Log the response
        headers = new();
        headers["StatusCode"] = (int)res.StatusCode;
        headers["StatusReason"] = res.ReasonPhrase;

        if (!res.IsSuccessStatusCode)
        {
            JObject responseContent = JObject.Parse(await res.Content.ReadAsStringAsync());
            // Return the response as we don't need to log the AOAI level error.
            return StatusCode((int)res.StatusCode, responseContent);
        }
        // Reply SSE as stream results.
        else if (body["stream"] is not null && body["stream"]!.Value<bool>())
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

                    headers["Elapsed"] = sw.ElapsedMilliseconds;

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
            headers["Elapsed"] = sw.ElapsedMilliseconds;
            TempResponseLog tempResponseLog = new()
            {
                Headers = headers,
                RequestId = requestId,
                Response = responseContent,
            };
            tempLogs.Add(tempResponseLog);

            actionResult = this.Ok(responseContent);
        }

        // Return the response first, then do logging.
        try
        {
            return actionResult;
        }
        finally
        {
            Container logContainer = containers["logContainer"];
            Container triggerContainer = containers["triggerContainer"];
            Response.OnCompleted(async () =>
            {
                foreach (TempLog tempLog in tempLogs)
                {
                    await logContainer.CreateItemAsync(tempLog,
                        new PartitionKey(requestId));
                }

                // Once all logging complete for the request, create trigger item.
                await triggerContainer.CreateItemAsync(new TempLog() { RequestId = requestId });
            });
        } 
    }
}
