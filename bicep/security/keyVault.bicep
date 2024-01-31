// Copyright (c) Microsoft. All rights reserved.

param keyVaultName string
param keyVaultPrivateEndpointName string
param location string
param skuName string
param vnetName string
param subnetName string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies:[]
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    tenantId: subscription().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

module privateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${keyVaultName}-privateEndpoint'
  params: {
    groupIds: [
      'vault'
    ]
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    name: keyVaultPrivateEndpointName
    subnetName: subnetName
    privateLinkServiceId: vault.id
    vnetName: vnetName
    location: location
  }
}
