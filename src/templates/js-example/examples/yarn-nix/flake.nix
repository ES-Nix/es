{
  description = "Example: TypeScript + Lodash via mkYarnPackage (yarn-nix integration)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        yarnNixNodeModules = pkgs.mkYarnPackage {
          name = "yarn-nix-node-modules";
          src = ./.;
        };
        yarnNixFrontend = pkgs.stdenv.mkDerivation {
          name = "yarn-nix-frontend";
          src = ./.;
          nativeBuildInputs = with pkgs; [ yarnNixNodeModules nodejs nodePackages.typescript ];
          buildPhase = ''
            ln -s ${yarnNixNodeModules}/libexec/yarn-nix-example/node_modules node_modules
            tsc --project tsconfig.json
          '';
          installPhase = ''
            mkdir -p $out/lib $out/bin
            mv dist $out/lib/
            cat > $out/bin/wui << EOF
            #!/bin/sh
            exec ${pkgs.nodejs}/bin/node $out/lib/dist/wui.js "\$@"
            EOF
            chmod +x $out/bin/wui
          '';
          meta.mainProgram = "wui";
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
          default = yarnNixFrontend;
          nodeModules = yarnNixNodeModules;
          inherit allTests;
        };
        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe yarnNixFrontend}";
            meta.description = "Run the TypeScript wui example";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe allTests}";
            meta.description = "Run all tests";
          };
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nodejs nodePackages.yarn nodePackages.typescript ];
        };
      }
    );
}
