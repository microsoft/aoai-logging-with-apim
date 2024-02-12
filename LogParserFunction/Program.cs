

using Microsoft.Extensions.DependencyInjection;

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

TelemetryConfiguration telemetryConfiguration = new()
{
    ConnectionString = Environment.GetEnvironmentVariable("ApplicationInsightsConnectionString")
};

// Setup Serilog. Add or remove sink as needed.
Log.Logger = new LoggerConfiguration()
    // Use Log.Debug to log the AOAI log for now.
    .MinimumLevel.Debug()
    .WriteTo.Console(new JsonFormatter())
    .WriteTo.ApplicationInsights(
      telemetryConfiguration,
      TelemetryConverter.Traces)
    .CreateLogger();

TikTokenService tikTokenService = new();
ResultCacheService resultCacheService = new();
ContentSafetyService contentSafetyService = new(contentSafetyClient);
DataProcessService eventHubDataProcessService = new(
    tikTokenService,
    resultCacheService,
    contentSafetyService,
    container);

IHost host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((hostContext, services) =>
    {
        services.AddTransient<DataProcessService>(sp => eventHubDataProcessService);
    })
    .Build();

host.Run();
