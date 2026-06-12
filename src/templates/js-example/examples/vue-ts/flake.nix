{
  description = "Example: Vite + Vue.js (TypeScript)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        vueTs = pkgs.buildNpmPackage {
          name = "vue-ts";
          src = ./.;
          npmDepsHash = "sha256-ov9jZrGmftWAlcMsqD749b5Z2sYp88qOoBFcDmHRW+U=";
          buildPhase = "npm run build";
          installPhase = ''
            mkdir -p $out/lib
            mv dist $out/lib/
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
          default = vueTs;
          inherit allTests;
        };
        apps.allTests = {
          type = "app";
          program = "${pkgs.lib.getExe allTests}";
          meta.description = "Run all tests";
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nodejs pkgs.bun ];
          shellHook = ''
            echo "Run: npm run dev  OR  nix build"
          '';
        };
      }
    );
}
