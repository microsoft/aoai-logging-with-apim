// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Services;

/// <summary>
/// Content Safety Service
/// </summary>
/// <param name="contentSafetyClient">ContentSafetyClient</param>
public class ContentSafetyService(ContentSafetyClient contentSafetyClient)
{
    private readonly ContentSafetyClient contentSafetyClient = contentSafetyClient;

    public async Task<ContentFilterResults> GetContentFilterResultsAsync(string text)
    {
        Azure.Response<AnalyzeTextResult> response = 
            await contentSafetyClient.AnalyzeTextAsync(new AnalyzeTextOptions(text));
        
        if (response is null)
        {
            return new();
        }

        return new()
        {
            Hate = new()
            {
                Severity = GetSeverity(response.Value.CategoriesAnalysis.First(x => x.Category == TextCategory.Hate).Severity),
                Filtered = false
            },
            SelfHarm = new()
            {
                Severity = GetSeverity(response.Value.CategoriesAnalysis.First(x => x.Category == TextCategory.SelfHarm).Severity),
                Filtered = false
            },
            Sexual = new()
            {
                Severity = GetSeverity(response.Value.CategoriesAnalysis.First(x => x.Category == TextCategory.Sexual).Severity),
                Filtered = false
            },
            Violence = new()
            {
                Severity = GetSeverity(response.Value.CategoriesAnalysis.First(x => x.Category == TextCategory.Violence).Severity),
                Filtered = false
            },
        };
    }

    private string GetSeverity(int? severityLevel)
    {
        switch (severityLevel)
        {
            case 0:
            case 1:
                return "safe";
            case 2:
            case 3:
                return "low";
            case 4:
            case 5:
                return "medium";
            default:
                return "high";
        }
    }
}
