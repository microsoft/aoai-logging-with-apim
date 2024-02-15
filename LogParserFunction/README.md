# Azure API Management(APIM) Log parser for Azure Open AI(AOAI)

As described in [the challenges](../README.md#challenges-of-azure-open-ai-in-production), one of the issue when monitoring the AOAI accounts is the inconsistency of response format depending on the models, features to use, and ``stream`` or ``non-stream`` mode for Completion endpoints.

For example, the stream mode responses do not contain, not only token usage information, but also it's difficult to read the result as each response contains just a snippet of the generated answer.

This C# sample application demonstrate how to parse these logs to make them identical so that it is easier to create reports and dashboards.

# Architecture

![Architecture](../assets/aoai_apim.svg)

1. The log parser is triggered from the Azure Event Hub that has ``request id``.
1. It retrieves all the logs for the ``request id`` from Cosmos DB.
1. Depending on the response type, it converts the logs into uniform format.
1. Then it sends the converted logs to Application Insights.

## Features

The log parser does:

- Combine a request and the corresponding response into single log.
- Combine multiple stream responses into a single response by joining the content, then calculate token usage and content safeness.

### Limitation

We are not creating the function calling response when using streaming mode at the moment.

# How to run the log parser

The log parser is a C# Azure Functions application. We can run it locally by using any IDE that supports Azure Functions, such as Visual Studio and Visual Studio Code.

## local.settings.json

Rename the ``__local.settings.json`` into ``local.settings.json`` and fill the necessary information. 

- __EventHubConnectionString__: We need ``Listen`` and ``Send`` policy.
- __CosmosDbUrl__ and __CosmosDbKey__: The CosmosDB access information to store the log documents.
- __CosmosDbDatabaseName__ and __CosmosDbContainerName__: The database and container names to store the log documents.
- __ContentSafetyUrl__ and __ContentSafetyKey__: The content safety service endpoint and key.
- __ApplicationInsightsConnectionString__: The application insights connection string to store the log trace.

## Run locally

You can run by dotnet runtime or use any IDE to run the program.

# Stream Log Parser

GPT models returns responses token by token when we use stream mode, so that we can return the results little by little to consumer. See [How to stream completion](https://cookbook.openai.com/examples/how_to_stream_completions) for more detail.

As described in the article, one of [the downsides](https://cookbook.openai.com/examples/how_to_stream_completions#downsides) is that it doesn't contain ``usage`` field that tells us how many tokens were consumed.

To solve this challenge, the log parser accumulates all the responses and concatenates the content, then calculates the token usage by using [TiktokenSharp](https://github.com/aiqinxuancai/TiktokenSharp).

Another challenge is that the response content safety check may not be accurate as it returns token by token. The log parser sends the concatenated result to [Azure Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/overview) service to analyze it.