# Logging Web API

C# sample Web API that works as a proxy.

![Architecture](/assets/aoai_apim.svg)

1. The Web API receive the request from AOAI.
1. Forward the request to AOAI specified in headers.
1. Create request log by setting ``request id`` and store in a cache.
1. Once AOAI respond, it returns the results back to APIM.
    - If it's streaming mode, then return SSE.
    - If it's non-streaming mode, then return HttpResponseMessage
    - If it's not succeeded, return the error as it is.
1. While replying the response, it also stores the response log by settings ``request id`` into the cache.
1. After it returns the response back to APIM, then send the logs to Cosmos DB.
1. Then send the ``request id`` to the Cosmos DB Container for trigger.

## How to run in local environment

If you want to run and debug the application, follow the steps below.

1. Rename ``__appsettings.json`` into ``appsettings,json``
1. Fill all the variables.
1. Run by using any IDE or ``dotnet run``

Please note that when you provision the solution by using [bicep files](/infra), Azure resources blocks external access. If the [Log Parser Function](/LogParserFunction/) is up and running in the cloud, it's triggered by the Cosmos DB change feed, so that you may end up have duplicate logs in the Application Insights when you run the function locally at the same time.

If you want to test from APIM, then you can change the backend address to any proxy address that routes the request to your local server.