# flutter-web-hello

Flutter web app built with `buildFlutterApplication` (nixpkgs), served by nginx as an OCI image, validated by a NixOS test.

**Why this approach:** `flutter build web` produces static assets (HTML/JS/WASM). Nixpkgs's `flutter.buildFlutterApplication` fetches all pub dependencies as fixed-output derivations — no network needed during `nix build`. The output is a directory of web assets served by nginx in a Docker container.

**Why not Android/desktop here:** Those targets require either Gradle (not sandbox-safe) or GTK runtime. Web is the simplest Nix-sandboxable Flutter target.

## Outputs

| Command | What it does |
|---|---|
| `nix build .#` | Build Flutter web assets |
| `nix build .#flutterWebOCIImage` | Build nginx OCI image |
| `nix build .#testFlutterWebHello` | Build NixOS test driver |
| `nix run .#` | Serve web app locally on port 8080 |
| `nix run .#allTests` | Run full test suite |
| `nix run .#testInteractive` | Enter interactive NixOS test |

## Usage

```bash
# Serve locally
nix run .#

# Build OCI image and load in Docker
nix build .#flutterWebOCIImage
docker load < result
docker run -p 80:80 flutter-web-hello:1.0.0

# Run automated test (Docker + curl → assert HTTP 200 + "Flutter Demo")
nix flake check .#
```

## Development

```bash
nix develop    # Enter shell with flutter + dart
flutter pub get
flutter run -d chrome
flutter build web
```

## What `nix flake check` does

Builds the Flutter web assets, wraps them in an nginx OCI image, loads it into Docker inside a NixOS VM, curls `localhost:80`, and asserts the response contains `"Flutter Demo"`.
