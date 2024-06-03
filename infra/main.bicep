// Copyright (c) Microsoft. All rights reserved.

targetScope = 'subscription'
var abbrs = loadJsonContent('./abbreviations.json')

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('Azure API Management Publisher Email')
param publisherEmail string = 'your_email_address@your.domain'

@description('Azure API Management Publisher Name')
param publisherName string = 'Your Name'

@description('Azure location for all resources.')
param location string

@description('Resource Group Name')
param resourceGroupName string = ''

@description('Azure Open AI Name')
param aoaiName string = ''

@description('Azure Open AI Token Limit TPM. default is 1000')
param tokenLimitTPM int = 10000

@description('Application Insights Name')
param applicationInsightsName string = ''

@description('Application Insights Workspace Name')
param workspaceName string = ''

@description('Key Vault Name')
param keyVaultName string = ''

@description('Key Vault Sku')
@allowed([
  'standard'
  'premium'
])
param keyVaultSku string = 'standard'

@description('Azure API Management Name')
param apiManagementServiceName string = ''

@description('Cosmos Db Account Name')
param cosmosDbAccountName string = ''

@description('Cosmos Db Database Name')
param cosmosDbDatabaseName string = 'Logs'

@description('Cosmos Db Log Container Name')
param cosmosDbLogContainerName string = 'TempLogs'

@description('Cosmos Db Trigger Container Name')
param cosmosDbTriggerContainerName string = 'LogTriggers'

@description('Content Safety Account Name')
param contentSafetyAccountName string = ''

@description('Logging Web App Name')
param loggingWebApiName string = ''

@description('Log Parser Function App Name')
param logParserFunctionName string = ''

@description('Log Parser Function Storage Account Name')
param functionStorageAccountName string = ''

@description('App Service Name for Logging and Log Parser')
param appServiceName string = ''

@description('Public IP name for Azure API Management')
param publicIpName string = ''

@description('Azure API Management Sku')
@allowed([
  'Developer'
  'BasicV2'
  'StandardV2'
  'Premium'
])
param apimSku string = 'StandardV2'

@description('Azure API Management Sku Count')
@allowed([
  0
  1
  2
])
param skuCount int = 1

@description('Virtual Network Name')
param vnetName string = ''

@description('Virtual Network Subnet Name for APIM')
param apimSubnetName string = ''

@description('Virtual Network Subnet Name for Private Endpoints')
param pepSubnetName string = ''

@description('Virtual Network Subnet Name for Web App')
param webAppSubnetName string = ''

@description('Network Security Group Name for APIM')
param apimNsgName string = ''

@description('Private Endpoint Name for Application Insights')
param applicationInsightsPrivateEndpointName string = ''

@description('Private Endpoint Name for Key Vault')
param keyVaultPrivateEndpointName string = ''

@description('Private Endpoint Name for Azure Open AI')
param aoaiPrivateEndpointName string = ''

@description('Private Endpoint Name for Cosmos Db')
param cosmosDbPrivateEndpointName string = ''

@description('Private Endpoint Name for Logging Web App')
param loggingWebApiPrivateEndpointName string = ''

@description('Private Endpoint Name for Log Parser Function App')
param logParserFunctionPrivateEndpointName string = ''

@description('Private Endpoint Name for Content Safety')
param contentSafetyPrivateEndpointName string = ''

var privateDnsZoneNames = [
  'privatelink.openai.azure.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.monitor.azure.com'
  'privatelink.documents.azure.com'
  'privatelink.azurewebsites.net'
  'privatelink.cognitiveservices.azure.com'
]

