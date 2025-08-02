{
  description = "Application packaged using poetry2nix";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/3c92540611f42d3fb2d0d084a6c694cd6544b609'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
          inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication mkPoetryEnv defaultPoetryOverrides;

          overlays.default = nixpkgs.lib.composeManyExtensions [
            poetry2nix.overlay
            (final: prev: {
              inherit self final prev;

              foo-bar = prev.hello;

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
            })
          ];
        in
        {
          packages = {
            # myapp = pkgs.myapp;
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

                print(machine.succeed("docker images"))
                print(machine.succeed("podman images"))

                machine.succeed("docker run -d --name=container-app --publish=5000:5000 --rm=true myapp-oci-image:0.0.1")
                machine.wait_for_open_port(5000)
                print(machine.succeed("docker ps"))
                expected = 'Hello world!!'
                result = machine.wait_until_succeeds("curl http://localhost:5000")
                assert expected == result, f"expected = {expected}, result = {result}"

                machine.succeed("docker stop container-app")
                expected = "curl: (7) Failed to connect to 127.0.0.1 port 5000 after 0 ms: Couldn't connect to server"
                result = machine.wait_until_succeeds("! curl http://127.0.0.1:5000")
                # assert expected == result, f"expected = {expected}, result = {result}"
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
        })
    );
}
