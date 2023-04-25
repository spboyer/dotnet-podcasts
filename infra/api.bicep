param name string
param location string = resourceGroup().location
param tags object = {}
param imageName string = ''
param containerAppsEnvironmentName string
param feedQueueConnectionStringKey string
param feedIngestion string
param keyVaultEndpoint string
param applicationInsightsConnectionString string
param keyVaultName string
param dataStore string
param serviceBinds array = []

var serviceName = 'api'

module app 'core/host/container-app.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    serviceBinds: serviceBinds
    env: [
      {
        name: 'DATA_STORE'
        value: dataStore
      }
      {
        name: 'AZURE_FEED_QUEUE_CONNECTION_STRING_KEY'
        value: feedQueueConnectionStringKey
      }
      {
        name: 'REACT_FEATURES_FEED_INGESTION'
        value: feedIngestion
      }
      {
        name: 'AZURE_KEY_VAULT_ENDPOINT'
        value: keyVaultEndpoint
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsightsConnectionString
      }
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: 'Development'
      }
    ]
    imageName: !empty(imageName) ? imageName : 'nginx:latest'
    keyVaultName: keyVault.name
  }
}

module keyVaultAccess 'core/security/keyvault-access.bicep' = {
  name: '${name}-keyvault-access'
  params: {
    keyVaultName: keyVaultName
    principalId: app.outputs.identityPrincipalId
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = app.outputs.identityPrincipalId
output SERVICE_API_NAME string = app.outputs.name
output SERVICE_API_URI string = app.outputs.uri
output SERVICE_API_IMAGE_NAME string = app.outputs.imageName
