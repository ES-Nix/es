{
  description = "Example: npm install uglify-es";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        uglifyEsExample = pkgs.buildNpmPackage {
          name = "uglify-es-example";
          src = ./.;
          npmDepsHash = "sha256-PlQbbYQdN7SH3pPVras84sNLHIXMS0zR4K08Hz5OgGw=";
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -r node_modules $out/lib/
            cat > $out/bin/uglifyjs << EOF
            #!/bin/sh
            exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/uglify-es/bin/uglifyjs "\$@"
            EOF
            chmod +x $out/bin/uglifyjs
          '';
          meta.mainProgram = "uglifyjs";
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
          default = uglifyEsExample;
          inherit allTests;
        };
        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe uglifyEsExample}";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe allTests}";
            meta.description = "Run all tests";
          };
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nodejs ];
        };
      }
    );
}
