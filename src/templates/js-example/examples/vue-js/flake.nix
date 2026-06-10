{
  description = "Example: Vite + Vue.js (JavaScript)";

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
          name = "vue-js";
          src = ./.;
          npmDepsHash = "sha256-f4zQb9bUWWgLNotv9RXnGy2+/D3drAq03+0Kc4rNAiE=";
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
