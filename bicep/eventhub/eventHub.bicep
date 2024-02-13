// Copyright (c) Microsoft. All rights reserved.

param keyVaultName string
param eventHubNamespaceName string
param eventHubName string
param privateEndpointName string
param location string
param vnetName string
param subnetName string
param eventHubSku string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    //publicNetworkAccess: 'Disabled' // Consider enabling this when Log Parser can access to it from the vnet
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 1
    partitionCount: 1
  }
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

resource listenSend 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  parent: eventHub
  name: 'ListenSend'
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

module privateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${eventHubNamespaceName}-privateEndpoint'
  params: {
    groupIds: [
      'namespace'
    ]
    dnsZoneName: 'privatelink.servicebus.windows.net'
    name: privateEndpointName
    subnetName: subnetName
    privateLinkServiceId: eventHubNamespace.id
    vnetName: vnetName
    location: location
  }
}

resource sendConnection 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${eventHubName}-Send'
  parent: vault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: send.listKeys().primaryConnectionString
  }
}

resource listenConnection 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${eventHubName}-ListenSend'
  parent: vault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: listenSend.listKeys().primaryConnectionString
  }
}
