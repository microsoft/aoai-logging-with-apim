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

### Application Level

APIM Policy handles network traffic and logging.
![architecture](/assets/aoai_apim.svg)

### Network Level

This solution uses VNet and Private Endpoints to secure Azure resources.

- APIM: Use External VNet integration mode.
- Azure Function and Web App: Use VNet integration mode so that they can access Azure resources via VNet and private endpoints.
- Other resources: Use VNet and private endpoint. Block all external access via Firewall rule.

# Repo structure

```shell
├─assets
├─bicep
├─LoggingWebApp
├─LogParserFunction
├─policies
├─PowerBIReports
├─queries
├─Dockerfile
└─README.md
```

- __bicep__: The infrastructure as code (IaC) assets.
- __LoggingWebApp__: C# sample Web API code to that works as proxy between APIM and AOAI, which send logs to Cosmos DB. Once logging completed, it sends the ``request id`` to the Event Hub.
- __Log Parser__: C# sample Azure Function code to parse the log in the Cosmos DB. It is triggered via Event Hub notification, then retrieve all the logs for the ``request id``, transform them and store the final log to Application Insights.
- __policies__: APIM policy fragments
- __PowerBIReports__: contains sample Power BI reports
- __queries__: contains Kusto and Cosmos DB query that are used for creating report

See the following for more detail in each component.

- [How to use Azure API Management with Azure Open AI](APIM.md)
- [Infrastructure as Code (bicep)](/bicep/README.md)
- [C# Logging Web App](/LoggingWebApp/README.md)
- [C# Log Parser Function](/LogParserFunction/README.md)
- [Power BI Reports](/PowerBIReports/README.md)

# Limitations

Currently, there are several limitations.

- Function Calling with stream mode: We are not consolidating the result for function calling in stream mode for now.
- GPT 4 Vision with URL: If there is authentication/authorization for the image URL that the log parser cannot obtain, it fails to read the image.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