var deployments = [
  {
    name: 'Embedding'
    displayName: 'Embedding'
    description: 'Embedding'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/embeddings?api-version={api-version}'
    backend: aoaiName
    modelName: 'text-embedding-ada-002'
    deploymentName: 'text-embedding-ada-002'
    version: '2'
    capacity: 10
    skuName:'Standard'
  }
  {
    name: 'Completon'
    displayName: 'GPT Completion'
    description: 'GPT Completion'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/completions?api-version={api-version}'
    backend: aoaiName
    modelName: 'gpt-35-turbo-instruct'
    deploymentName: 'gpt-35-turbo-instruct'
    version: '0914'
    capacity: 10
    skuName:'Standard'
  }
  {
    name: 'ChatCompleton'
    displayName: 'Chat Completion'
    description: 'Chat Completion'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/chat/completions?api-version={api-version}'
    backend: aoaiName
    modelName: 'gpt-4o'
    deploymentName: 'gpt-4o'
    version: '2024-05-13'
    capacity: 10
    skuName:'GlobalStandard'
  }  
]

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
}

//## Create Dns for Private Endpoint ##
module dns './network/dns.bicep' = {
  scope: rg
  name: 'dnsDeployment'
  params: {
     privateDnsZoneNames:privateDnsZoneNames
  }
}

//## Create VNet ##
module vnet './network/vnet.bicep' = {
  scope: rg
  name: 'vnetDeployment'
  params: {
    location: location
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    apimSubnetName: !empty(apimSubnetName) ? apimSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.apiManagementService}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    webAppSubnetName: !empty(webAppSubnetName) ? webAppSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.webSitesAppService}${environmentName}'
    apimNsgName: !empty(apimNsgName) ? apimNsgName : '${abbrs.networkNetworkSecurityGroups}${abbrs.apiManagementService}${environmentName}'
    privateDnsZoneNames: privateDnsZoneNames
  }
  dependsOn: [
    dns
  ]
}

//## Create Key Vault that stores Keys ##
module keyVault './security/keyVault.bicep' = {
  scope: rg
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}'
    skuName: keyVaultSku
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    keyVaultPrivateEndpointName: !empty(keyVaultPrivateEndpointName) ? keyVaultPrivateEndpointName : '${abbrs.networkPrivateLinkServices}${abbrs.keyVaultVaults}${environmentName}'
  }
  dependsOn: [
    vnet
    dns
  ]
}

//## Create Cosmos Db ##
module cosmosDb './db/cosmosDb.bicep' = {
  scope: rg
  name: 'cosmosDbDeployment'
  params: {
    location: location
    accountName: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbrs.documentDBDatabaseAccounts}${environmentName}'
    databaseName: cosmosDbDatabaseName
    logContainerName: cosmosDbLogContainerName
    triggerContainerName: cosmosDbTriggerContainerName
    primaryRegion: location
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}'
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    privateEndpointName: !empty(cosmosDbPrivateEndpointName) ? cosmosDbPrivateEndpointName : '${abbrs.networkPrivateLinkServices}${abbrs.documentDBDatabaseAccounts}${environmentName}'
  }
  dependsOn:[
    vnet
    dns
    keyVault
  ]
}

//## Create Application Insights ##
module applicationInsights './monitoring/applicationInsights.bicep' = {
  scope: rg
  name: 'applicationInsightsDeployment'
  params: {
    location: location
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}'
    workspaceName: !empty(workspaceName) ? workspaceName : '${abbrs.operationalInsightsWorkspaces}${environmentName}'
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}'
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    privateEndpointName: !empty(applicationInsightsPrivateEndpointName) ? applicationInsightsPrivateEndpointName : '${abbrs.networkPrivateLinkServices}${abbrs.insightsComponents}${environmentName}'
  }
  dependsOn: [
    vnet
    dns
    keyVault
  ]
}

//## Create Application Insights ##
module contentsafety './ai/contentSafety.bicep' = {
  scope: rg
  name: 'contentsafetyDeployment'
  params: {
    location: location
    contentSafetyAccountName: !empty(contentSafetyAccountName) ? contentSafetyAccountName : '${abbrs.cognitiveServicesContentSafety}${environmentName}'
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}'
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    privateEndpointName: !empty(contentSafetyPrivateEndpointName) ? contentSafetyPrivateEndpointName : '${abbrs.networkPrivateLinkServices}${abbrs.cognitiveServicesContentSafety}${environmentName}'
  }
  dependsOn: [
    vnet
    dns
    keyVault
  ]
}

