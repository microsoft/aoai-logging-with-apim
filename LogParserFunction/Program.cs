// Copyright (c) Microsoft. All rights reserved.

CosmosClient cosmosClient = new CosmosClientBuilder(
        Environment.GetEnvironmentVariable("CosmosDbConnectionString"))
        .WithConnectionModeGateway()
        .Build();

Container container = cosmosClient.GetContainer(
    Environment.GetEnvironmentVariable("CosmosDbDatabaseName"),
    Environment.GetEnvironmentVariable("CosmosDbLogContainerName"));

ContentSafetyClient contentSafetyClient = new(
       new Uri(Environment.GetEnvironmentVariable("ContentSafetyUrl")!),
       new Azure.AzureKeyCredential(Environment.GetEnvironmentVariable("ContentSafetyKey")!));

TikTokenService tikTokenService = new();
ContentSafetyService contentSafetyService = new(contentSafetyClient);
DataProcessService dataProcessService = new(
    tikTokenService,
    contentSafetyService,
    container);

IHost host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();
        services.AddTransient(sp => dataProcessService);
    })
    .Build();

host.Run();
