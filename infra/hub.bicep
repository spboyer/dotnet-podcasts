param name string
param location string = resourceGroup().location
param tags object = {}
param keyVaultName string
param containerAppsEnvironmentName string
param imageName string
param keyVaultEndpoint string
param applicationInsightsConnectionString string
param orleansStorageConnectionStringKey string
param apiBaseUrl string
param dataStore string
param serviceBinds array = []

var serviceName = 'hub'

module app 'core/host/container-app.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    imageName: !empty(imageName) ? imageName : 'nginx:latest'
    keyVaultName: keyVault.name
    env: [
      {
        name: 'DATA_STORE'
        value: dataStore
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
        name: 'AZURE_ORLEANS_STORAGE_CONNECTION_STRING_KEY'
        value: orleansStorageConnectionStringKey
      }
      {
        name: 'REACT_APP_API_BASE_URL'
        value: apiBaseUrl
      }
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: 'Development'
      }
    ]
    serviceBinds: serviceBinds
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

output LISTEN_TOGETHER_HUB string = '${app.outputs.uri}/listentogether'
output SERVICE_HUB_IDENTITY_PRINCIPAL_ID string = app.outputs.identityPrincipalId
output SERVICE_HUB_NAME string = app.outputs.name
output SERVICE_HUB_URI string = app.outputs.uri
output SERVICE_HUB_IMAGE_NAME string = app.outputs.imageName

