// Copyright (c) Microsoft. All rights reserved.

param keyVaultName string
param eventHubName string
param applicationInsightsName string
param cosmosDbAccountName string
param cosmosDbDatabaseName string
param cosmosDbContainerName string
param webAppName string
param appServicePlanName string
param location string
param sku string
param vnetName string
param subnetName string
param privateEndpointSubnetName string
param privateEndpointName string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: toLower(cosmosDbAccountName)
}

resource sendConnection 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: '${eventHubName}-Send'
  parent: vault
}

resource cosmosDbKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: toLower(cosmosDbAccountName)
  parent: vault
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: subnetName
  parent: vnet
}

resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: asp.id
    httpsOnly: true
    virtualNetworkSubnetId: subnet.id
    publicNetworkAccess: 'Disabled'
    siteConfig: {
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
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
          name: 'EventHubConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${sendConnection.properties.secretUri})'
        }
        {
          name: 'CosmosDbUrl'
          value: cosmosDbAccount.properties.documentEndpoint
        }
        {
          name: 'CosmosDbDatabaseName'
          value: cosmosDbDatabaseName
        }
        {
          name: 'CosmosDbCollectionName'
          value: cosmosDbContainerName
        }
        {
          name: 'CosmosDbKey'
          value: '@Microsoft.KeyVault(SecretUri=${cosmosDbKey.properties.secretUri})'
        }
      ]
      phpVersion: 'OFF'
      netFrameworkVersion: 'v8.0'
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
  }
}

module privateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${webAppName}-privateEndpoint'
  params: {
    groupIds: [
      'sites'
    ]
    dnsZoneName: 'privatelink.azurewebsites.net'
    name: privateEndpointName
    subnetName: privateEndpointSubnetName
    privateLinkServiceId: webApp.id
    vnetName: vnetName
    location: location
  }
}

output webAppIdentityId string = webApp.identity.principalId
