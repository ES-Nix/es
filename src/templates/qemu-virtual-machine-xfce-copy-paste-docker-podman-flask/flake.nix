{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
    --override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }: {
    overlay = nixpkgs.lib.composeManyExtensions [
      poetry2nix.overlays.default
      (final: prev: {
        foo-bar = prev.hello;

        myapp = prev.poetry2nix.mkPoetryApplication {
          src = prev.poetry2nix.cleanPythonSources { src = ./.; };
          projectDir = ./.;

          overrides = prev.poetry2nix.defaultPoetryOverrides.extend
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


        myappOCIImage =
          let

            nonRootShadowSetup = { user, uid, group, gid }: with prev; [
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

            troubleshootPackages = with prev; [
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
          prev.dockerTools.buildLayeredImage {
            name = "myapp-oci-image";
            tag = "0.0.1";
            contents = [
              final.myapp # Execise: change it to prev.myapp
              # pkgs.bashInteractive
              # pkgs.coreutils
              prev.busybox
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

              Env = with prev; [
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


        nixos-vm = nixpkgs.lib.nixosSystem {
          # system = builtins.currentSystem;
          system = prev.system;
          # system = "x86_64-linux";

          modules = [
            ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
              {
                # Internationalisation options
                i18n.defaultLocale = "en_US.UTF-8";
                console.keyMap = "br-abnt2";

                # Set your time zone.
                time.timeZone = "America/Recife";

                # Why
                # nix flake show --impure .#
                # break if it does not exists?
                # Use systemd boot (EFI only)
                boot.loader.systemd-boot.enable = true;
                fileSystems."/" = { device = "/dev/hda1"; };

                virtualisation.vmVariant =
                  {
                    virtualisation.docker.enable = true;
                    virtualisation.podman.enable = true;

                    virtualisation.memorySize = 1024 * 9; # Use MiB memory.
                    virtualisation.diskSize = 1024 * 50; # Use MiB memory.
                    virtualisation.cores = 7; # Number of cores.
                    virtualisation.graphics = true;

                    virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                    virtualisation.qemu.options = [
                      # https://www.spice-space.org/spice-user-manual.html#Running_qemu_manually
                      # remote-viewer spice://localhost:3001

                      # "-daemonize" # How to save the QEMU PID?
                      "-machine vmport=off"
                      "-vga qxl"
                      "-spice port=3001,disable-ticketing=on"
                      "-device virtio-serial"
                      "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                      "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                    ];

                    virtualisation.useNixStoreImage = false; # TODO: hardening
                    virtualisation.writableStore = true; # TODO: hardening
                  };


                systemd.user.services.podman-custom-bootstrap-1 = {
                  description = "Podman Custom Bootstrap 1";
                  wantedBy = [ "default.target" ];
                  after = [ "podman.service" ];
                  path = with pkgs; [ "/run/wrappers" podman ];
                  script = ''
                    echo "Loading OCI Image in podman..."
                    podman load <"${pkgs.myappOCIImage}"
                  '';
                  serviceConfig = {
                    Type = "oneshot";
                  };
                };

                systemd.services.docker-custom-bootstrap-1 = {
                  description = "Docker Custom Bootstrap 1";
                  wantedBy = [ "multi-user.target" ];
                  after = [ "docker.service" ];
                  path = with pkgs; [ docker ];
                  script = ''
                    # set -x
                    echo "Loading OCI Image in docker..."
                    docker load <"${pkgs.myappOCIImage}"
                  '';
                  serviceConfig = {
                    Type = "oneshot";
                  };
                };


                security.sudo.wheelNeedsPassword = false; # TODO: hardening
                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;
                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1"; # TODO: hardening
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    file
                    firefox
                    jq
                    foo-bar
                    myapp
                  ];
                  shell = pkgs.bash;
                  uid = 1234;
                  autoSubUidGidRange = true;
                };

                services.xserver.enable = true;
                services.xserver.xkb.layout = "br";
                services.displayManager.autoLogin.user = "nixuser";

                # https://nixos.org/manual/nixos/stable/#sec-xfce
                services.xserver.desktopManager.xfce.enable = true;
                services.xserver.desktopManager.xfce.enableScreensaver = false;
                services.xserver.videoDrivers = [ "qxl" ];
                services.spice-vdagentd.enable = true; # For copy/paste to work

                nix.extraOptions = "experimental-features = nix-command flakes";

                environment.systemPackages = with pkgs; [
                  openssl
                  file
                ];

                system.stateVersion = "24.05";
              })

            { nixpkgs.overlays = [ self.overlay ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvm = final.nixos-vm.config.system.build.vm;

        automatic-vm = prev.writeShellApplication {
          name = "run-nixos-vm";
          runtimeInputs = with final; [ curl virt-viewer ];
          /*
              Pode ocorrer uma condição de corrida de seguinte forma:
              a VM inicializa (o processo não é bloqueante, executa em background)
              o spice/VNC interno a VM inicializa
              o remote-viewer tenta conectar, mas o spice não está pronto ainda

              TODO: idealmente não deveria ser preciso ter mais uma dependência (o curl)
                    para poder sincronizar o cliente e o server. Será que no caso de
                    ambos estarem na mesma máquina seria melhor usar virt-viewer -fw?
              https://unix.stackexchange.com/a/698488
            */
          text = ''

              # https://unix.stackexchange.com/a/230442
              # export NO_AT_BRIDGE=1
              # https://gist.github.com/eoli3n/93111f23dbb1233f2f00f460663f99e2#file-rootless-podman-wayland-sh-L25
              export LD_LIBRARY_PATH="${prev.libcanberra-gtk3}"/lib/gtk-3.0/modules

              ${final.myvm}/bin/run-nixos-vm & PID_QEMU="$!"

              export VNC_PORT=3001

              for _ in web{0..50}; do
                if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
                then
                  break
                fi
                # date +'%d/%m/%Y %H:%M:%S:%3N'
                sleep 0.2
              done;

              remote-viewer spice://localhost:"$VNC_PORT"

              kill $PID_QEMU
            '';
        };

      })
    ];
  } // (
    let
      # nix flake show --allow-import-from-derivation --impure --refresh .#
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

    in
    flake-utils.lib.eachSystem suportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
      in
      rec {
        packages = { inherit (pkgs) myapp myappOCIImage; };
        defaultPackage = pkgs.myapp;

        packages.myvm = pkgs.myvm;
        packages.automatic-vm = pkgs.automatic-vm;

        apps.default = {
          type = "app";
          program = "${pkgs.automatic-vm}/bin/run-nixos-vm";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          testMyappOCIImageDockerFirefoxOCR = pkgs.testers.runNixOSTest {
            name = "test-myapp-as-oci-image-docker-firefox-ocr";
            nodes.machineWithDockerFirefoxOCR =
              { config, pkgs, lib, ... }:
              {
                config.virtualisation.docker.enable = true;

                config.services.xserver.enable = true;
                # config.services.xserver.xkb.layout = "br";
                config.services.displayManager.autoLogin.user = "alice";
                # https://nixos.org/manual/nixos/stable/#sec-xfce
                config.services.xserver.desktopManager.xfce.enable = true;
                config.services.xserver.desktopManager.xfce.enableScreensaver = false;

                config.users.users.alice = {
                  isNormalUser = true;
                  extraGroups = [ "wheel" ];
                  packages = with pkgs; [
                    firefox
                  ];
                  uid = 1000;
                };
              };

            enableOCR = true;

            # Set the timeout to 160 seconds
            globalTimeout = 160;

            testScript = { nodes, ... }:
              let
                user = nodes.machineWithDockerFirefoxOCR.users.users.alice;

                su = command: "su - ${user.name} -c '${command}'";

                suId = su "id -u";
                suWhichFirefox = su "which firefox";
                suFirefox = su "firefox http://127.0.0.1:5000 >&2 &";
                suPgrepFirefox = su "pgrep -x firefox";
              in
              ''
                start_all()

                machineWithDockerFirefoxOCR.succeed("docker load < ${self.packages.${system}.myappOCIImage}")
                machineWithDockerFirefoxOCR.succeed("docker run -d --rm --publish=5000:5000 myapp-oci-image:0.0.1")
                machineWithDockerFirefoxOCR.wait_for_open_port(5000)
                machineWithDockerFirefoxOCR.wait_until_succeeds("curl http://127.0.0.1:5000")

                machineWithDockerFirefoxOCR.wait_for_unit("default.target")
                machineWithDockerFirefoxOCR.succeed("${suId} | grep -q '1000'")
                machineWithDockerFirefoxOCR.succeed("${suWhichFirefox}")
                machineWithDockerFirefoxOCR.execute("${suFirefox}")

                # machineWithDockerFirefoxOCR.succeed("${suPgrepFirefox}")
                # machineWithDockerFirefoxOCR.sleep(20)
                # machineWithDockerFirefoxOCR.screenshot("screen")

                machineWithDockerFirefoxOCR.wait_for_text(r"(Hello world!!)")
                machineWithDockerFirefoxOCR.screenshot("screen")
              '';
            # hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
          };

          testMyappOCIImageDocker = pkgs.testers.runNixOSTest {
            name = "test-myapp-as-oci-image-docker";
            nodes.machineWithDocker =
              { config, pkgs, lib, ... }:
              {
                config.virtualisation.docker.enable = true;
              };

            enableOCR = true;

            testScript = ''
              start_all()

              machineWithDocker.succeed("docker load < ${self.packages.${system}.myappOCIImage}")
              machineWithDocker.succeed("docker run -d --rm --publish=5000:5000 myapp-oci-image:0.0.1")
              machineWithDocker.wait_for_open_port(5000)
              machineWithDocker.wait_until_succeeds("curl http://127.0.0.1:5000")
              machineWithDocker.succeed("curl http://127.0.0.1:5000 | grep -q 'Hello world!!'")
            '';
          };

          testMyappOCIImagePodman = pkgs.testers.runNixOSTest {
            name = "test-myapp-as-oci-image-podman";

            nodes.machineWithPodman =
              { config, pkgs, lib, ... }:
              {
                config.virtualisation.podman.enable = true;
              };

            testScript = ''
              start_all()

              machineWithPodman.succeed("podman load < ${self.packages.${system}.myappOCIImage}")
              machineWithPodman.succeed("podman run -d --rm --publish=5000:5000 localhost/myapp-oci-image:0.0.1")
              machineWithPodman.wait_for_open_port(5000)
              machineWithPodman.wait_until_succeeds("curl http://127.0.0.1:5000")
              machineWithPodman.succeed("curl http://127.0.0.1:5000 | grep -q 'Hello world!!'")

            '';
            # hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
          };
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [ foo-bar myapp poetry ];

          shellHook = ''
          '';
        };

        # Shell for poetry.
        #     nix develop .#poetry
        # Use this shell for changes to pyproject.toml and poetry.lock.
        devShells.poetry = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };

        # nixosConfigurations.vm = pkgs.nixos-vm;
      }
    )
  );
  #  // {
  #    nixosConfigurations.vm = pkgs.nixos-vm;
  #  };
}
