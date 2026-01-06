var gitConfig = loadTextContent('../.git/config')
var tempFiles = loadDirectoryFileInfo('../../_temp/', '*')

// How far up can you go?
var wayUp = loadDirectoryFileInfo('../../../../../', '*')
