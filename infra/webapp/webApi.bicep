// Copyright (c) Microsoft. All rights reserved.

param location string
param loggingWebApiName string
param appServicePlanName string
param sku string
param keyVaultName string
param applicationInsightsName string
param cosmosDbAccountName string
param cosmosDbDatabaseName string
param cosmosDbLogContainerName string
param cosmosDbTriggerContainerName string
param vnetName string
param webAppSubnetName string
param pepSubnetName string
param loggingWebApiPrivateEndpointName string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource cosmosDbConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: '${toLower(cosmosDbAccountName)}-ConnectionString'
  parent: vault
}

resource applicationInsightsConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: '${applicationInsightsName}-ConnectionString'
  parent: vault
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource webAppSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: webAppSubnetName
  parent: vnet
}

resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
}

resource loggingWebApi 'Microsoft.Web/sites@2022-03-01' = {
  name: loggingWebApiName
  location: location
  tags: {
    'azd-service-name': 'loggingWebApi'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: asp.id
    httpsOnly: true
    virtualNetworkSubnetId: webAppSubnet.id
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${applicationInsightsConnectionString.properties.secretUri})'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
        {
          name: 'CosmosDbConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${cosmosDbConnectionString.properties.secretUri})'
        }  
        {
          name: 'CosmosDbDatabaseName'
          value: cosmosDbDatabaseName
        }
        {
          name: 'CosmosDbLogContainerName'
          value: cosmosDbLogContainerName
        }
        {
          name: 'CosmosDbTriggerContainerName'
          value: cosmosDbTriggerContainerName
        }
      ]
      phpVersion: 'OFF'
      netFrameworkVersion: 'v8.0'
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      alwaysOn: true
    }
  }
}

module webAppPrivateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${loggingWebApiName}-privateEndpoint'
  params: {
    location: location
    name: loggingWebApiPrivateEndpointName
    groupIds: [
      'sites'
    ]
    dnsZoneName: 'privatelink.azurewebsites.net'
    vnetName: vnetName
    pepSubnetName: pepSubnetName
    privateLinkServiceId: loggingWebApi.id
  }
}

output loggingWebApiIdentityId string = loggingWebApi.identity.principalId
