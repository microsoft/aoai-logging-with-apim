// Copyright (c) Microsoft. All rights reserved.

param location string
param applicationInsightsName string
param workspaceName string
param keyVaultName string
param vnetName string
param pepSubnetName string
param privateEndpointName string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource privateLinkScope 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: 'private-link-scope'
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'Open'
      queryAccessMode: 'Open'
    }
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {}
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource workspaceScopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  parent: privateLinkScope
  name: '${workspaceName}-connection'
  properties: {
    linkedResourceId: workspace.id
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'other'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: workspace.id
    RetentionInDays: 90
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module privateEndpoint '../network/privateEndpoint.bicep' = {
  name: '${applicationInsightsName}-privateEndpoint'
  params: {
    groupIds: [
      'azuremonitor'
    ]
    dnsZoneName: 'privatelink.monitor.azure.com'
    name: privateEndpointName
    pepSubnetName: pepSubnetName
    privateLinkServiceId: privateLinkScope.id
    vnetName: vnetName
    location: location
  }
  dependsOn: [
    applicationInsights
  ]
}

resource appInsightsScopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  parent: privateLinkScope
  name: '${applicationInsightsName}-connection'
  properties: {
    linkedResourceId: applicationInsights.id
  }
  dependsOn: [
    privateEndpoint
  ]
}

resource applicationInsightsConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${applicationInsightsName}-ConnectionString'
  parent: vault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: applicationInsights.properties.ConnectionString
  }
}

resource applicationInsightsKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: applicationInsightsName
  parent: vault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: applicationInsights.properties.InstrumentationKey
  }
}
