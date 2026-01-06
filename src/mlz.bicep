var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')
var raw = loadTextContent(credFiles[0].relativePath)

// Force an error that might include the value
var badIndex = substring(raw, 9999, 1)
output x string = badIndex
