targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param cosmosAccountName string = ''
param cosmosDatabaseName string = ''
param resourceGroupName string = ''
param blobName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : 'yumeng-${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The application database
module cosmos './app/db.bicep' = {
  name: 'yumeng-cosmos-${environmentName}'
  scope: rg
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    databaseName: cosmosDatabaseName
    location: location
    tags: tags
  }
}

// The application storage
module storage './app/storage.bicep' = {
  name: 'yumeng-storage-${environmentName}'
  scope: rg
  params: {
    name: !empty(blobName) ? blobName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
  }
}

// Data outputs
// output AZURE_COSMOS_CONNECTION_STRING string = cosmos.outputs.connectionString
output AZURE_COSMOS_DATABASE_NAME string = cosmos.outputs.databaseName
output AZURE_STORAGE_NAME string = storage.outputs.name
output AZURE_STORAGE_PRIMARY_ENDPOINTS object = storage.outputs.primaryEndpoints

// App outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
