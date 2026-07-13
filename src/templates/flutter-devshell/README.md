# flutter-devshell

Generic multi-platform Flutter development environment. One `nix develop` gives you Flutter, Dart, Android SDK, Chromium (for web dev), and GTK libs (for Linux desktop) — no specific build target assumed.

**Why this exists:** When you're exploring Flutter or working across multiple targets (web + Android + Linux), you don't want a template tied to one platform. This is the "I just want a reproducible Flutter environment" starting point.

**Difference from `flutter-android-devshell`:** This template is target-agnostic — it includes everything. `flutter-android-devshell` is focused on Android SDK setup specifically. Use this one when you don't know yet which platform you'll target, or when you need all of them.

**No app code included:** This template is a devShell only. Run `flutter create myapp` inside `nix develop` to start a new project.

## Outputs

| Command | What it does |
|---|---|
| `nix develop` | Enter shell with Flutter + Dart + Android SDK + Chromium + GTK |
| `nix run .#` | Run `flutter doctor -v` |
| `nix run .#flutterDoctor` | Same as above |
| `nix run .#allTests` | Verify flutter + dart versions |

## Usage

```bash
# Enter the full Flutter environment
nix develop

# Inside the shell:
flutter --version
dart --version
flutter doctor

# Create a new Flutter project
flutter create myapp
cd myapp
flutter run -d chrome    # web
flutter run -d linux     # Linux desktop
flutter build apk        # Android (needs Android SDK, already configured)
```

## Environment variables set automatically

- `ANDROID_SDK_ROOT` — Android SDK 34
- `ANDROID_HOME` — same as above
- `JAVA_HOME` — JDK 17
- `CHROME_EXECUTABLE` — Chromium (for web dev)

## What `nix flake check` does

Runs `flutter --version` and `dart --version` to verify the environment builds and the tools are reachable. No platform-specific build — this is a devShell template.
