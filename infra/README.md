# Infrastructure as Code (bicep)

We can use the bicep files to provision a sample environment. [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/) is an Infrastructure as Code (IaC) solution for Azure that let us write YAML to define the Azure resources. 

## Run the bicep

1. Create a resource group in your subscription
1. Run the ``az`` command.
    ```shell
    az deployment group create -g <resource group name> -f .\main.bicep --parameters projectName=<project_name>
    ```
1. Wait until all the resources are deployed.

## Resources

The bicep files deploys following resources.

- Network: Virtual Network, Subnet, DNS, Public IP address and private endpoint to secure Azure Resources.
- Application Insights: Logging metrics from APIM.
- Key Vault: Stores the keys and connection strings.
- Cosmos Db: The temporary log store.
- AOAI and Deployments: The AOAI account and three deployments. gpt-35-turbo, gpt-35-turbo-instruct, and text-ada-embedding-002.
- APIM: The APIM instance
  - Named Value: Linked to the Key Vault for AOAI key.
  - Backend: Stores the AOAI endpoint information with ``api-key`` header.
  - Policy Fragments: The inbound and outbound logging policy.
  - API and Operations: The API and the operations of Azure Open AI deployments.
- Web App and Function App: The logging related components.

## How to test

Once the deployment has been completed, we should be able to consume the endpoint.

1. Get the subscription key that has access to the deployed API.
1. Use any HTTP client tool to call the Chat Completion, Completion or Embedding endpoint.

The header and body formats are exactly same as AOAI endpoints. Only the differences are the endpoint address and the key, which is APIM subscription key.

As other resources are protected from external access, you cannot access to AOAI endpoint directly.

# Use existing resources

You can pass parameters to the ``main.bicep`` if you want to use existing Key Vault, Application Insights, etc. See [main.bicep](./main.bicep) for parameters information.

# How to customize

Each bicep contains each resource definitions. For example, if you want to change the model and deployment names for the AOAI, change the ``deployments`` variable in [aoai.bicep](./aoai.bicep).

When you change the deployment, you also need to update the ``deployments`` variable in [apimApis.bicep](./apimApis.bicep) as they are closely related.