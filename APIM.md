# How to use Azure API Management (APIM) with Azure Open AI (AOAI)

To solve [the challenges](/README.md#challenges-of-azure-open-ai-in-production), we can use several APIM features.

# APIs

First, we need to add API definition for the AOAI. There are several features we recommend we to use while adding the API. 

## Named values

[Names values](https://learn.microsoft.com/azure/api-management/api-management-howto-properties?tabs=azure-portal) are the place where we can store secrets safely. It supports three value types.

|Type	|Description|
|---|---|
|Plain|	Literal string or policy expression|
|Secret|	Literal string or policy expression that is encrypted by API Management|
|Key vault|	Identifier of a secret stored in an Azure key vault.|

We recommend storing AOAI keys in the Key Vault, and create named values by referencing them.

![Named values](/assets/namedValues.png)

## Backends

We can use [backends](https://learn.microsoft.com/azure/api-management/backends?tabs=bicep) to manage AOAI accounts. Backend supports specifying headers, so we can use the named value to set AOAI key for each backend. Add ``openai`` as part of the base address.

![Backend](/assets//backend.png)

## APIs

We can create API definition either by manual or import OpenAPI definition. We can find the Open API definition for each version of AOAI [here](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference)

Please note that we need to modify the endpoint address.

See [Add an API manually](https://learn.microsoft.com/azure/api-management/add-api-manually) or [Import an OpenAPI specification](https://learn.microsoft.com/azure/api-management/import-api-from-oas?tabs=portal) for more detail how to add the API.

Once we added APIs, we can edit the inbound policy to specify backend that we created.

```xml
<policies>
    <inbound>
        <base />
        <set-backend-service backend-id="AOAIbackend" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```
See [API Management policies overview](https://learn.microsoft.com/azure/api-management/api-management-howto-policies) for more detail about policies.

We need to set API URL suffix as ``oepnai`` that makes the base address as ``https://<apim_account>.azure-api.net/openai

![API URL suffix](/assets/api_url_suffix.png)

Then use the rest of the URL as the post method address.

![GPT-35 post settings](/assets/gpt_35_post_settings.png)

With these settings, when the user access ``https://<apim_account>.azure-api.net/openai/deployments/gpt-35-turbo/chat/completions?api-version=2023-12-01-preview``, the request will be matched to this definition and will be redirected to ``<backend>/deployments/gpt-35-turbo/chat/completions?api-version=2023-12-01-previe`` because the backend contains ``openai`` as part of the base address.

# Subscriptions

We hide AOAI keys by using named values and backend feature. Then we can give new key to end users, that is APIM subscription keys.

[Subscriptions](https://learn.microsoft.com/azure/api-management/api-management-subscriptions) are the most common way for API consumers to access APIs published through an API Management instance.

We can control the [scope of the subscriptions](https://learn.microsoft.com/azure/api-management/api-management-subscriptions#scope-of-subscriptions) so that each subscription may have different set of APIs to access.

Name the subscription key so that it's easy to distinguish later.

## Subscription key name

By default, we use ``Ocp-Apim-Subscription-Key`` as a header key name for the subscription keys. To make APIs compatible with AOAI, however, we need to change the key name to ``api-key`` that is same as AOAI. By doing this, we can simply replace the endpoint URL and the key of the existing applications to make them work.

![Subscription key name](/assets/subscription_key_name.png)

## Throttling by subscription key

If we want to set the throttling for each subscription key, we need to use [product](https://learn.microsoft.com/azure/api-management/api-management-howto-add-products?tabs=azure-portal) feature. By using product, we can:
- Set APIs to consume
- Set policy 

For example, we can add policy as below.

![Product policy](/assets/product_policy.png)

```xml
<policies>
    <inbound>
        <rate-limit calls="5" renewal-period="60" />
        <quota calls="100" renewal-period="604800" />
        <base />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

This policy limits the API calls by using [Rate limits and quotas](https://learn.microsoft.com/azure/api-management/api-management-sample-flexible-throttling#rate-limits-and-quotas).

Then we can create a subscription for the product.

![Alt text](/assets/product_subscription.png)

The users who use this key will be throttled based on the policy.

# Logging

APIM provides out-of-box logging capabilities. See [How to integrate Azure API Management with Azure Application Insights](https://learn.microsoft.com/azure/api-management/api-management-howto-app-insights?tabs=rest) for detail setup.

## Out-of-box logging and its limitations

This provides basic logging, and we can use [Azure-OpenAI-Insights](https://github.com/dolevshor/Azure-OpenAI-Insights) and [Visualize data using Managed Grafana](https://learn.microsoft.com/azure/api-management/visualize-using-managed-grafana-dashboard) to visualize the log.

However, these logging has some limitations.

- It doesn't log actual request and response body.
- When using streaming mode, it doesn't provide token usage information. See [How to stream completions](https://cookbook.openai.com/examples/how_to_stream_completions) for more detail.
- Limited logging destination. Only Application Insights, Azure Monitor and local.

## Custom Logging solution by using Event Hub

To solve these challenges, we can use Azure Event Hub to send any information for request/response, then handles log information by ourselves.

See [Log events to Azure Event Hubs](https://learn.microsoft.com/azure/api-management/api-management-howto-log-event-hubs?tabs=PowerShell) for detail setup.

This solution uses following [policy fragment](https://learn.microsoft.com/azure/api-management/policy-fragments) to log the request and response body as well as additional fields. You can easily add additional fields or remove unused fields from the policy.

[__inbound-logging__](/policies/inbound-logging.xml)
```xml
<fragment>
	<log-to-eventhub logger-id="aoailogger">@{
            var requestBody = context.Request.Body?.As<JObject>(true);
            var requestUrl = $"{context.Request.Url.Scheme}://{context.Request.Url.Host}:{context.Request.Url.Port}{context.Request.Url.Path}{context.Request.Url.QueryString}";
            var headers = new JObject();
            foreach(var header in context.Request.Headers)
            {
                if (header.Key == "api-key")
                {
                    continue;
                }
                headers[header.Key] = string.Join(",", header.Value);
            }
            return new JObject(
                new JProperty("type", "Request"),
                new JProperty("timestamp", context.Timestamp),
                new JProperty("subscriptionId", context.Subscription.Id),
                new JProperty("subscriptionName", context.Subscription.Name),
                new JProperty("operationId", context.Operation.Id),
                new JProperty("request", requestBody),
                new JProperty("serviceName", context.Deployment.ServiceName),
                new JProperty("requestId", context.RequestId),
                new JProperty("requestIp", context.Request.IpAddress),
                new JProperty("url", requestUrl),
                new JProperty("operationName", context.Operation.Name),
                new JProperty("region", context.Deployment.Region),
                new JProperty("apiName", context.Api.Name),
                new JProperty("apiRevision", context.Api.Revision),
                new JProperty("method", context.Operation.Method),
                new JProperty("headers", headers)
            ).ToString();
        }
    </log-to-eventhub>
</fragment>
```

[__outbound-logging__](/policies/outbound-logging.xml)
```xml
<fragment>
	<log-to-eventhub logger-id="aoailogger">@{
            var responseBody = context.Response.Body?.As<string>(true);
            return new JObject(
                new JProperty("type", "Response"),
                new JProperty("timestamp", context.Timestamp),
                new JProperty("elapsed", context.Elapsed),
                new JProperty("response", responseBody),
                new JProperty("statusCode", context.Response.StatusCode),
                new JProperty("requestId", context.RequestId),
                new JProperty("statusReason", context.Response.StatusReason)
            ).ToString();
        }
    </log-to-eventhub>
</fragment>
```
Once the policy fragments are defined, we can use it in the API policy scope. We can set it on the top level of the API or in each operation.

```xml
<policies>
    <inbound>
        <base />
        <include-fragment fragment-id="inbound-logging" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <include-fragment fragment-id="outbound-logging" />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

When the data is sent to the Event Hub instance, we use [Log Parser](/LogParser/) to parse and transform the logs, then store them into Application Insights and/or Cosmos DB instance. The log parser is the one which transforms the log to make various types of logs, such as Completion, Chat Completion, function callings, stream or non-stream, Embeddings results into identical format so that we can easily analyze the log.