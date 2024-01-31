// Copyright (c) Microsoft. All rights reserved.

param apiManagementServiceName string
param publisherEmail string
param publisherName string
param sku string
param skuCount int
param location string
param publicIpName string
param vnetName string
param subnetName string

resource apimSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  name: '${vnetName}/${subnetName}'
}


resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' existing  = {
  name: publicIpName
}

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'External'
    publicIpAddressId: publicIP.id
    virtualNetworkConfiguration: {
       subnetResourceId: apimSubnet.id
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output apimIdentityId string = apiManagementService.identity.principalId
