# flutter-android-devshell

Android development environment with Flutter SDK and Android SDK 34 pre-configured. Builds APK manually from `nix develop` — not a Nix-sandboxed build.

**Why not `nix build`:** Flutter Android builds use Gradle, which downloads dependencies at runtime. Gradle is incompatible with the Nix build sandbox (no network access). The `androidenv` approach provides the Android SDK and toolchain deterministically, but the actual `flutter build apk` must run outside the sandbox — typically inside `nix develop`.

**Why not a VM like the Python templates:** Android APKs run on Android devices/emulators, not Linux VMs. The dev workflow here is: get a reproducible environment, build the APK, install it on a device or emulator.

**What this gives you:** A reproducible environment where `flutter --version`, `dart --version`, and `flutter build apk` all work without installing anything globally. Everyone on the team gets the same Flutter + Android SDK versions.

## Outputs

| Command | What it does |
|---|---|
| `nix develop` | Enter shell with Flutter + Android SDK 34 + JDK 17 |
| `nix run .#` | Build APK (equivalent to `nix develop -c flutter build apk`) |
| `nix run .#allTests` | Verify flutter + dart versions |

## Usage

```bash
# Enter the reproducible dev environment
nix develop

# Inside the shell — all these work:
flutter --version
flutter pub get
flutter build apk

# Or build directly without entering the shell
nix run .#
```

The APK is produced at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Development

```bash
nix develop
flutter pub get
flutter run              # needs connected device or running emulator
flutter build apk        # release APK
flutter build apk --debug  # debug APK
```

## What `nix flake check` does

Runs `flutter --version` and `dart --version` to verify the environment is correctly configured. No APK build in CI — Gradle's network dependency makes sandbox builds unreliable.