//## Create Azure Open AI and stores the key to the Key Vault ##
module aoai './ai/aoai.bicep' = {
  scope: rg
  name: 'aoaiDeployment'
  params: {
    location: location
    aoaiName: !empty(aoaiName) ? aoaiName : '${abbrs.cognitiveServicesOpenAi}${environmentName}'
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    privateEndpointName: !empty(aoaiPrivateEndpointName) ? aoaiPrivateEndpointName : '${abbrs.networkPrivateLinkServices}${abbrs.cognitiveServicesOpenAi}${environmentName}'
    deployments: deployments
  }
  dependsOn: [
    keyVault
    vnet
    dns
  ]
}

module loggingWebApi './webapp/webApi.bicep' = {
  scope: rg
  name: 'webApiDeployment'
  params: {
    location: location
    loggingWebApiName: !empty(loggingWebApiName) ? loggingWebApiName : '${abbrs.webSitesAppService}loggingweb-${environmentName}'
    appServicePlanName: !empty(appServiceName) ? appServiceName : '${abbrs.webServerFarms}${environmentName}'
    sku: 'S1'
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}'
    cosmosDbAccountName: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbrs.documentDBDatabaseAccounts}${environmentName}'
    cosmosDbDatabaseName: cosmosDbDatabaseName
    cosmosDbLogContainerName: cosmosDbLogContainerName
    cosmosDbTriggerContainerName: cosmosDbTriggerContainerName
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    webAppSubnetName: !empty(webAppSubnetName) ? webAppSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.webSitesAppService}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    loggingWebApiPrivateEndpointName: !empty(loggingWebApiPrivateEndpointName) ? loggingWebApiPrivateEndpointName : '${abbrs.networkPrivateLinkServices}${abbrs.webSitesAppService}loggingweb-${environmentName}'
  }
  dependsOn: [
    vnet
    dns
    applicationInsights
    cosmosDb
    keyVault
    contentsafety
  ]
}

module logParserFunction './webapp/function.bicep' = {
  scope: rg
  name: 'webAppDeployment'
  params: {
    location: location
    logParserFunctionName: !empty(logParserFunctionName) ? logParserFunctionName : '${abbrs.webSitesFunctions}logparser-${environmentName}'
    appServicePlanName: !empty(appServiceName) ? appServiceName : '${abbrs.webServerFarms}${environmentName}'
    sku: 'S1'
    functionStorageAccountName: !empty(functionStorageAccountName) ? functionStorageAccountName : '${abbrs.storageStorageAccounts}logparser${environmentName}'
    functionStorageAccountType: 'Standard_LRS'
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}'
    cosmosDbAccountName: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbrs.documentDBDatabaseAccounts}${environmentName}'
    cosmosDbDatabaseName: cosmosDbDatabaseName
    cosmosDbLogContainerName: cosmosDbLogContainerName
    cosmosDbTriggerContainerName: cosmosDbTriggerContainerName
    contentSafetyAccountName: !empty(contentSafetyAccountName) ? contentSafetyAccountName : '${abbrs.cognitiveServicesContentSafety}${environmentName}'
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    webAppSubnetName: !empty(webAppSubnetName) ? webAppSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.webSitesAppService}${environmentName}'
    pepSubnetName: !empty(pepSubnetName) ? pepSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.networkPrivateLinkServices}${environmentName}'
    logParserFunctionPrivateEndpointName: !empty(logParserFunctionPrivateEndpointName) ? logParserFunctionPrivateEndpointName : '${abbrs.networkPrivateLinkServices}${abbrs.webSitesFunctions}logparser-${environmentName}'
  }
  dependsOn: [
    vnet
    dns
    applicationInsights
    cosmosDb
    keyVault
    contentsafety
  ]
}

module publicIp './network/publicIp.bicep' = {
  scope: rg
  name: 'publicIpDeployment'
  params: {
    location: location
    publicIpName: !empty(publicIpName) ? publicIpName : '${abbrs.networkPublicIPAddresses}${environmentName}'
  }
}

