// Copyright (c) Microsoft. All rights reserved.

param location string
param publicIpName string

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    dnsSettings: {
      domainNameLabel: publicIpName
    }
    publicIPAllocationMethod: 'Static'
  }
}
