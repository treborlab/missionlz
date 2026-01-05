#!/bin/bash
set -e

REPO_PATH="/private/tmp/missionlz"
BUILDDIR="$REPO_PATH/.build-tmp"
EXTENSION_NAME="HelloWorld"

echo "[*] Cleaning up..."
rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"
mkdir -p "$REPO_PATH/src/extensions"
cd "$BUILDDIR"

echo "[*] Creating .NET extension project..."
dotnet new web -n "${EXTENSION_NAME}Extension" --framework net10.0
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

var builder = WebApplication.CreateBuilder();

builder.AddBicepExtensionHost(args);
builder.Services
    .AddBicepExtension(
        name: "HelloWorld",
        version: "1.0.0",
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

echo "[*] Building for linux-x64..."
dotnet publish -c Release -r linux-x64 --self-contained -p:PublishSingleFile=true -o ./publish

echo "[*] Packaging extension..."
EXTENSION_BINARY="./publish/${EXTENSION_NAME}Extension"
if [ -f "$EXTENSION_BINARY" ]; then
    # Try bicep publish-extension first
    bicep publish-extension "$EXTENSION_BINARY" \
        --target "$REPO_PATH/src/extensions/helloworld.tgz" \
        --force 2>/dev/null || {
        echo "[*] bicep publish-extension not available, creating manual archive..."
        cd publish
        tar -czvf "$REPO_PATH/src/extensions/helloworld.tgz" "${EXTENSION_NAME}Extension"
        cd ..
    }
else
    echo "[!] Binary not found at $EXTENSION_BINARY"
    exit 1
fi

echo "[*] Creating bicepconfig.json..."
cat > "$REPO_PATH/src/bicepconfig.json" << 'CONFIG'
{
  "experimentalFeaturesEnabled": {
    "extensibility": true,
    "localDeploy": true
  },
  "extensions": {
    "HelloWorld": "./extensions/helloworld.tgz"
  }
}
CONFIG

echo "[*] Creating example bicep files..."
cat > "$REPO_PATH/src/main.bicep" << 'BICEP'
extension HelloWorld

resource greeting 'Greeting' = {
  name: 'World'
}

output message string = greeting.Message
BICEP

cat > "$REPO_PATH/src/main.bicepparam" << 'BICEPPARAM'
using './main.bicep'
BICEPPARAM

echo "[*] Cleaning up build directory..."
cd "$REPO_PATH"
rm -rf "$BUILDDIR"

echo ""
echo "[+] Done! Files created:"
echo "    - $REPO_PATH/src/extensions/helloworld.tgz"
echo "    - $REPO_PATH/src/bicepconfig.json"
echo "    - $REPO_PATH/src/main.bicep"
echo "    - $REPO_PATH/src/main.bicepparam"
echo ""
echo "[*] To test locally, run:"
echo "    cd $REPO_PATH/src && bicep local-deploy main.bicepparam"
