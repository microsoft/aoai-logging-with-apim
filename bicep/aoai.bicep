// Copyright (c) Microsoft. All rights reserved.

@description('Specifies an Azure Open AI name.')
param aoaiName string

@description('Location for all resources.')
param location string

@description('The name of the key vault to be created.')
param keyVaultName string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

var deployments = [
  {
    name: 'text-embedding-ada-002'
    version: '2'
    capacity: 10
  }
  {
    name: 'gpt-35-turbo'
    version: '0613'
    capacity: 10
  }
  {
    name: 'gpt-35-turbo-instruct'
    version: '0914'
    capacity: 10
  }
]

resource aoai 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: aoaiName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {     
  }
}

@batchSize(1)
resource models 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for deployment in deployments: {
  name: deployment.name
  parent: aoai
  sku: {
    name: 'Standard'
    capacity: deployment.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: deployment.name
      version: deployment.version
    }
    raiPolicyName: 'Microsoft.Default'
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
}]

resource aoaiKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: aoaiName
  parent: vault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: aoai.listKeys().key1
  }
}
