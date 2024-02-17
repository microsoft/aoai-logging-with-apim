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

We can use [backends](https://learn.microsoft.com/azure/api-management/backends?tabs=bicep) to manage the Logging Web App. Add ``aoai`` at the end as we use this part to create AOAI request.

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
        <set-header name="AOAI-Api-Key" exists-action="override">
            <value>{{api-key}}</value>
        </set-header>
        <set-header name="Backend-Url" exists-action="override">
            <value>{{backend-url}}</value>
        </set-header>
        <set-backend-service backend-id="logging-web" />
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

We need to set API URL suffix as ``oepnai`` that makes the base address as ``https://<apim_account>.azure-api.net/openai``

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

## AOAI Out-of-box logging and its limitations

AOAI provides basic logging, and we can use [Azure-OpenAI-Insights](https://github.com/dolevshor/Azure-OpenAI-Insights) and [Visualize data using Managed Grafana](https://learn.microsoft.com/azure/api-management/visualize-using-managed-grafana-dashboard) to visualize the log.

However, these logging has some limitations.

- It doesn't log actual request and response body.
- When using streaming mode, it doesn't provide token usage information. See [How to stream completions](https://cookbook.openai.com/examples/how_to_stream_completions) for more detail.

## Custom Logging solution by using Web API proxy

To solve these challenges, we can use Web API as proxy between APIM and AOAI that send logs to Cosmos DB.

APIM has an Event Hub logger to send any information for request/response, then handles log information by ourselves, however it has several critical limitations.

- The 200KB size limit for each log
- When using AOAI streaming mode, APIM blocks it as it needs to capture all response before sending SSE to the client. 

See [Log events to Azure Event Hubs](https://learn.microsoft.com/azure/api-management/api-management-howto-log-event-hubs?tabs=PowerShell) and [Configure API for server-sent events](https://learn.microsoft.com/en-us/azure/api-management/how-to-server-sent-events) for more detail.

This solution uses C# Web API as a proxy to overcome these limitations. We use following [policy fragment](https://learn.microsoft.com/azure/api-management/policy-fragments) to send the information to the proxy via headers. You can add/remove headers by yourself.

[__inbound-logging__](/policies/inbound-logging.xml)
```xml
<fragment>
	<set-header name="Timestamp" exists-action="override">
		<value>@(context.Timestamp.ToString())</value>
	</set-header>
	<set-header name="Subscription-Id" exists-action="override">
		<value>@(context.Subscription.Id.ToString())</value>
	</set-header>
	<set-header name="Subscription-Name" exists-action="override">
		<value>@(context.Subscription.Name)</value>
	</set-header>
	<set-header name="Operation-Id" exists-action="override">
		<value>@(context.Operation.Id.ToString())</value>
	</set-header>
	<set-header name="Service-Name" exists-action="override">
		<value>@(context.Deployment.ServiceName)</value>
	</set-header>
	<set-header name="Request-Id" exists-action="override">
		<value>@(context.RequestId.ToString())</value>
	</set-header>
	<set-header name="Request-Ip" exists-action="override">
		<value>@(context.Request.IpAddress)</value>
	</set-header>
	<set-header name="Operation-Name" exists-action="override">
		<value>@(context.Operation.Name)</value>
	</set-header>
	<set-header name="Region" exists-action="override">
		<value>@(context.Deployment.Region)</value>
	</set-header>
	<set-header name="Api-Name" exists-action="override">
		<value>@(context.Api.Name)</value>
	</set-header>
	<set-header name="Api-Revision" exists-action="override">
		<value>@(context.Api.Revision)</value>
	</set-header>
	<set-header name="Method" exists-action="override">
		<value>@(context.Operation.Method)</value>
	</set-header>
</fragment>
```
Once the policy fragments are defined, we can use it in the API policy scope. We can set it on the top level of the API or in each operation.

The ``forward-request`` is important to support SSE.

```xml
<policies>
    <inbound>
        <base />
        <include-fragment fragment-id="inbound-logging" />
    </inbound>
    <backend>
        <forward-request timeout="120" fail-on-error-status-code="true" buffer-response="false" />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

When the [Logging Web API](/LoggingWebApi/) stores all the logs to Cosmos DB account, it sends the ``request id`` to Event Hub so that [Log Parser Function](/LogParserFunction/) is triggered. It transforms the various types of logs, such as Completion, Chat Completion, function callings, stream or non-stream, Embeddings results into identical format so that we can easily analyze the log.