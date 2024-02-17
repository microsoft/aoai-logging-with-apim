// Copyright (c) Microsoft. All rights reserved.

param apiManagementServiceName string
param applicationInsightsName string

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource logger 'Microsoft.ApiManagement/service/loggers@2023-03-01-preview' = {
  name: applicationInsightsName
  parent: apiManagementService
  properties: {
    loggerType: 'applicationInsights'
    description: 'Application Insights logger with connection string'
    credentials: {
      connectionString: applicationInsights.properties.ConnectionString
    }
  }
}
