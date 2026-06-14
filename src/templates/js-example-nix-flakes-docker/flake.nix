{
  description = "Example: run docker.nix-community.org/nixpkgs/nix-flakes bash shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # docker must be available in PATH at runtime
        nixFlakesDockerShell = pkgs.writeShellApplication {
          name = "nix-flakes-docker-shell";
          runtimeInputs = [ ];
          text = ''
            docker \
              run \
              --env=PATH=/root/.nix-profile/bin:/usr/bin:/bin \
              --privileged=true \
              --device=/dev/fuse \
              --env="DISPLAY=''${DISPLAY:-:0.0}" \
              --interactive=true \
              --network=host \
              --mount=type=tmpfs,destination=/var/lib/containers \
              --tty=true \
              --rm=true \
              --user=0 \
              --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
              --volume=/etc/localtime:/etc/localtime:ro \
              --volume=/dev:/dev \
              docker.nix-community.org/nixpkgs/nix-flakes \
              bash \
              -c \
              "''${*:-id}"
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
          default = nixFlakesDockerShell;
          inherit allTests;
        };
        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe nixFlakesDockerShell}";
            meta.description = "Run nix-flakes Docker container (requires docker in PATH)";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe allTests}";
            meta.description = "Run all tests";
          };
        };
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
