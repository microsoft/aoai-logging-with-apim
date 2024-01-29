// Copyright (c) Microsoft. All rights reserved.

@description('Specifies a Event Hub Namespace name that is used for APIM logger.')
param eventHubNamespaceName string

@description('Specifies a Event Hub name.')
param eventHubName string

@description('Specifies the Azure location for all resources.')
param location string

@description('Specifies the messaging tier for Event Hub Namespace.')
@allowed([
  'Basic'
  'Standard'
])
param eventHubSku string

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
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
