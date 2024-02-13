// Copyright (c) Microsoft. All rights reserved.

param keyVaultName string
param apimIdentityId string
param loggingWebAppIdentityId string
param logParserFunctionIdentityId string

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
  name: guid(vault.id, loggingWebAppIdentityId,  roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: loggingWebAppIdentityId
    principalType: 'ServicePrincipal'
  }
}

resource functionAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: vault
  name: guid(vault.id, logParserFunctionIdentityId,  roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: logParserFunctionIdentityId
    principalType: 'ServicePrincipal'
  }
}
