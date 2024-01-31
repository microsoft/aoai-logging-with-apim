// Copyright (c) Microsoft. All rights reserved.

@description('The Azure Open AI name.')
param aoaiName string

@description('The private endpoint name.')
param privateEndpointName string

@description('Location for all resources.')
param location string

@description('The name of the key vault to be created.')
param keyVaultName string

@description('The virtual network name.')
param vnetName string

@description('The virtual network subnet name.')
param subnetName string

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
    customSubDomainName: toLower(aoaiName)
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
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

module privateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${aoaiName}-privateEndpoint'
  params: {
    groupIds: [
      'account'
    ]
    dnsZoneName: 'privatelink.openai.azure.com'
    name: privateEndpointName
    subnetName: subnetName
    privateLinkServiceId: aoai.id
    vnetName: vnetName
    location: location
  }
}
