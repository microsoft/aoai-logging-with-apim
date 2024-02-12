// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Services;

/// <summary>
/// ResultCacheService
/// TODO: Use cosmos db to store the result
/// </summary>
public class ResultCacheService
{
    private readonly Dictionary<string, EventHubRequestLog> cache = new();

    /// <summary>
    /// Get the Request log by request id
    /// </summary>
    /// <param name="requestId">RequsetId</param>
    /// <returns>EventHubRequestLog</returns>
    public EventHubRequestLog? GetRequestLog(string requestId)
    {
        return cache.ContainsKey(requestId) ? cache[requestId] : default;
    }

    /// <summary>
    /// Store the request log.
    /// </summary>
    /// <param name="requestLog">EventHubRequestLog</param>
    public void StoreRequestLog(EventHubRequestLog requestLog)
    {
        cache[requestLog.RequestId] = requestLog;
    }

    /// <summary>
    /// Remove the request log from cache.
    /// </summary>
    /// <param name="requestId">RequsetId</param>
    public void RemoveRequestLog(string requestId)
    {
        cache.Remove(requestId);
    }
}
