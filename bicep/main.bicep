// Copyright (c) Microsoft. All rights reserved.

@description('Project name that is used to generate resource names. If you want to assign each name by yourself, or use existing ones, specify each name one by one.')
@minLength(4)
@maxLength(10)
param projectName string

@description('Azure location for all resources.')
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
@allowed([
  'standard'
  'premium'
])
param keyVaultSku string = 'standard'

@description('Event Hub Namespae')
param eventHubNamespaceName string = '${projectName}-ns'

@description('Event Hub Name')
param eventHubName string = projectName

@description('Event Hub Sku')
param eventHubSku string = 'Standard'

@description('Azure API Management Name')
param apiManagementServiceName string = '${projectName}-apim'

@description('Public IP name for Azure API Management')
param publicIpName string = '${apiManagementServiceName}-publicip'

@description('Azure API Management Sku')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param apimSku string = 'Developer'

@description('Azure API Management Sku Count')
@allowed([
  0
  1
  2
])
param skuCount int = 1

@description('Azure API Management Publisher Email')
param publisherEmail string = 'your_email_address@your.domain'

@description('Azure API Management Publisher Name')
param publisherName string = 'Your Name'

@description('Virtual Network Name')
param vnetName string = '${projectName}-vnet'

@description('Virtual Network Subnet Name for APIM')
param apimSubnetName string = '${projectName}-apim-subnet'

@description('Virtual Network Subnet Name for Private Endpoints')
param pepSubnetName string = '${projectName}-pep-subnet'

@description('Network Security Group Name for APIM')
param apimNsgName string = '${projectName}-apim-nsg'

@description('Private Endpoint Name for Application Insights')
param applicationInsightsPrivateEndpointName string = '${projectName}-ai-pep'

@description('Private Endpoint Name for Key Vault')
param keyVaultPrivateEndpointName string = '${projectName}-kv-pep'

@description('Private Endpoint Name for Azure Open AI')
param aoaiPrivateEndpointName string = '${projectName}-aoai-pep'

@description('Private Endpoint Name for Event Hub Namespace')
param eventHubPrivateEndpointName string = '${projectName}-ns-pep'

var privateDnsZoneNames = [
  'privatelink.openai.azure.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.servicebus.windows.net'
  'privatelink.monitor.azure.com'
]

//## Create Dns for Private Endpoint ##
module dns './network/dns.bicep' = {
  name: 'dnsDeployment'
  params: {
     privateDnsZoneNames:privateDnsZoneNames
  }
}

//## Create VNet ##
module vnet './network/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    vnetName: vnetName
    apimSubnetName: apimSubnetName
    pepSubnetName: pepSubnetName
    apimNsgName: apimNsgName
    privateDnsZoneNames: privateDnsZoneNames
  }
  dependsOn: [
    dns
  ]
}

//## Create Application Insights ##
module applicationInsights './monitoring/applicationInsights.bicep' = {
  name: 'applicationInsightsDeployment'
  params: {
    location: location
    applicationInsightsName: applicationInsightsName
    workspaceName: workspaceName
    privateEndpointName: applicationInsightsPrivateEndpointName
    vnetName: vnetName
    subnetName: pepSubnetName
  }
  dependsOn: [
    vnet
    dns
  ]
}

//## Create Key Vault that stores Azure Open AI Key ##
module keyVault './security/keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    skuName: keyVaultSku
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    vnetName: vnetName
    subnetName: pepSubnetName
  }
  dependsOn: [
    vnet
    dns
  ]
}

//## Create Azure Open AI and stores the key to the Key Vault ##
module aoai './/aoai/aoai.bicep' = {
  name: 'aoaiDeployment'
  params: {
    aoaiName: aoaiName
    keyVaultName: keyVaultName
    location: location
    privateEndpointName: aoaiPrivateEndpointName
    vnetName: vnetName
    subnetName: pepSubnetName
  }
  dependsOn: [
    keyVault
    vnet
    dns
  ]
}

//## Create Event Hub Namespace and Event Hub so that Azure API Management can send logs to it ##
module eventHub './/eventhub/eventHub.bicep' = {
  name: 'eventHubDeployment'
  params: {
    eventHubNamespaceName: eventHubNamespaceName
    eventHubName: eventHubName
    location: location
    eventHubSku: eventHubSku
    privateEndpointName: eventHubPrivateEndpointName
    vnetName: vnetName
    subnetName: pepSubnetName
  }
  dependsOn: [
    vnet
    dns
  ]
}

module publicIp './network/publicIp.bicep' = {
  name: 'publicIpDeployment'
  params: {
    location: location
    publicIpName: publicIpName
  }
}

//## Create API Management ##
module apim './apim/apim.bicep' = {
  name: 'apimDeployment'
  params: {
    apiManagementServiceName: apiManagementServiceName
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: apimSku
    skuCount: skuCount
    publicIpName: publicIpName
    vnetName: vnetName
    subnetName: apimSubnetName
  }
  dependsOn: [
    vnet
    dns
  ]
}

//## Assign API Managemnet Managed Identity to appropriate roles ## 
module roles './security/roles.bicep' = {
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
module apimLogger './apim/apimLogger.bicep' = {
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
module apimApplicationInsights './apim/apimApplicationInsights.bicep' = {
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
module apimPolicyFragment './apim/apimPolicyFragment.bicep' = {
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
module apimBackend './apim/apimBackend.bicep' = {
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
module apimApis './apim/apimApis.bicep' = {
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
