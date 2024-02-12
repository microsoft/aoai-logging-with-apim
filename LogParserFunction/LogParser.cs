
namespace LogParserFunction;

public class LogParser(DataProcessService dataProcessService)
{
    private readonly DataProcessService dataProcessService = dataProcessService;

    [Function("LogParser")]
    public async Task Run([EventHubTrigger("%EventHubName%", Connection = "EventHubConnectionString")] string[] inputs)
    {
        foreach (string input in inputs)
        {
            await dataProcessService.ProcessEventAsync(input);
        }
    }
}
