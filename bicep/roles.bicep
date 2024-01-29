// Copyright (c) Microsoft. All rights reserved.

@description('The name of the key vault to be created.')
param keyVaultName string

@description('Specifies an APIM identity id.')
param apimIdentityId string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name:'4633458b-17de-408a-b874-0445c86b69e6'
  scope: vault
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: vault
  name: guid(vault.id, apimIdentityId,  roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: apimIdentityId
    principalType: 'ServicePrincipal'
  }
}
