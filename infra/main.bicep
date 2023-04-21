targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

param feedIngestion bool = true

param apiImageName string = ''
param hubImageName string = ''
param ingestionImageName string = ''
param updaterImageName string = ''
param webImageName string = ''
param dataStore string = 'PostgreSQL'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Container apps host (including container registry)
module containerApps './core/host/container-apps.bicep' = {
  name: 'container.apps'
  scope: rg
  params: {
    name: 'app'
    containerAppsEnvironmentName: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
}

// Store secrets in a keyvault
module keyVault 'core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

module apiPostgreSql './core/host/springboard-container-app.bicep' = {
  name: 'podcast.sql'
  scope: rg
  params: {
    name: '${abbrs.dBforPostgreSQLServers}podcast-${resourceToken}'
    location: location
    tags: tags
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    serviceType: 'postgres'
  }
}

module hubPostgreSql './core/host/springboard-container-app.bicep' = {
  name: 'listentogether.sql'
  scope: rg
  params: {
    name: '${abbrs.dBforPostgreSQLServers}hub-${resourceToken}'
    location: location
    tags: tags
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    serviceType: 'postgres'
  }
}

module storage 'app/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    allowBlobPublicAccess: true
    keyVaultName: keyVault.outputs.name
    tags: tags
  }
}

module web 'web.bicep' = {
  name: 'podcast.web'
  scope: rg
  params: {
    name: '${abbrs.appContainerApps}web-${resourceToken}'
    location: location
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    imageName: webImageName
    keyVaultName: keyVault.outputs.name
    apiBaseUrl: api.outputs.SERVICE_API_URI
    listenTogetherHubUrl: hub.outputs.LISTEN_TOGETHER_HUB
    tags: tags
  }
}

module hub 'hub.bicep' = {
  name: 'listentogether.hub'
  scope: rg
  params: {
    name: '${abbrs.appContainerApps}hub-${resourceToken}'
    location: location
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    imageName: hubImageName
    keyVaultName: keyVault.outputs.name
    orleansStorageConnectionStringKey: storage.outputs.orleansStorageConnectionStringKey
    apiBaseUrl: api.outputs.SERVICE_API_URI
    keyVaultEndpoint: keyVault.outputs.endpoint
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    dataStore: dataStore
    serviceBinds: [
      hubPostgreSql.outputs.serviceBind
    ]
    tags: tags
  }
}

module api 'api.bicep' = {
  name: 'podcast.api'
  scope: rg
  params: {
    name: '${abbrs.appContainerApps}api-${resourceToken}'
    location: location
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    imageName: apiImageName
    keyVaultName: keyVault.outputs.name
    feedQueueConnectionStringKey: storage.outputs.feedQueueConnectionStringKey
    keyVaultEndpoint: keyVault.outputs.endpoint
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    feedIngestion: '${feedIngestion}'
    dataStore: dataStore
    serviceBinds: [
      apiPostgreSql.outputs.serviceBind
    ]
    tags: tags
  }
}

module updaterWorker 'updater.bicep' = {
  name: 'updater.worker'
  scope: rg
  params: {
    name: '${abbrs.appContainerApps}updater-${resourceToken}'
    location: location
    keyVaultName: keyVault.outputs.name
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    imageName: updaterImageName
    keyVaultEndpoint: keyVault.outputs.endpoint
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    dataStore: dataStore
    serviceBinds: [
      apiPostgreSql.outputs.serviceBind
    ]
    tags: tags
  }
}

module ingestionWorker 'ingestion.bicep' = if (feedIngestion) {
  name: 'ingestion.worker'
  scope: rg
  params: {
    name: '${abbrs.appContainerApps}ingestion-${resourceToken}'
    location: location
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    imageName: ingestionImageName
    keyVaultName: keyVault.outputs.name
    feedQueueConnectionStringKey: storage.outputs.feedQueueConnectionStringKey
    keyVaultEndpoint: keyVault.outputs.endpoint
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    tags: tags
    dataStore: dataStore
    serviceBinds: [
      apiPostgreSql.outputs.serviceBind
    ]
  }
}

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
  }
}

// Data outputs
output AZURE_FEED_QUEUE_CONNECTION_STRING_KEY string = storage.outputs.feedQueueConnectionStringKey
output AZURE_ORLEANS_STORAGE_CONNECTION_STRING_KEY string = storage.outputs.orleansStorageConnectionStringKey
output AZURE_STORAGE_PRIMARY_KEY_STRING_KEY string = storage.outputs.storagePrimaryKeyConnectionStringKey

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = '' //containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = ''//containerApps.outputs.registryName
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output REACT_APP_API_BASE_URL string = api.outputs.SERVICE_API_URI
output REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output REACT_APP_HUB_BASE_URL string = hub.outputs.SERVICE_HUB_URI
output REACT_APP_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
output REACT_FEATURES_FEED_INGESTION string = '${feedIngestion}'
output REACT_LISTEN_TOGETHER_HUB string = hub.outputs.LISTEN_TOGETHER_HUB
output REACT_RESOURCE_GROUP_NAME string = rg.name
output REACT_STORAGE_NAME string = storage.outputs.name
output SERVICE_API_NAME string = api.outputs.SERVICE_API_NAME
output SERVICE_HUB_NAME string = hub.outputs.SERVICE_HUB_NAME
output SERVICE_INGESTION_NAME string = ingestionWorker.outputs.SERVICE_INGESTION_NAME
output SERVICE_UPDATER_NAME string = updaterWorker.outputs.SERVICE_UPDATER_NAME
output SERVICE_WEB_NAME string = web.outputs.SERVICE_WEB_NAME
