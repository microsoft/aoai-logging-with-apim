// Copyright (c) Microsoft. All rights reserved.

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

CosmosClient cosmosClient = new CosmosClientBuilder(
        builder.Configuration["CosmosDbConnectionString"])
        .WithConnectionModeGateway()
        .Build();

Container logContainer = cosmosClient.GetContainer(
    builder.Configuration["CosmosDbDatabaseName"],
    builder.Configuration["CosmosDbLogContainerName"]);

Container triggerContainer = cosmosClient.GetContainer(
    builder.Configuration["CosmosDbDatabaseName"],
    builder.Configuration["CosmosDbTriggerContainerName"]);

Containers containers = new()
{
    { "logContainer", logContainer },
    { "triggerContainer", triggerContainer },
};

// Add services to the container.

builder.Services.AddControllers().AddNewtonsoftJson();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton(containers);
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
