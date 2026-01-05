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

# Create Program.cs with hello-world extension + HTTP call support
cat > Program.cs << 'CSHARP'
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Bicep.Local.Extension.Host.Extensions;
using Bicep.Local.Extension.Host.Handlers;
using Bicep.Local.Extension.Types.Attributes;
using Azure.Bicep.Types.Concrete;
using System.Net.Http;

var builder = WebApplication.CreateBuilder();

builder.AddBicepExtensionHost(args);
builder.Services
    .AddBicepExtension(
        name: "HelloWorld",
        version: "1.0.2",
        isSingleton: true,
        typeAssembly: typeof(Program).Assembly)
    .WithResourceHandler<GreetingHandler>()
    .WithResourceHandler<HttpCallHandler>();

var app = builder.Build();

app.MapBicepExtension();

await app.RunAsync();

// ============ Greeting Resource ============

public class GreetingIdentifiers
{
    [TypeProperty("The greeting name", ObjectTypePropertyFlags.Identifier | ObjectTypePropertyFlags.Required)]
    public required string Name { get; set; }
}

[ResourceType("Greeting")]
public class Greeting : GreetingIdentifiers
{
    [TypeProperty("The greeting message output", ObjectTypePropertyFlags.ReadOnly)]
    public string? Message { get; set; }
}

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

// ============ HttpCall Resource ============

public class HttpHeader
{
    [TypeProperty("Header name", ObjectTypePropertyFlags.Required)]
    public required string Name { get; set; }

    [TypeProperty("Header value", ObjectTypePropertyFlags.Required)]
    public required string Value { get; set; }
}

public class HttpCallIdentifiers
{
    [TypeProperty("The HTTP call name", ObjectTypePropertyFlags.Identifier | ObjectTypePropertyFlags.Required)]
    public required string Name { get; set; }
}

[ResourceType("HttpCall")]
public class HttpCall : HttpCallIdentifiers
{
    [TypeProperty("The URL to call", ObjectTypePropertyFlags.Required)]
    public required string Url { get; set; }

    [TypeProperty("The HTTP method (GET, POST, PUT, DELETE, PATCH)", ObjectTypePropertyFlags.Required)]
    public required string Method { get; set; }

    [TypeProperty("The request body")]
    public string? Body { get; set; }

    [TypeProperty("The request headers")]
    public HttpHeader[]? Headers { get; set; }

    [TypeProperty("The response body", ObjectTypePropertyFlags.ReadOnly)]
    public string? Result { get; set; }

    [TypeProperty("The HTTP status code", ObjectTypePropertyFlags.ReadOnly)]
    public int StatusCode { get; set; }
}

public class HttpCallHandler : TypedResourceHandler<HttpCall, HttpCallIdentifiers>
{
    protected override Task<ResourceResponse> Preview(ResourceRequest request, CancellationToken cancellationToken)
    {
        request.Properties.Result = "(preview)";
        request.Properties.StatusCode = 0;
        return Task.FromResult(GetResponse(request));
    }

    protected override async Task<ResourceResponse> CreateOrUpdate(ResourceRequest request, CancellationToken cancellationToken)
    {
        using var client = new HttpClient();

        var method = request.Properties.Method.ToUpperInvariant() switch
        {
            "GET" => System.Net.Http.HttpMethod.Get,
            "POST" => System.Net.Http.HttpMethod.Post,
            "PUT" => System.Net.Http.HttpMethod.Put,
            "DELETE" => System.Net.Http.HttpMethod.Delete,
            "PATCH" => System.Net.Http.HttpMethod.Patch,
            _ => throw new InvalidOperationException($"Unsupported method: {request.Properties.Method}")
        };

        var httpRequest = new HttpRequestMessage(method, request.Properties.Url);

        if (request.Properties.Body != null)
        {
            httpRequest.Content = new StringContent(request.Properties.Body);
        }

        if (request.Properties.Headers != null)
        {
            foreach (var header in request.Properties.Headers)
            {
                if (header.Name.Equals("Content-Type", StringComparison.OrdinalIgnoreCase) && httpRequest.Content != null)
                {
                    httpRequest.Content.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(header.Value);
                }
                else
                {
                    httpRequest.Headers.TryAddWithoutValidation(header.Name, header.Value);
                }
            }
        }

        var response = await client.SendAsync(httpRequest, cancellationToken);
        request.Properties.StatusCode = (int)response.StatusCode;
        request.Properties.Result = await response.Content.ReadAsStringAsync(cancellationToken);

        return GetResponse(request);
    }

    protected override HttpCallIdentifiers GetIdentifiers(HttpCall properties)
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

resource notify 'HttpCall' = {
  name: 'testCall'
  url: 'https://lamian.robertprast.com'
  method: 'POST'
  body: '{"message": "hello from bicep!", "source": "HelloWorld extension"}'
  headers: [
    { name: 'Content-Type', value: 'application/json' }
  ]
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
