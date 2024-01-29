// Copyright (c) Microsoft. All rights reserved.

@description('Specifies a project name that is used to generate resource names. If you want to assign each name by yourself, or use existing ones, specify each name one by one.')
@minLength(4)
param projectName string

@description('Specifies the Azure location for all resources.')
param location string = resourceGroup().location

@description('Azure Open AI Name')
param aoaiName string = '${projectName}-aoai' 

@description('Application Insights Name')
param applicationInsightsName string = '${projectName}-ai'

@description('Application Insights Workspace Name')
param workspaceName string = '${projectName}-ai-workspace'

@description('Key Vault Name')
param keyVaultName string = '${projectName}-kv'

@description('Key Vault Sku')
param keyVaultSku string = 'standard'

@description('Event Hub Namespae')
param eventHubNamespaceName string = '${projectName}-ns'

@description('Event Hub Name')
param eventHubName string = projectName

@description('Event Hub Sku')
param eventHubSku string = 'Basic'

@description('Azure API Management Name')
param apiManagementServiceName string = '${projectName}-apim'

@description('Azure API Management Sku')
param apimSku string = 'Developer'

@description('Azure API Management Publisher Email')
param publisherEmail string = 'your_email_address@your.domain'

@description('Azure API Management Publisher Name')
param publisherName string = 'Your Name'

//## Create Application Insights ##
module applicationInsights './applicationInsights.bicep' = {
  name: 'applicationInsightsDeployment'
  params: {
    location: location
    applicationInsightsName: applicationInsightsName
    workspaceName: workspaceName
  }
}

//## Create Key Vault that stores Azure Open AI Key ##
module keyVault './keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    skuName: keyVaultSku
  }
}

//## Create Azure Open AI and stores the key to the Key Vault ##
module aoai './aoai.bicep' = {
  name: 'aoaiDeployment'
  params: {
    aoaiName: aoaiName
     keyVaultName: keyVaultName
    location: location
  }
  dependsOn: [
    keyVault
  ]
}

//## Create Event Hub Namespace and Event Hub so that Azure API Management can send logs to it ##
module eventHub './eventHub.bicep' = {
  name: 'eventHubDeployment'
  params: {
    eventHubNamespaceName: eventHubNamespaceName
    eventHubName: eventHubName
    location: location
    eventHubSku: eventHubSku
  }
}

//## Create API Management ##
module apim './apim.bicep' = {
  name: 'apimDeployment'
  params: {
    apiManagementServiceName: apiManagementServiceName
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: apimSku
    skuCount: 1
  }
}

//## Assign API Managemnet Managed Identity to appropriate roles ## 
module roles './roles.bicep' = {
  name: 'rolesDeployment'
  params: {
     apimIdentityId: apim.outputs.apimIdentityId
     keyVaultName: keyVaultName
  }
  dependsOn: [
    apim
    keyVault
  ]
}

//## Create Event Hub Logger ##
module apimLogger './apimLogger.bicep' = {
  name: 'apimLoggerDeployment'
  params: {
    apiManagementServiceName: apiManagementServiceName
    eventHubName: eventHubName
    eventHubNamespaceName: eventHubNamespaceName
    loggerName: 'aoailogger' // This name is also used in the policy fragment
  }
  dependsOn: [
    apim
    eventHub
  ]
}

//## Link the Application Insights to API Management ##
module apimApplicationInsights './apimApplicationInsights.bicep' = {
  name: 'apimApplicationInsightsDeployment'
  params: {
    apiManagementServiceName: apiManagementServiceName
    applicationInsightsName: applicationInsightsName
  }
  dependsOn: [
    apim
    applicationInsights
  ]
}

//## Create API Management Policy for APIs ##
module apimPolicyFragment './apimPolicyFragment.bicep' = {
  name: 'apimPolicyFragmentDeployment'
  params: {
    apiManagementServiceName: apiManagementServiceName
  }
  dependsOn: [
    apim
    eventHub
  ]
}

//## Create Named Value ad Backed to store Azure Open AI Inforamtion ##
module apimBackend './apimBackend.bicep' = {
  name: 'apimBackendDeployment'
  params: {
     apiManagementServiceName: apiManagementServiceName
     aoaiName: aoaiName
     keyVaultName: keyVaultName
  }
  dependsOn: [
    aoai
    apim
    keyVault
    roles
  ]
}

//## Create API Management API and Operations ##
module apimApis './apimApis.bicep' = {
  name: 'apimApisDeployment'
  params: {
    apiManagementServiceName: apiManagementServiceName
    aoaiName: aoaiName
    applicationInsightsName: applicationInsightsName
  }
  dependsOn: [
    apim
    aoai
    apimBackend
  ]
}
