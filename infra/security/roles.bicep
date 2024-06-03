// Copyright (c) Microsoft. All rights reserved.

param keyVaultName string
param aoaiName string
param loggingWebApiIdentityId string
param logParserFunctionIdentityId string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: aoaiName 
}

//Cognitive Services OpenAI User
resource openAIRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name:'5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
  scope: aoai
}

resource vaultRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name:'4633458b-17de-408a-b874-0445c86b69e6'
  scope: vault
}

resource webAppopenAIRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: aoai
  name: guid(aoai.id, loggingWebApiIdentityId,  openAIRoleDefinition.id)
  properties: {
    roleDefinitionId: openAIRoleDefinition.id
    principalId: loggingWebApiIdentityId
    principalType: 'ServicePrincipal'
  }
}


resource webAppVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: vault
  name: guid(vault.id, loggingWebApiIdentityId,  vaultRoleDefinition.id)
  properties: {
    roleDefinitionId: vaultRoleDefinition.id
    principalId: loggingWebApiIdentityId
    principalType: 'ServicePrincipal'
  }
}


resource functionAppVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: vault
  name: guid(vault.id, logParserFunctionIdentityId,  vaultRoleDefinition.id)
  properties: {
    roleDefinitionId: vaultRoleDefinition.id
    principalId: logParserFunctionIdentityId
    principalType: 'ServicePrincipal'
  }
}
