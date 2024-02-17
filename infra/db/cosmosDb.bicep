// Copyright (c) Microsoft. All rights reserved.

param location string
param accountName string
param databaseName string
param logContainerName string
param triggerContainerName string
param primaryRegion string
param keyVaultName string
param vnetName string
param pepSubnetName string
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

resource logContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: database
  name: logContainerName
  properties: {
    resource: {
      id: logContainerName
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

resource triggerContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: database
  name: triggerContainerName
  properties: {
    resource: {
      id: triggerContainerName
      partitionKey: {
        paths: [
          '/id'
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
    pepSubnetName: pepSubnetName
    privateLinkServiceId: account.id
    vnetName: vnetName
    location: location
  }
}

resource cosmosDbConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${toLower(accountName)}-ConnectionString'
  parent: vault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: account.listConnectionStrings().connectionStrings[0].connectionString
  }
}
