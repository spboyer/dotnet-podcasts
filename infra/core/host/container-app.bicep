param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string = ''
param containerName string = 'main'
param env array = []
param enableIngres bool = true
param external bool = true
param imageName string
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)
param targetPort int = 80
param serviceBinds array = []
param minReplicas int = 1
param maxReplicas int = 1

@description('CPU cores allocated to a single container instance, e.g. 0.5')
param containerCpuCoreCount string = '0.5'

@description('Memory allocated to a single container instance, e.g. 1Gi')
param containerMemory string = '1.0Gi'

#disable-next-line BCP081
resource app 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: name
  location: location
  tags: tags
  identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: enableIngres ? {
        external: external
        targetPort: targetPort
        transport: 'auto'
      } : null
    }
    template: {
      serviceBinds: serviceBinds
      containers: [
        {
          image: imageName
          name: containerName
          env: env
          resources: {
            cpu: json(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

output identityPrincipalId string = managedIdentity ? app.identity.principalId : ''
output imageName string = imageName
output name string = app.name
output uri string = enableIngres ? 'https://${app.properties.configuration.ingress.fqdn}' : ''
output appId string = app.id
