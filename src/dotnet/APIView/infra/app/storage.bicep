param name string
param location string = resourceGroup().location

param containers array = [
  {
    name: 'originals'
  }
  {
    name: 'codefiles'
  }
  {
    name: 'usagesamples'
  }
]


module storage '../core/storage/storage-account.bicep' = {
  name: 'storage'
  params: {
    name: name
    location: location
    containers: containers
  }
}

output name string = storage.name
output primaryEndpoints object = storage.outputs.primaryEndpoints