//## Create API Management ##
module apim './apim/apim.bicep' = {
  scope: rg
  name: 'apimDeployment'
  params: {
    location: location
    apiManagementServiceName: !empty(apiManagementServiceName) ? apiManagementServiceName : '${abbrs.apiManagementService}${environmentName}'
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: apimSku
    skuCount: skuCount
    publicIpName: !empty(publicIpName) ? publicIpName : '${abbrs.networkPublicIPAddresses}${environmentName}'
    vnetName: !empty(vnetName) ? vnetName : '${abbrs.networkVirtualNetworks}${environmentName}'
    apimSubnetName: !empty(apimSubnetName) ? apimSubnetName : '${abbrs.networkVirtualNetworksSubnets}${abbrs.apiManagementService}${environmentName}'
  }
  dependsOn: [
    vnet
    dns
    loggingWebApi
    logParserFunction
  ]
}

//## Assign API Managemnet Managed Identity to appropriate roles ## 
module roles './security/roles.bicep' = {
  scope: rg
  name: 'rolesDeployment'
  params: {
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}'
    aoaiName: !empty(aoaiName) ? aoaiName : '${abbrs.cognitiveServicesOpenAi}${environmentName}'
    loggingWebApiIdentityId: loggingWebApi.outputs.loggingWebApiIdentityId
    logParserFunctionIdentityId: logParserFunction.outputs.logParserFunctionIdentityId
  }
  dependsOn: [
    apim
    keyVault
    loggingWebApi
    logParserFunction
  ]
}

//## Link the Application Insights to API Management ##
module apimApplicationInsights './apim/apimApplicationInsights.bicep' = {
  scope: rg
  name: 'apimApplicationInsightsDeployment'
  params: {
    apiManagementServiceName: !empty(apiManagementServiceName) ? apiManagementServiceName : '${abbrs.apiManagementService}${environmentName}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}'
  }
  dependsOn: [
    apim
    applicationInsights
  ]
}

//## Create API Management Policy for APIs ##
module apimPolicyFragment './apim/apimPolicyFragment.bicep' = {
  scope: rg
  name: 'apimPolicyFragmentDeployment'
  params: {
    apiManagementServiceName: !empty(apiManagementServiceName) ? apiManagementServiceName : '${abbrs.apiManagementService}${environmentName}'
  }
  dependsOn: [
    apim
  ]
}

//## Create Named Value ad Backed to store Azure Open AI Inforamtion ##
module apimBackend './apim/apimBackend.bicep' = {
  scope: rg
  name: 'apimBackendDeployment'
  params: {
     apiManagementServiceName: !empty(apiManagementServiceName) ? apiManagementServiceName : '${abbrs.apiManagementService}${environmentName}'
     aoaiName: !empty(aoaiName) ? aoaiName : '${abbrs.cognitiveServicesOpenAi}${environmentName}'
     loggingWebApiName: !empty(loggingWebApiName) ? loggingWebApiName : '${abbrs.webSitesAppService}loggingweb-${environmentName}'
  }
  dependsOn: [
    aoai
    apim
    keyVault
    roles
    loggingWebApi
    logParserFunction
  ]
}

//## Create API Management API and Operations ##
module apimApis './apim/apimApis.bicep' = {
  scope: rg
  name: 'apimApisDeployment'
  params: {
    apiManagementServiceName: !empty(apiManagementServiceName) ? apiManagementServiceName : '${abbrs.apiManagementService}${environmentName}'
    aoaiName: !empty(aoaiName) ? aoaiName : '${abbrs.cognitiveServicesOpenAi}${environmentName}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}'
    loggingWebApiName: !empty(loggingWebApiName) ? loggingWebApiName : '${abbrs.webSitesAppService}loggingweb-${environmentName}'
    deployments: deployments
    tokenLimitTPM: tokenLimitTPM
  }
  dependsOn: [
    apim
    aoai
    apimBackend
    loggingWebApi
    logParserFunction
  ]
}
