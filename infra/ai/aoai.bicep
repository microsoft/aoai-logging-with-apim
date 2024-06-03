// Copyright (c) Microsoft. All rights reserved.

param location string
param aoaiName string
param vnetName string
param pepSubnetName string
param privateEndpointName string
param deployments array

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
  }
}

@batchSize(1)
resource models 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for deployment in deployments: {
  name: deployment.deploymentName
  parent: aoai
  sku: {
    name: deployment.skuName
    capacity: deployment.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: deployment.modelName
      version: deployment.version
    }
    raiPolicyName: 'Microsoft.Default'
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
}]

module privateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${aoaiName}-privateEndpoint'
  params: {
    groupIds: [
      'account'
    ]
    dnsZoneName: 'privatelink.openai.azure.com'
    name: privateEndpointName
    pepSubnetName: pepSubnetName
    privateLinkServiceId: aoai.id
    vnetName: vnetName
    location: location
  }
}
