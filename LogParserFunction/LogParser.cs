// Copyright (c) Microsoft. All rights reserved.

using Azure.Messaging.EventHubs.Producer;

namespace LogParserFunction;

public class LogParser(
    DataProcessService dataProcessService, 
    TelemetryClient telemetryClient, 
    EventHubProducerClient eventHubProducerClient, 
    ILogger<LogParser> logger)
{
    private readonly DataProcessService _dataProcessService = dataProcessService;
    private readonly TelemetryClient _telemetryClient = telemetryClient;
    private readonly EventHubProducerClient _eventHubProducerClient = eventHubProducerClient;
    private readonly ILogger<LogParser> _logger = logger;

    [Function("LogParser")]
    public async Task Run([EventHubTrigger("%EventHubName%", Connection = "EventHubConnectionString", IsBatched = false)] string input)
    {
        try
        {
            _logger.LogInformation($"Parse {input}");
            AOAILog? aoaiLog = await _dataProcessService.ProcessEventAsync(input);
            if (aoaiLog is not null)
            {
                _telemetryClient.TrackTrace(
                    JsonConvert.SerializeObject(
                        aoaiLog,
                        new JsonSerializerSettings() { NullValueHandling = NullValueHandling.Ignore }));
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning($"Failed with error: {ex.Message}. The {input} is push back to the event hub again.");
            EventDataBatch eventBatch = await _eventHubProducerClient.CreateBatchAsync();
            eventBatch.TryAdd(new Azure.Messaging.EventHubs.EventData(input));
            await _eventHubProducerClient.SendAsync(eventBatch);
        }

        return;
    }
}
