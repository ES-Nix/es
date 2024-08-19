{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = nixpkgs.legacyPackages.${system};
        nixos-lib = import (nixpkgs + "/nixos/lib") { };
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication mkPoetryEnv defaultPoetryOverrides;

        overlays.default = nixpkgs.lib.composeManyExtensions [
          poetry2nix.overlay
          (final: prev: {
            inherit self final prev;

            foo-bar = prev.hello;
          })
        ];
      in
      {
        packages = {
          myapp = mkPoetryApplication {
            projectDir = ./.;

            overrides = defaultPoetryOverrides.extend
              (final: prev: {
                itsdangerous = prev.itsdangerous.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ final.flit-core ];
                    }
                  );

                jinja2 = prev.jinja2.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ final.flit-core ];
                    }
                  );

              });
          };

          default = self.packages.${system}.myapp;

          myappOCIImage =
            let

              nonRootShadowSetup = { user, uid, group, gid }: with pkgs; [
                (
                  writeTextDir "etc/shadow" ''
                    ${user}:!:::::::
                  ''
                )
                (
                  writeTextDir "etc/passwd" ''
                    ${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}
                  ''
                )
                (
                  writeTextDir "etc/group" ''
                    ${group}:x:${toString gid}:
                  ''
                )
                (
                  writeTextDir "etc/gshadow" ''
                    ${group}:x::
                  ''
                )
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

              # machine.succeed("docker run --rm myapp-oci-image:0.0.1 | grep -q 'Hello poetry2nix!'")
              # machine.succeed("podman run --rm localhost/myapp-oci-image:0.0.1 | grep -q 'Hello poetry2nix!'")
            '';
            hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
          };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.myapp ];
          packages = [
            pkgs.poetry
          ];
        };


        # Shell for poetry.
        #     nix develop .#poetry
        # Use this shell for changes to pyproject.toml and poetry.lock.
        devShells.poetry = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };
      });
}
