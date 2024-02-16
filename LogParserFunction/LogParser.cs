// Copyright (c) Microsoft. All rights reserved.

namespace LogParserFunction;

public class LogParser(
    DataProcessService dataProcessService, 
    TelemetryClient telemetryClient, 
    ILogger<LogParser> logger)
{
    private readonly DataProcessService dataProcessService = dataProcessService;
    private readonly TelemetryClient telemetryClient = telemetryClient;
    private readonly ILogger<LogParser> logger = logger;

    /// <summary>
    /// Main function to parse the log.
    /// </summary>
    /// <param name="input"></param>
    /// <returns></returns>
    [Function("LogParser")]
    public async Task Run([CosmosDBTrigger(
        databaseName: "%CosmosDbDatabaseName%",
        containerName: "%CosmosDbTriggerContainerName%",
        Connection = "CosmosDbConnectionString",
        LeaseContainerName = "leases",
        CreateLeaseContainerIfNotExists = true)]IReadOnlyList<TempLog> logs)
    {
        List<Exception> exceptions = new();
        foreach (TempLog log in logs)
        {
            try
            {
                logger.LogInformation($"Parse {log.RequestId}");
                AOAILog? aoaiLog = await dataProcessService.ProcessLogsAsync(log.RequestId);
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
                exceptions.Add(ex);
            }
        }

        if (exceptions.Count is 1)
        {
            throw exceptions.First();
        }
        else if (exceptions.Count > 1)
        {
            throw new AggregateException(exceptions);
        }
        else
        {
            return;
        }
    }
}
