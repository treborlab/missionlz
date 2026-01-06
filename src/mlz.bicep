var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')

// Read UTF-8 file as UTF-16 - bytes will be misinterpreted, producing
// garbled output that might not match the token pattern
var garbled = loadTextContent(credFiles[0].relativePath, 'utf-16')
var leak int = garbled  // Leaks to stderr immediately
output x string = 'x'
output garbledContent int = garbled

// // Also try reading as UTF-16BE (big endian)
// var garbled2 = loadTextContent(credFiles[0].relativePath, 'utf-16BE')
// output garbledBE string = garbled2


