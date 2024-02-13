// Copyright (c) Microsoft. All rights reserved.

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

CosmosClient client = new CosmosClientBuilder(
        builder.Configuration["CosmosDbUrl"],
        builder.Configuration["CosmosDbKey"])
        .WithConnectionModeGateway()
        .Build();

EventHubProducerClient eventHubProducerClient = new(builder.Configuration["EventHubConnectionString"]);

Loggers loggers = new()
{
    {
        "AzCosmosDB",
        new LoggerConfiguration()
        .MinimumLevel.Information()
        .WriteTo.Console(new JsonFormatter())
        .WriteTo.AzCosmosDB(
            client,
            databaseName: builder.Configuration["CosmosDbDatabaseName"],
            collectionName: builder.Configuration["CosmosDbContainerName"],
            partitionKeyProvider: new RequestIdPartitionKeyProvider(),
            partitionKey:"requestId")
        .CreateLogger()
    },
    {
        "EventHub",
        new LoggerConfiguration()
        .MinimumLevel.Information()
        .WriteTo.Console(new JsonFormatter())
        .WriteTo.AzureEventHub(eventHubProducerClient, outputTemplate: "{Message}")
        .CreateLogger()
    }
};

// Add services to the container.

builder.Services.AddControllers().AddNewtonsoftJson();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<Loggers>(sp => loggers);

WebApplication app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
