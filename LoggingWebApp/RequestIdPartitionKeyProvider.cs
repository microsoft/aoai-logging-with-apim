// Copyright (c) Microsoft. All rights reserved.

namespace LoggingWebApp;

/// <summary>
/// Custom Partition Key Provider for Cosmos DB Partition Key.
/// </summary>
public class RequestIdPartitionKeyProvider : IPartitionKeyProvider
{
    /// <summary>
    /// Returns request id as partition key.
    /// </summary>
    /// <param name="logEvent">LogEvent</param>
    /// <returns>Partition Key</returns>
    public string GeneratePartitionKey(LogEvent logEvent)
    {
        return ((ScalarValue)logEvent.Properties[nameof(TempRequestLog.RequestId)]).Value!.ToString()!;
    }
}
