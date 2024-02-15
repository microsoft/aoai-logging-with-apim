// Copyright (c) Microsoft. All rights reserved.

namespace LogParserFunction;

public class LogParser(
    DataProcessService dataProcessService, 
    TelemetryClient telemetryClient, 
    EventHubProducerClient eventHubProducerClient, 
    ILogger<LogParser> logger)
{
    private readonly DataProcessService dataProcessService = dataProcessService;
    private readonly TelemetryClient telemetryClient = telemetryClient;
    private readonly EventHubProducerClient eventHubProducerClient = eventHubProducerClient;
    private readonly ILogger<LogParser> logger = logger;

    /// <summary>
    /// Main function to parse the log.
    /// </summary>
    /// <param name="input"></param>
    /// <returns></returns>
    [Function("LogParser")]
    public async Task Run([EventHubTrigger("%EventHubName%", Connection = "EventHubConnectionString", IsBatched = false)] string input)
    {
        try
        {
            logger.LogInformation($"Parse {input}");
            AOAILog? aoaiLog = await dataProcessService.ProcessEventAsync(input);
            if (aoaiLog is not null)
            {
                telemetryClient.TrackTrace(
                    JsonConvert.SerializeObject(
                        aoaiLog,
                        new JsonSerializerSettings() { NullValueHandling = NullValueHandling.Ignore }));
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning($"Failed with error: {ex.Message}. The {input} is push back to the event hub again.");
            EventDataBatch eventBatch = await eventHubProducerClient.CreateBatchAsync();
            eventBatch.TryAdd(new Azure.Messaging.EventHubs.EventData(input));
            await eventHubProducerClient.SendAsync(eventBatch);
        }

        return;
    }
}
