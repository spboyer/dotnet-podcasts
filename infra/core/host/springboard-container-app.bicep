param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string = ''
param serviceType string = ''

resource app 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      service: {
        type: serviceType
      }
    }
    template: {
      containers: [
        {
          name: name
          image: serviceType
        }
      ]
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

output serviceBind object = {
  serviceId: app.id
  name: name
}

output app object = app
output name string = app.name

