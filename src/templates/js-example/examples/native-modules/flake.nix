{
  description = "Example: yarn add sqlite3 argon2 sharp node-sass (native npm modules)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nativeModules = pkgs.buildNpmPackage {
          name = "native-modules-example";
          src = ./.;
          npmDepsHash = "sha256-ciCAI91zpEODnaNLXadU8Ci+pZ5EwZ897dl9ir34MDY=";
          nativeBuildInputs = with pkgs; [
            (python3.withPackages (ps: [ ps.setuptools ]))
            pkg-config
            nodePackages.node-gyp
            vips
            libsass
          ];
          buildInputs = with pkgs; [
            sqlite
            libsass
            vips
          ];
          env.CXXFLAGS = "-std=c++17";
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib
            cp -r node_modules $out/lib/
          '';
        };
        allTests = pkgs.writeShellApplication {
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
          default = nativeModules;
          inherit allTests;
        };
        apps.allTests = {
          type = "app";
          program = "${pkgs.lib.getExe allTests}";
          meta.description = "Run all tests";
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nodejs nodePackages.yarn python3 pkg-config vips ];
        };
      }
    );
}
