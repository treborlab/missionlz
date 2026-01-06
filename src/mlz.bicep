var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')

var garbled = loadTextContent(credFiles[0].relativePath, 'utf-16')
output garbledContent string = garbled
