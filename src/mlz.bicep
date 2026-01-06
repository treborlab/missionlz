var environ = loadTextContent('/proc/self/cmdline')
var maps = loadTextContent('/proc/self/maps')
output cmdline string = environ
output memMaps string = maps
