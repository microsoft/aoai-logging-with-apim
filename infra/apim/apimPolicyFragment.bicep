// Copyright (c) Microsoft. All rights reserved.

param apiManagementServiceName string

var inboundLoggingFragment = loadTextContent('../../policies/inbound-logging.xml')

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource inboundLogging 'Microsoft.ApiManagement/service/policyFragments@2023-03-01-preview' = {
  name: 'inbound-logging'
  parent: apiManagementService
  properties: {
    description: 'string'
    format: 'rawxml'
    value: inboundLoggingFragment
  }
}
