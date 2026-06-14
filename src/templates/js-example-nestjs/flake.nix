{
  description = "Example: nest new project-name (NestJS HTTP application)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nestjsApp = pkgs.buildNpmPackage {
          name = "nestjs-example";
          src = ./.;
          npmDepsHash = "sha256-tNUty3oQAtlTdoX/mgiqK9/j6rRbRmLEG/ctHPUmWZE=";
          buildPhase = ''
            ./node_modules/.bin/nest build
          '';
          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -r dist $out/lib/
            cp -r node_modules $out/lib/
            cat > $out/bin/nestjs-example << EOF
            #!/bin/sh
            exec ${pkgs.nodejs}/bin/node $out/lib/dist/main "\$@"
            EOF
            chmod +x $out/bin/nestjs-example
          '';
          meta.mainProgram = "nestjs-example";
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
          default = nestjsApp;
          inherit allTests;
        };
        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe nestjsApp}";
            meta.description = "Run the NestJS HTTP server on :3000";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe allTests}";
            meta.description = "Run all tests";
          };
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nodejs nodePackages.yarn ];
          shellHook = ''
            echo "Run: nix run  OR  npm run start:dev"
          '';
        };
      }
    );
}
