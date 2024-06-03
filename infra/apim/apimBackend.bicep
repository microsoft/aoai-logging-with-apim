// Copyright (c) Microsoft. All rights reserved.

param apiManagementServiceName string
param aoaiName string
param loggingWebApiName string

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: aoaiName
}

resource webApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: loggingWebApiName
}

resource backendNamedValue 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  name: 'backend-${aoaiName}'
  parent: apiManagementService
  properties: {
    displayName: 'backend-${aoaiName}'
    value: '${aoai.properties.endpoint}openai/'
    secret: false
  }
}

resource backend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: loggingWebApiName
  parent: apiManagementService
  properties: {
    protocol: 'http'
    url: 'https://${webApp.properties.defaultHostName}/openai/'
  }
}
