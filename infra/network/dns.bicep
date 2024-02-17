// Copyright (c) Microsoft. All rights reserved.

param privateDnsZoneNames array

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for privateDnsZoneName in privateDnsZoneNames: {
  name: privateDnsZoneName
  location: 'global'
}]
