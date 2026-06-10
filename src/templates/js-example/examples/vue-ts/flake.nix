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
      in
      {
        packages.default = pkgs.buildNpmPackage {
          name = "vue-ts";
          src = ./.;
          npmDepsHash = "sha256-ov9jZrGmftWAlcMsqD749b5Z2sYp88qOoBFcDmHRW+U=";
          buildPhase = "npm run build";
          installPhase = ''
            mkdir -p $out/lib
            mv dist $out/lib/
          '';
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
