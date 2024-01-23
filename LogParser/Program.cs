// Copyright (c) Microsoft. All rights reserved.

IConfiguration configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false)
                .Build();

CosmosClient client = new CosmosClientBuilder(
        configuration["CosmosDbUrl"], 
        configuration["CosmosDbKey"])
        .WithConnectionModeGateway()
        .Build();

ContentSafetyClient contentSafetyClient = new(
       new Uri(configuration["ContentSafetyUrl"]!),
       new Azure.AzureKeyCredential(configuration["ContentSafetyKey"]!));

TelemetryConfiguration telemetryConfiguration = new()
{
    ConnectionString = configuration["ApplicationInsightsConnectionString"]
};

// Setup Serilog. Add or remove sink as needed.
Log.Logger = new LoggerConfiguration()
    // Use Log.Debug to log the AOAI log for now.
    .MinimumLevel.Debug()
    .WriteTo.Console(new JsonFormatter())
    .WriteTo.ApplicationInsights(
      telemetryConfiguration,
      TelemetryConverter.Traces)
    .WriteTo.AzCosmosDB(client, new AzCosmosDbSinkOptions()
    {
        DatabaseName = configuration["CosmosDbDatabaseName"]
    })
    .CreateLogger();

TikTokenService tikTokenService = new();
ResultCacheService resultCacheService = new();
ContentSafetyService contentSafetyService = new(contentSafetyClient);
DataProcessService eventHubDataProcessService = new(
    tikTokenService, 
    resultCacheService,
    contentSafetyService);

BlobContainerClient storageClient = new BlobContainerClient(
    configuration["BlobStorageConnectionStorage"],
    configuration["BlobContainerName"]);

EventProcessorClient processor = new (
    storageClient,
    EventHubConsumerClient.DefaultConsumerGroupName,
    configuration["EventHubConnectionString"]);

processor.ProcessEventAsync += eventHubDataProcessService.ProcessEventAsync;
processor.ProcessErrorAsync += eventHubDataProcessService.ProcessErrorAsync;

await processor.StartProcessingAsync();

while (true)
{
    await Task.Delay(TimeSpan.FromSeconds(1));
}
