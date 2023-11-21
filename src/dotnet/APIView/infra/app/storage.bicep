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


module blob '../core/storage/storage-account.bicep' = {
  params: {
    name: name
    location: location
    containers: containers
    tags: tags
  }
}