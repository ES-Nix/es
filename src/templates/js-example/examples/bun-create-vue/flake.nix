{
  description = "Example: bun create vue (interactive scaffold)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        bunCreateVue = pkgs.writeShellApplication {
          name = "bun-create-vue";
          runtimeInputs = [ pkgs.bun ];
          text = ''
            echo "Scaffolding Vue.js project with bun..."
            echo "Commands:"
            echo "  bun create vue@latest"
            echo "  bun create vue@latest -- --template vue"
            echo "  bun create vue@latest -- --template vue-ts"
            bun create vue@latest "$@"
          '';
        };
      in
      {
        packages.default = bunCreateVue;
        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe bunCreateVue}";
          meta.description = "Interactive: bun create vue scaffold";
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.bun pkgs.nodejs ];
          shellHook = ''
            echo "bun $(bun --version) ready"
            echo "Run: bun create vue@latest my-app"
          '';
        };
      }
    );
}
