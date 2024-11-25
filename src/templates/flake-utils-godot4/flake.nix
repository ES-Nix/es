{
  description = " ";
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixgl.url = "github:guibou/nixGL";
    nixgl.inputs.nixpkgs.follows = "nixpkgs";
    nixgl.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, nixgl, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

    in
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        foo-bar = prev.hello;
      };
    } //
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs {
            overlays = [ self.overlays.default ];
            system = suportedSystem;
            config.allowUnfreePredicate = (_: true);
            config.android_sdk.accept_license = true;
            config.allowUnfree = true;
            config.cudaSupport = true;
          };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          packages.default = self.devShells."${suportedSystem}".default;
          devShells.default = pkgsAllowUnfree.mkShell.override { stdenv = pkgsAllowUnfree.clangStdenv; } {
            buildInputs = with pkgsAllowUnfree; [
              # Rust related dependencies
              rustc
              cargo
              rustfmt
              libclang

              # Godot Engine Editor
              godot_4

              # The support for OpenGL in Nix
              nixgl.defaultPackage."${suportedSystem}".nixGLDefault
            ];

            FONTCONFIG_FILE = "${pkgsAllowUnfree.fontconfig.out}/etc/fonts/fonts.conf";
            FONTCONFIG_PATH = "${pkgsAllowUnfree.fontconfig.out}/etc/fonts/";

            # Point bindgen to where the clang library would be
            LIBCLANG_PATH = "${pkgsAllowUnfree.libclang.lib}/lib";
            # Make clang aware of a few headers (stdbool.h, wchar.h)
            BINDGEN_EXTRA_CLANG_ARGS = with pkgsAllowUnfree; ''
              -isystem ${llvmPackages.libclang.lib}/lib/clang/${lib.getVersion clang}/include
              -isystem ${llvmPackages.libclang.out}/lib/clang/${lib.getVersion clang}/include
              -isystem ${glibc.dev}/include
            '';

            # For Rust language server and rust-analyzer
            RUST_SRC_PATH = "${pkgsAllowUnfree.rust.packages.stable.rustPlatform.rustLibSrc}";

            shellHook = ''
              export TMPDIR=/tmp

              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build --impure $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default

              alias godot="nixGL godot4 --rendering-driver opengl3"
            '';
          };
        }
      )

    // {
      #
    };
}
