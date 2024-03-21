// Copyright (c) Microsoft. All rights reserved.

param apiManagementServiceName string
param aoaiName string
param loggingWebApiName string
param applicationInsightsName string

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: aoaiName
}

resource api 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  name: 'AzureOpenAI'
  parent: apiManagementService
  properties: {
    apiType: 'http'
    description: 'Azure Open AI API'
    displayName: 'Azure Open AI'
    path: 'openai'
    protocols: [
      'https'
    ]
    serviceUrl: '${aoai.properties.endpoint}openai'
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    subscriptionRequired: true
    type: 'http'
  }
}

var apiPolicy = loadTextContent('../../policies/api-policy.xml')

resource topLevelPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'rawxml'
    value: apiPolicy
  }
}

resource diag 'Microsoft.ApiManagement/service/apis/diagnostics@2023-03-01-preview' = {
  name: 'applicationinsights'
  parent: api
  properties: {
    alwaysLog: 'allErrors'
    metrics: true
    operationNameFormat: 'Name'
    verbosity: 'information'
    logClientIp: true
    httpCorrelationProtocol: 'W3C'
    loggerId: resourceId('Microsoft.ApiManagement/service/loggers', applicationInsightsName, applicationInsightsName)
  }
}

var originalOperationPolicy = loadTextContent('../../policies/operation-policy.xml')
var operationPolicy1 = replace(originalOperationPolicy, '{{api-key}}', '{{${aoaiName}}}')
var operationPolicy2 = replace(operationPolicy1, '{{backend-url}}', '{{backend-${aoaiName}}}')
var operationPolicy = replace(operationPolicy2, '{backend-id}', loggingWebApiName)

var deployments = [
  {
    name: 'Embedding'
    displayName: 'Embedding'
    description: 'Embedding'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/embeddings?api-version={api-version}'
    backend: aoaiName
  }
  {
    name: 'Completon'
    displayName: 'GPT Completion'
    description: 'GPT Completion'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/completions?api-version={api-version}'
    backend: aoaiName
  }
  {
    name: 'ChatCompleton'
    displayName: 'Chat Completion'
    description: 'Chat Completion'
    method: 'POST'
    urlTemplate: '/deployments/{deployment-id}/chat/completions?api-version={api-version}'
    backend: aoaiName
  }  
]

resource operations 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = [for i in range(0, length(deployments)): {
  name: deployments[i].name
  parent: api
  properties: {
    description: deployments[i].description
    displayName: deployments[i].displayName
    method: deployments[i].method
    templateParameters: [
      {
        name: 'deployment-id'
        required: true
        type: 'string'
      }
      {
        name: 'api-version'
        required: true
        type: 'string'
      }
    ]
    urlTemplate: deployments[i].urlTemplate
  }
}]

resource operationLevelpolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-03-01-preview' = [for i in range(0, length(deployments)): {
  name: 'policy'
  parent: operations[i]
  properties: {
    format: 'rawxml'
    value: operationPolicy
  }
}]
