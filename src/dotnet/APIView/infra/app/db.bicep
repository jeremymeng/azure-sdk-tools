param accountName string
param location string = resourceGroup().location
param tags object = {}

param containers array = [
  {
    id: 'Reviews'
    partitionKey '/id'
  }
  {
    id: 'Comments'
    partitionKey '/ReviewId'
  }
  {
    id: 'PullRequests'
    partitionKey '/PullRequestNumber'
  }
  {
    id: 'UsageSamples'
    partitionKey 'ReviewId'
  }
  {
    id: 'UserPreference'
    partitionKey 'UserName'
  }
  {
    id: 'Profiles'
    partitionKey 'id'
  }
]
param databaseName string = ''

// Because databaseName is optional in main.bicep, we make sure the database name is set here.
var defaultDatabaseName = 'APIView'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

module cosmos '../core/database/cosmos/sql/cosmos-sql-db.bicep' = {
  params: {
    accountName: accountName
    databaseName: actualDatabaseName
    location: location
    containers: containers
    tags: tags
  }
}

output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = cosmos.outputs.databaseName
output endpoint string = cosmos.outputs.endpoint