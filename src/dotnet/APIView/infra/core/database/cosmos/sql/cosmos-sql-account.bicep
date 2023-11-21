metadata description = 'Creates an Azure Cosmos DB for NoSQL account.'
param name string
param location string = resourceGroup().location
param tags object = {}

module cosmos '../../cosmos/cosmos-account.bicep' = {
  name: 'cosmos-account'
  params: {
    name: name
    location: location
    tags: tags
    kind: 'GlobalDocumentDB'
  }
}

// output connectionString string = cosmos.outputs.connectionString
output endpoint string = cosmos.outputs.endpoint
output id string = cosmos.outputs.id
output name string = cosmos.outputs.name