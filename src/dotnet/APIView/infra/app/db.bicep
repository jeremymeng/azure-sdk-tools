param accountName string
param location string = resourceGroup().location
param tags object = {}

param containers array = [
  {
    name: 'Reviews'
    id: 'Reviews'
    partitionKey: '/id'
  }
  {
    name: 'Comments'
    id: 'Comments'
    partitionKey: '/ReviewId'
  }
  {
    name: 'PullRequests'
    id: 'PullRequests'
    partitionKey: '/PullRequestNumber'
  }
  {
    name: 'UsageSamples'
    id: 'UsageSamples'
    partitionKey: '/ReviewId'
  }
  {
    name: 'UserPreference'
    id: 'UserPreference'
    partitionKey: '/UserName'
  }
  {
    name: 'Profiles'
    id: 'Profiles'
    partitionKey: '/id'
  }
]

param databaseName string = ''

// Because databaseName is optional in main.bicep, we make sure the database name is set here.
var defaultDatabaseName = 'APIView'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

module cosmos '../core/database/cosmos/sql/cosmos-sql-db.bicep' = {
  name: 'cosmos-sql'
  params: {
    accountName: accountName
    databaseName: actualDatabaseName
    location: location
    containers: containers
    tags: tags
  }
}

// output connectionString string = cosmos.outputs.connectionString
output databaseName string = cosmos.outputs.databaseName
output endpoint string = cosmos.outputs.endpoint