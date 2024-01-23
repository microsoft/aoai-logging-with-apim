# Azure Open AI Operation Management with Azure API Management

## Challenges of Azure Open AI in production

We often see common challenges when we use Azure Open AI(AOAI) in production environment.

- __Key Management__: AOAI only has primary and secondary key per account, therefore we need to share the same key with users, teams and organizations. However, in most scenario, we need to manage each user separately for performance and monitoring purposes. The risk of sharing the same key is quite severe, for example, if someone reveals or lost the key, all the other users and applications are affected by rotating the existing keys.
- __Different throttling settings__: Customers want to control how each audience consumes the service, but AOAI doesn't provide granular controls.
- __Monitor Token Usage__: When using streaming mode, AOAI doesn't return consumed token count information.
- __Monitor Request/Response body and headers__: Customers often needs actual request/response body and headers data to further analyze the usage, but AOAI doesn't provide it by default.
- __Different Formats__: Each endpoint has slightly different request/response formats. Streaming mode also has quite different and hard to read response format that makes harder to generate reports.
- __Content Safety for Stream Response__: As stream response returns the result token by token, the content safety results may not be accurate.
- __Create Usage Dashboard__: Though AOAI integrates with Application Insights, they cannot create granular dashboard by using Power BI.
- Not all models are available in a single AOAI account, so users have to manage endpoint and key combinations.

## How Azure API Management solves the challenges

[Azure API Management (APIM)](https://learn.microsoft.com/azure/api-management/api-management-key-concepts) is a hybrid, multi-cloud management platform for APIs across all environments. As a platform-as-a-service, API Management supports the complete API lifecycle.

We have more granular control to any APIs by using APIM.

- Consolidate the endpoint access by hiding APIs behind the APIM instance.
- Granular access control by issuing keys by using [subscriptions feature](https://learn.microsoft.com/azure/api-management/api-management-subscriptions). We can manage the access by API, APIs and/or by products.
- Use [policies](https://learn.microsoft.com/azure/api-management/api-management-howto-policies) to manage APIs such as setting thresholds, use different backends, set/remove headers, specify cache policies, etc.
- Manage APIs by using [backends](https://learn.microsoft.com/azure/api-management/backends?tabs=bicep) and security store keys and connection strings by using [named values](https://learn.microsoft.com/azure/api-management/api-management-howto-properties?tabs=azure-portal).
- It provides out-of-box monitor capabilities and custom logger that can send log to any supported destination when we need more detailed logging.
- Use custom logging to log the request and response body so calculate consumed token as well as analyze the content safety.

## Solution Architecture

![architecture](/assets/aoai_apim.svg)

# Repo structure

```shell
├─assets
├─LogParser
├─policies
├─PowerBIReports
├─queries
├─Dockerfile
└─README.md
```

- __LogParser__: C# sample code to parse the log in the event hub, transform and send them to Application Insights and Cosmos Db
- __policies__: APIM policy fragments
- __PowerBIReports__: contains sample Power BI reports
- __queries__: contains Kusto and Cosmos DB query that are used for creating report
- __Dockerfile__: Build the Log Parser as a docker image

See the following for more detail in each component.

- [How to use Azure API Management with Azure Open AI](APIM.md)
- [C# Log Parser](/LogParser/README.md)
- [Power BI Reports](/PowerBIReports/README.md)

# Limitations

Currently, there are several limitations.

- Body size exceeds 200 KB: APIM truncate the log if entire data exceeds 200 KB. In that case, the log parser cannot read the log as it's truncated in the middle of the log.
- Function Calling with stream mode: We are not consolidating the result for function calling in stream mode for now.
- GPT 4 Vision with URL: If there is authentication/authorization for the image URL that the log parser cannot obtain, it fails to read the image.