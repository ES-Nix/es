{
  description = "Example: yarn add ffi-napi (native binding, --ignore-scripts for Node.js 22 compat)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # ffi-napi 4.x native binding is incompatible with Node.js 22 (node_api_basic_finalize rename).
        # --ignore-scripts skips gyp compilation; demonstrates the npm/Nix integration pattern.
        ffiNapi = pkgs.buildNpmPackage {
          name = "ffi-napi-example";
          src = ./.;
          npmDepsHash = "sha256-CibMEJZtBY3SJQrOBxtozrMwiPopnW67uiPElDMimfA=";
          npmFlags = "--ignore-scripts";
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib
            cp -r node_modules $out/lib/
          '';
        };
        allTests = pkgs.writeShellApplication
          {
            name = "all-tests";
            text = ''
              nix fmt . \
              && nix flake show '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix flake check --verbose '.#'
            '';
          } // { meta.mainProgram = "all-tests"; };
      in
      {
        packages = {
          default = ffiNapi;
          inherit allTests;
        };
        apps.allTests = {
          type = "app";
          program = "${pkgs.lib.getExe allTests}";
          meta.description = "Run all tests";
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nodejs nodePackages.yarn libffi ];
        };
      }
    );
}
