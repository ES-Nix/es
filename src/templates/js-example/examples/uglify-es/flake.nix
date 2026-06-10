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
      in
      {
        packages.default = uglifyEsExample;
        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe uglifyEsExample}";
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nodejs ];
        };
      }
    );
}
