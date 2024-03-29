// Copyright (c) Microsoft. All rights reserved.

param location string
param logParserFunctionName string
param appServicePlanName string
param sku string
param functionStorageAccountName string
param functionStorageAccountType string
param keyVaultName string
param applicationInsightsName string
param cosmosDbAccountName string
param cosmosDbDatabaseName string
param cosmosDbLogContainerName string
param cosmosDbTriggerContainerName string
param contentSafetyAccountName string
param vnetName string
param webAppSubnetName string
param pepSubnetName string
param logParserFunctionPrivateEndpointName string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource contentSafety 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: contentSafetyAccountName
}

resource cosmosDbConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: '${toLower(cosmosDbAccountName)}-ConnectionString'
  parent: vault
}

resource contentSafetyKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: contentSafetyAccountName
  parent: vault
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource applicationInsightsConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: '${applicationInsightsName}-ConnectionString'
  parent: vault
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource webAppSubne 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
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

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: functionStorageAccountName
  location: location
  sku: {
    name: functionStorageAccountType
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource logParserFunction 'Microsoft.Web/sites@2022-03-01' = {
  name: logParserFunctionName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    'azd-service-name': 'logParserFunction'
  }
  kind: 'functionapp'
  properties: {
    serverFarmId: asp.id
    httpsOnly: true
    virtualNetworkSubnetId: webAppSubne.id
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
            name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
            value: '1'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(logParserFunctionName)
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
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
        {
          name: 'ContentSafetyUrl'
          value: contentSafety.properties.endpoint
        }
        {
          name: 'ContentSafetyKey'
          value: '@Microsoft.KeyVault(SecretUri=${contentSafetyKey.properties.secretUri})'
        }
        {
          name: 'ApplicationInsightsConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${applicationInsightsConnectionString.properties.secretUri})'
        }
      ]
      phpVersion: 'OFF'
      netFrameworkVersion: 'v8.0'
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      alwaysOn: true
      use32BitWorkerProcess: false
      vnetRouteAllEnabled: true
    }
  }
}

module functionPrivateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${logParserFunctionName}-privateEndpoint'
  params: {
    groupIds: [
      'sites'
    ]
    dnsZoneName: 'privatelink.azurewebsites.net'
    name: logParserFunctionPrivateEndpointName
    pepSubnetName: pepSubnetName
    privateLinkServiceId: logParserFunction.id
    vnetName: vnetName
    location: location
  }
}

output logParserFunctionIdentityId string = logParserFunction.identity.principalId
