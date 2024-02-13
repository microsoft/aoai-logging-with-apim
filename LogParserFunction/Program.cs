// Copyright (c) Microsoft. All rights reserved.

CosmosClient cosmosClient = new CosmosClientBuilder(
        Environment.GetEnvironmentVariable("CosmosDbUrl"),
        Environment.GetEnvironmentVariable("CosmosDbKey"))
        .WithConnectionModeGateway()
        .Build();

Container container = cosmosClient.GetContainer(
    Environment.GetEnvironmentVariable("CosmosDbDatabaseName"),
    Environment.GetEnvironmentVariable("CosmosDbContainerName"));

ContentSafetyClient contentSafetyClient = new(
       new Uri(Environment.GetEnvironmentVariable("ContentSafetyUrl")!),
       new Azure.AzureKeyCredential(Environment.GetEnvironmentVariable("ContentSafetyKey")!));

TikTokenService tikTokenService = new();
ContentSafetyService contentSafetyService = new(contentSafetyClient);
DataProcessService eventHubDataProcessService = new(
    tikTokenService,
    contentSafetyService,
    container);

IHost host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();
        services.AddTransient(sp => eventHubDataProcessService);
        services.AddTransient(sp => new EventHubProducerClient(Environment.GetEnvironmentVariable("EventHubConnectionString")));
    })
    .Build();

host.Run();
