// Copyright (c) Microsoft. All rights reserved.

param keyVaultName string
param accountName string
param location string
param primaryRegion string
param databaseName string
param containerName string
param vnetName string
param subnetName string
param privateEndpointName string

var locations = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: false
  }
]

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: toLower(accountName)
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableMultipleWriteLocations: false
    enableAutomaticFailover: false
    publicNetworkAccess: 'Disabled'
    capabilities: [
      {
        name: 'DeleteAllItemsByPartitionKey'
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: account
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/requestId'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ]
      }
      defaultTtl: 86400
    }
  }
}

module privateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${accountName}-privateEndpoint'
  params: {
    groupIds: [
      'Sql'
    ]
    dnsZoneName: 'privatelink.documents.azure.com'
    name: privateEndpointName
    subnetName: subnetName
    privateLinkServiceId: account.id
    vnetName: vnetName
    location: location
  }
}

resource cosmosDbKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: toLower(accountName)
  parent: vault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: account.listKeys().primaryMasterKey
  }
}
