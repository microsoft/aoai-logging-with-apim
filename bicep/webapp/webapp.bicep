// Copyright (c) Microsoft. All rights reserved.

param eventHubNamespaceName string
param eventHubName string
param applicationInsightsName string
param cosmosDbName string
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

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: toLower(cosmosDbName)
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' existing = {
  name: eventHubNamespaceName
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' existing = {
  parent: eventHubNamespace
  name: eventHubName
}

resource send 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  parent: eventHub
  name: 'Send'
  properties: {
    rights: [
      'Send'
    ]
  }
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
          value: send.listKeys().primaryConnectionString
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
          value: cosmosDbAccount.listKeys().primaryMasterKey
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
