{
  description = "Example: Python 3.12 OCI image via dockerTools (replaces Containerfile)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python312OciImage = pkgs.dockerTools.buildLayeredImage {
          name = "python312";
          tag = "latest";
          contents = [ pkgs.python312 pkgs.busybox ];
          config = {
            Entrypoint = [ "${pkgs.python312}/bin/python3" ];
            Cmd = [ "-c" "import this" ];
          };
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
          default = python312OciImage;
          inherit allTests;
        };
        apps.allTests = {
          type = "app";
          program = "${pkgs.lib.getExe allTests}";
          meta.description = "Run all tests";
        };
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
