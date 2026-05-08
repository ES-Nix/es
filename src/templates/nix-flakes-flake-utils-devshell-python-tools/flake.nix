{
  description = "It is an nix flake example of a devShell and uses flake-utils support multiple architectures";
  /*
    # github:NixOS/nixpkgs/nixos-25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'  
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, ... }:
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

        f00Bar = prev.hello;

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

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
            config.cudaSupport = false;
          };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          packages = {
            inherit (pkgsAllowUnfree)
              allTests
              f00Bar
              ;
            default = self.devShells.${suportedSystem}.default;
          };

          apps = {
            allTests = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.allTests}";
              meta.description = "Run all tests for this flake";
            };
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            packages = with pkgsAllowUnfree; [
              bashInteractive
              pleaseKeepMyInputs

              f00Bar

              python313

              # auditwheel
              binutils.out
              glibc.bin
              patchelf
              poetry
              python3Packages.pip
              python3Packages.wheel
              python3Packages.wheel-filename
              python3Packages.wheel-inspect
              twine
              uv
            ];

            shellHook = ''
              test -d .profiles || mkdir -v .profiles
              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true
            '';
          };

          checks = {
            inherit (pkgsAllowUnfree)
              f00Bar
              ;
            default = self.packages.${suportedSystem}.default;
          };
        }
      )

    // {
      #
    };
}
