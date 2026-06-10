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
      in
      {
        # ffi-napi 4.x native binding is incompatible with Node.js 22 (node_api_basic_finalize rename).
        # --ignore-scripts skips gyp compilation; demonstrates the npm/Nix integration pattern.
        packages.default = pkgs.buildNpmPackage {
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
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nodejs nodePackages.yarn libffi ];
        };
      }
    );
}
