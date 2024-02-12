// Copyright (c) Microsoft. All rights reserved.

param keyVaultName string
param apimIdentityId string
param webAppIdentityId string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name:'4633458b-17de-408a-b874-0445c86b69e6'
  scope: vault
}

resource apimRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: vault
  name: guid(vault.id, apimIdentityId,  roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: apimIdentityId
    principalType: 'ServicePrincipal'
  }
}

resource webAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: vault
  name: guid(vault.id, webAppIdentityId,  roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: webAppIdentityId
    principalType: 'ServicePrincipal'
  }
}

