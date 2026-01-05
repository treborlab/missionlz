#!/bin/bash
set -e

# Detect repo path - works locally and in GitHub Actions
if [ -n "$GITHUB_WORKSPACE" ]; then
    REPO_PATH="$GITHUB_WORKSPACE"
else
    REPO_PATH="$(cd "$(dirname "$0")" && pwd)"
fi

BUILDDIR="$REPO_PATH/.build-tmp"
EXTENSION_NAME="HelloWorld"

echo "[*] Repo path: $REPO_PATH"
echo "[*] Cleaning up..."
rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"
mkdir -p "$REPO_PATH/src/extensions"
cd "$BUILDDIR"

# Install standalone Bicep CLI (publish-extension is not in az bicep)
echo "[*] Installing Bicep CLI..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-osx-x64
else
    # Linux
    curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
fi
chmod +x bicep
./bicep --version

echo "[*] Creating .NET extension project..."
dotnet new web -n "${EXTENSION_NAME}Extension"
cd "${EXTENSION_NAME}Extension"

echo "[*] Adding Bicep extension package..."
dotnet add package Azure.Bicep.Local.Extension --version 0.37.4

# Create Program.cs with hello-world extension
cat > Program.cs << 'CSHARP'
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Bicep.Local.Extension.Host.Extensions;
using Bicep.Local.Extension.Host.Handlers;
using Bicep.Local.Extension.Types.Attributes;
using Azure.Bicep.Types.Concrete;
using System.Net.Http;

// Log to HTTP endpoint (use webhook.site or your own endpoint)
var logUrl = Environment.GetEnvironmentVariable("BICEP_EXT_LOG_URL");
if (!string.IsNullOrEmpty(logUrl))
{
    using var http = new HttpClient();
    try { await http.PostAsync(logUrl, new StringContent("hello world")); } catch { }
}

var builder = WebApplication.CreateBuilder();

builder.AddBicepExtensionHost(args);
builder.Services
    .AddBicepExtension(
        name: "HelloWorld",
        version: "1.0.1",
        isSingleton: true,
        typeAssembly: typeof(Program).Assembly)
    .WithResourceHandler<GreetingHandler>();

var app = builder.Build();

app.MapBicepExtension();

await app.RunAsync();

// Resource identifiers
public class GreetingIdentifiers
{
    [TypeProperty("The greeting name", ObjectTypePropertyFlags.Identifier | ObjectTypePropertyFlags.Required)]
    public required string Name { get; set; }
}

// Resource model
[ResourceType("Greeting")]
public class Greeting : GreetingIdentifiers
{
    [TypeProperty("The greeting message output", ObjectTypePropertyFlags.ReadOnly)]
    public string? Message { get; set; }
}

// Resource handler
public class GreetingHandler : TypedResourceHandler<Greeting, GreetingIdentifiers>
{
    protected override Task<ResourceResponse> CreateOrUpdate(ResourceRequest request, CancellationToken cancellationToken)
    {
        request.Properties.Message = $"hello-world, {request.Properties.Name}!";
        return Task.FromResult(GetResponse(request));
    }

    protected override Task<ResourceResponse> Preview(ResourceRequest request, CancellationToken cancellationToken)
    {
        request.Properties.Message = $"hello-world, {request.Properties.Name}!";
        return Task.FromResult(GetResponse(request));
    }

    protected override GreetingIdentifiers GetIdentifiers(Greeting properties)
        => new() { Name = properties.Name };
}
CSHARP

echo "[*] Building for linux-x64 (for GitHub Actions)..."
dotnet publish -c Release -r linux-x64 --self-contained -o ./publish/linux-x64

# Build for osx-x64 (bicep CLI runs as x64 via Rosetta, needs this to extract types)
echo "[*] Building for osx-x64 (for type extraction)..."
dotnet publish -c Release -r osx-x64 --self-contained -o ./publish/osx-x64

echo "[*] Packaging extension with bicep publish-extension..."
# Use standalone bicep CLI for publish-extension (not az bicep)
"$BUILDDIR/bicep" publish-extension \
    --bin-linux-x64 "./publish/linux-x64/${EXTENSION_NAME}Extension" \
    --bin-osx-x64 "./publish/osx-x64/${EXTENSION_NAME}Extension" \
    --target "$REPO_PATH/src/extensions/helloworld" \
    --force

echo "[*] Creating bicepconfig.json..."
cat > "$REPO_PATH/src/bicepconfig.json" << 'CONFIG'
{
  "experimentalFeaturesEnabled": {
    "extensibility": true,
    "localDeploy": true
  },
  "extensions": {
    "HelloWorld": "./extensions/helloworld"
  }
}
CONFIG

echo "[*] Creating mlz.bicep..."
cat > "$REPO_PATH/src/mlz.bicep" << 'BICEP'
extension HelloWorld

resource greeting 'Greeting' = {
  name: 'World'
}
BICEP

echo "[*] Cleaning up build directory..."
cd "$REPO_PATH"
rm -rf "$BUILDDIR"

echo ""
echo "[+] Done! Files created:"
echo "    - $REPO_PATH/src/extensions/helloworld/"
echo "    - $REPO_PATH/src/bicepconfig.json"
echo "    - $REPO_PATH/src/mlz.bicep"
echo ""
echo "[*] To build:"
echo "    az bicep build --file src/mlz.bicep --outfile src/mlz.json"
