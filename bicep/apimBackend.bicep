// Copyright (c) Microsoft. All rights reserved.

@description('The name of the API Management service instance')
param apiManagementServiceName string

@description('The name of the key vault to be created.')
param keyVaultName string

@description('Specifies an Azure Open AI name.')
param aoaiName string

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: aoaiName
}

resource namedValue 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  name: aoaiName
  parent: apiManagementService
  properties: {
    displayName: aoaiName
    keyVault: {
      identityClientId: null
      secretIdentifier: 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/${aoaiName}'
    }
    secret: true
  }
}

resource backend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: aoaiName
  parent: apiManagementService
  properties: {
    protocol: 'http'
    url: '${aoai.properties.endpoint}openai'
    credentials: {
       header: {
         'api-key':['{{${aoaiName}}}']
       }
    }
  }
}
