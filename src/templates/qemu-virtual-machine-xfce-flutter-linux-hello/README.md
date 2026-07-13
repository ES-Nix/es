# qemu-virtual-machine-xfce-flutter-linux-hello

Flutter Linux desktop app built with `buildFlutterApplication` (nixpkgs), runs in a QEMU VM with XFCE desktop, accessible via SPICE.

**Why this approach:** `flutter build linux` produces a native GTK binary. Nixpkgs's `buildFlutterApplication` with `targetFlutterPlatform = "linux"` fetches all pub dependencies as fixed-output derivations and links the required GTK/libepoxy/libGL libraries at build time. The result is a standalone binary that runs in any NixOS environment.

**Why no Docker/OCI image here:** Flutter Linux produces a GTK application, not a server. Running it requires a display server (X11/Wayland). The QEMU VM with XFCE is the natural environment — use `nix run .#automaticVm` to open the desktop.

**Test strategy:** The automated NixOS test runs the app headless under `xvfb-run` and checks the process appears in `ps`. Interactive use is via SPICE remote-viewer.

## Outputs

| Command | What it does |
|---|---|
| `nix build .#` | Build Flutter Linux binary |
| `nix build .#myvm` | Build QEMU VM disk image |
| `nix run .#automaticVm` | Launch VM with XFCE via SPICE |
| `nix run .#` | Run the Flutter Linux app (needs display) |
| `nix run .#allTests` | Run full test suite |

## Usage

```bash
# Interactive VM (opens remote-viewer)
nix run .#automaticVm

# Inside the VM: open terminal and run
flutter-linux-hello

# Automated headless test
nix flake check .#
```

## Development

```bash
nix develop    # Shell with flutter + dart + GTK libs
flutter pub get
flutter run -d linux
flutter build linux
```

## What `nix flake check` does

Builds the Flutter Linux binary, boots a headless NixOS VM with xvfb, launches the app, and verifies the process exists in `ps aux`. Visual testing requires the interactive VM via `nix run .#automaticVm`.
