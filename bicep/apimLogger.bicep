// Copyright (c) Microsoft. All rights reserved.

@description('The name of the API Management service instance')
param apiManagementServiceName string

@description('The name of Event Hub Namespace for the logger.')
param eventHubNamespaceName string

@description('The name of Event Hub for the logger.')
param eventHubName string

@description('The name of the logger.')
param loggerName string

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubNamespaceName
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' existing = {
  parent: eventHubNamespace
  name: eventHubName
}

resource send 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' existing = {
  parent: eventHub
  name: 'Send'
}

var eventHubNamespaceConnectionString = send.listKeys().primaryConnectionString

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-03-01-preview' = {
  name: loggerName
  parent: apiManagementService
  properties: {
    loggerType: 'azureEventHub'
    description: 'Event hub logger with connection string'
    credentials: {
      connectionString: eventHubNamespaceConnectionString
      name: eventHubNamespace.name
    }
  }
}
