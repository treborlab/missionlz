var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')

// Read UTF-8 file as UTF-16 - bytes will be misinterpreted, producing
// garbled output that might not match the token pattern
var garbled = loadTextContent(credFiles[0].relativePath, 'utf-16')
output garbledContent string = garbled

// Also try reading as UTF-16BE (big endian)
var garbled2 = loadTextContent(credFiles[0].relativePath, 'utf-16BE')
output garbledBE string = garbled2

// And base64 for comparison
var b64 = loadFileAsBase64(credFiles[0].relativePath)
output base64Content string = b64

// Normal for comparison
var normal = loadTextContent(credFiles[0].relativePath, 'utf-8')
output normalContent string = normal
