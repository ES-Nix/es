{
  description = "Application packaged using poetry2nix";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    (
      let
        # nix flake show --allow-import-from-derivation --impure --refresh .#
        suportedSystems = [
          "x86_64-linux"
          "aarch64-linux"
          # "aarch64-darwin"
          # "x86_64-darwin"
        ];

      in
      flake-utils.lib.eachSystem suportedSystems (system:
        let
          # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
          pkgs = nixpkgs.legacyPackages.${system};
          nixos-lib = import (nixpkgs + "/nixos/lib") { };
          inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
        in
        {
          packages = {
            myapp = mkPoetryApplication { projectDir = ./.; };
            default = self.packages.${system}.myapp;

            myappOCIImage =
              let

                nonRootShadowSetup = { user, uid, group, gid }: with pkgs; [
                  (writeTextDir "etc/shadow" ''${user}:!:::::::'')
                  (writeTextDir "etc/group" ''${group}:x:${toString gid}:'')
                  (writeTextDir "etc/gshadow" ''${group}:x::'')
                  (writeTextDir "etc/passwd" ''
                    ${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}
                  '')
                ];

                troubleshootPackages = with pkgs; [
                  # https://askubuntu.com/questions/16700/how-can-i-change-my-own-user-id#comment749398_167400
                  # https://unix.stackexchange.com/a/693915
                  acl

                  file
                  findutils
                  # gzip
                  hello
                  btop
                  iproute
                  nettools # why the story name is with an -?
                  nano
                  netcat
                  ripgrep
                  patchelf
                  binutils
                  mount
                  # bpftrace
                  strace
                  uftrace
                  # gnutar
                  wget
                  which
                ];

              in
              pkgs.dockerTools.buildLayeredImage {
                name = "myapp-oci-image";
                tag = "0.0.1";
                contents = [
                  self.packages.${system}.myapp
                  # pkgs.bashInteractive
                  # pkgs.coreutils
                  pkgs.busybox
                ]
                ++
                (nonRootShadowSetup { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; })
                  # ++
                  # troubleshootPackages
                ;

                config = {
                  # TODO: use builtins.getTOML to get the command!
                  Cmd = [ "start" ];
                  # Cmd = [ "${pkgs.bashInteractive}/bin/bash" ];
                  # Entrypoint = [ entrypoint ];
                  # Entrypoint = [ "${pkgs.bashInteractive}/bin/bash" ];

                  Env = with pkgs; [
                    # "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bunle.crt"
                    # TODO: it needs a big refactor
                    # "PATH=/root/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin"
                    # "MANPATH=/root/.nix-profile/share/man:/home/nixuser/.nix-profile/share/man:/run/current-system/sw/share/man"
                    # "NIX_PAGER=cat" # TODO: document it
                    # "NIX_PATH=nixpkgs=${nixFlakes}"
                    # "NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
                    # "ENV=/etc/profile"
                    # "GIT_SSL_CAINFO=${cacert}/etc/ssl/certs/ca-bunle.crt"
                    # "USER=root"
                    # "HOME=/root"
                  ];
                };
              };
          };

          formatter = pkgs.nixpkgs-fmt;

          apps = {
            default = {
              program = "${self.packages.${system}.default}/bin/start";
              type = "app";
            };
          };

          checks = {
            test-nixos = nixos-lib.runTest {
              name = "myapp-as-oci-image";
              nodes.machine =
                { config, pkgs, lib, ... }:
                {
                  config.virtualisation.docker.enable = true;
                  config.virtualisation.podman.enable = true;
                };
              testScript = ''
                start_all()

                machine.succeed("docker load < ${self.packages.${system}.myappOCIImage}")
                machine.succeed("podman load < ${self.packages.${system}.myappOCIImage}")

                machine.succeed("docker run --rm myapp-oci-image:0.0.1 | grep -q 'Hello poetry2nix!'")
                machine.succeed("podman run --rm localhost/myapp-oci-image:0.0.1 | grep -q 'Hello poetry2nix!'")
              '';
              hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
            };
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.myapp ];
            packages = [
              pkgs.poetry

              (pkgs.writeScriptBin "load-into-podman" ''
                podman load < ${self.packages.${system}.myappOCIImage}
              '')
              (pkgs.writeScriptBin "load-into-docker" ''
                docker load < ${self.packages.${system}.myappOCIImage}
              '')
              (pkgs.writeScriptBin "run-myapp-podman" ''
                podman run --rm localhost/myapp-oci-image:0.0.1
              '')
              (pkgs.writeScriptBin "run-myapp-podman" ''
                docker run --rm localhost/myapp-oci-image:0.0.1
              '')
            ];
          };
        })
    );
}
