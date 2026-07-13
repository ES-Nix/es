{
  description = "Flutter Android development environment — androidenv (SDK 34) + Flutter + JDK 17";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; android_sdk.accept_license = true; }; };

        androidSdk = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "34.0.0" ];
          platformVersions = [ "34" ];
          abiVersions = [ "x86_64" "armeabi-v7a" "arm64-v8a" ];
          includeNDK = false;
          includeEmulator = false;
          includeSources = false;
        };

        buildApkScript = pkgs.writeShellApplication {
          name = "build-apk";
          runtimeInputs = [ pkgs.flutter pkgs.jdk17 androidSdk.androidsdk ];
          text = ''
            export ANDROID_SDK_ROOT="${androidSdk.androidsdk}/libexec/android-sdk"
            export ANDROID_HOME="$ANDROID_SDK_ROOT"
            export JAVA_HOME="${pkgs.jdk17}"
            flutter build apk "$@"
            echo "APK built: build/app/outputs/flutter-apk/app-release.apk"
          '';
        };

        allTests =
          let name = "all-tests";
          in pkgs.writeShellApplication
            {
              name = name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show --all-systems '.#' \
                && nix flake metadata '.#' \
                && nix develop '.#' --command sh -c 'flutter --version && dart --version'
              '';
            } // { meta.mainProgram = name; };

        versionCheck = pkgs.runCommand "flutter-version-check"
          {
            nativeBuildInputs = with pkgs; [ flutter dart writableTmpDirAsHomeHook ];
          } ''
          flutter --version > "$out"
          dart --version >> "$out"
        '';
      in
      {
        packages = {
          inherit buildApkScript allTests;
          default = buildApkScript;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe buildApkScript}";
            meta.description = "Build Flutter Android APK (run from a Flutter project dir)";
          };
          buildApk = {
            type = "app";
            program = "${pkgs.lib.getExe buildApkScript}";
            meta.description = "Build Flutter Android APK (run from a Flutter project dir)";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe allTests}";
            meta.description = "Run all tests";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit versionCheck;
          default = versionCheck;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            flutter
            dart
            jdk17
            androidSdk.androidsdk
          ];
          shellHook = ''
            export ANDROID_SDK_ROOT="${androidSdk.androidsdk}/libexec/android-sdk"
            export ANDROID_HOME="$ANDROID_SDK_ROOT"
            export JAVA_HOME="${pkgs.jdk17}"
            export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"

            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true
          '';
        };
      }
    );
}
