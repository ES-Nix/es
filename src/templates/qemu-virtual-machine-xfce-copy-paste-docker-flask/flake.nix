{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'    
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        packageFlaskAPI = prev.python3Packages.buildPythonPackage rec {
          pname = "packageFlaskAPI";
          version = "0.0.1";

          src = ./.;

          doCheck = false;

          propagatedBuildInputs = with prev.python3Packages; [
            flask
          ];

          meta.mainProgram = "main.py";
        };

        appFlaskAPI = prev.python3Packages.buildPythonApplication {
          pname = "myFlaskServer";
          version = "0.0.1";

          interpreter = prev.pkgsMusl.python3Minimal;

          propagatedBuildInputs = with prev.python3Packages; [
            flask
            numpy
          ];

          src = ./.;
          postInstall = ''
            mv -v $out/bin/main.py $out/bin/run-flask-server
          '';

          meta.mainProgram = "run-flask-server";
        };

        python3WithFlask =
          let
            pyCustom = (prev.python3.override {
              self = pyCustom;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (pyPkgs: with pyPkgs; [
            # final.appFlaskAPI
            final.packageFlaskAPI
          ]);

        # docker run --rm -ti --publish=8080:8080 flask-app:0.0.1
        python3WithFlaskOCIImage = prev.dockerTools.buildImage {
          name = "flask-app";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.appFlaskAPI
            # final.python3WithFlask
          ];
          config = {
            Cmd = [ "${prev.lib.getExe final.appFlaskAPI}" ];
          };
        };

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = prev.system;
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

                # journalctl --unit docker-custom-bootstrap-1.service -b -f
                systemd.services.docker-custom-bootstrap-1 = {
                  description = "Docker Custom Bootstrap 1";
                  wantedBy = [ "multi-user.target" ];
                  after = [ "docker.service" ];
                  path = with pkgs; [ docker ];
                  script = ''
                    # set -x
                    echo "Loading OCI Image in docker..."

                    docker load <"${pkgs.python3WithFlaskOCIImage}"

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
                    final.appFlaskAPI
                    # final.python3WithFlask
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
                ];

                system.stateVersion = "24.05";
              })

            { nixpkgs.overlays = [ self.overlays.default ]; }
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

              for _ in {0..100}; do
                if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
                then
                  break
                fi
                # date +'%d/%m/%Y %H:%M:%S:%3N'
                sleep 0.1
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
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

    in
    flake-utils.lib.eachSystem suportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      rec {
        packages = {
          inherit (pkgs)
            appFlaskAPI
            python3WithFlask
            python3WithFlaskOCIImage
            ;
        };
        # packages.default = pkgs.myapp;

        packages.myvm = pkgs.myvm;
        packages.default = packages.automatic-vm;
        packages.automatic-vm = pkgs.automatic-vm;

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };


        formatter = pkgs.nixpkgs-fmt;

        checks = {
          testMyappFirefoxOCR = pkgs.testers.runNixOSTest {
            name = "test-myapp-firefox-ocr";
            nodes.machineWithFirefoxAndOCR =
              { config, pkgs, lib, modulesPath, ... }:
              {

                imports = [
                  "${dirOf modulesPath}/tests/common/x11.nix"
                  "${dirOf modulesPath}/tests/common/user-account.nix"
                ];

                config.services.xserver.enable = true;
                config.services.xserver.displayManager.startx.enable = true;
                config.networking.firewall.allowedTCPPorts = [ 8080 ];

                config.environment.systemPackages = with pkgs; [
                  firefox
                  appFlaskAPI
                ];

              };

            enableOCR = true;
            globalTimeout = 160;

            testScript = { nodes, ... }:
              let
                apiPort = "${ toString 8080}";

                url = "http://127.0.0.1:${apiPort}";
                cmdFirefoxUrl = "firefox ${url} >&2 &";
              in
              ''
                start_all()

                machineWithFirefoxAndOCR.wait_for_unit("default.target")
                machineWithFirefoxAndOCR.wait_for_unit("graphical.target")
                machineWithFirefoxAndOCR.wait_for_x()
                machineWithFirefoxAndOCR.screenshot("screen0")

                machineWithFirefoxAndOCR.succeed("run-flask-server >&2 &")

                machineWithFirefoxAndOCR.wait_for_open_port(${apiPort})
                machineWithFirefoxAndOCR.wait_until_succeeds("curl ${url} | grep --quiet -F 'Hello, World!'")

                machineWithFirefoxAndOCR.execute("${cmdFirefoxUrl}")
                machineWithFirefoxAndOCR.wait_until_succeeds("pgrep -x firefox")
                machineWithFirefoxAndOCR.screenshot("screen1")
                machineWithFirefoxAndOCR.wait_for_text("Hello, World!")
                machineWithFirefoxAndOCR.screenshot("screen2")
                machineWithFirefoxAndOCR.send_key("alt-f4")
                machineWithFirefoxAndOCR.wait_until_fails("pgrep -x firefox")
              '';
            # hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
          };

          testMyappOCIImageDockerFirefoxOCR = pkgs.testers.runNixOSTest {
            name = "test-myapp-as-oci-image-docker-firefox-ocr";
            nodes.machineWithDockerFirefoxOCR =
              { config, pkgs, lib, modulesPath, ... }:
              {

                imports = [
                  "${dirOf modulesPath}/tests/common/x11.nix"
                  "${dirOf modulesPath}/tests/common/user-account.nix"
                ];

                config.services.xserver.enable = true;
                config.services.xserver.displayManager.startx.enable = true;

                config.virtualisation.docker.enable = true;

                config.environment.systemPackages = with pkgs; [
                  firefox
                ];

              };

            enableOCR = true;
            globalTimeout = 160;

            testScript = { nodes, ... }:
              let
                apiPort = "${ toString 8080}";

                url = "http://127.0.0.1:${apiPort}";
                cmdFirefoxUrl = "firefox ${url} >&2 &";
              in
              ''
                start_all()

                machineWithDockerFirefoxOCR.succeed("docker load < ${self.packages.${system}.python3WithFlaskOCIImage}")
                machineWithDockerFirefoxOCR.succeed("docker run -d --rm --publish=${apiPort}:${apiPort} flask-app:0.0.1")

                machineWithDockerFirefoxOCR.wait_for_open_port(${apiPort})
                machineWithDockerFirefoxOCR.wait_until_succeeds("curl ${url} | grep --quiet -F 'Hello, World!'")

                machineWithDockerFirefoxOCR.wait_for_unit("default.target")
                machineWithDockerFirefoxOCR.wait_for_unit("graphical.target")
                machineWithDockerFirefoxOCR.wait_for_x()
                machineWithDockerFirefoxOCR.screenshot("screen0")

                machineWithDockerFirefoxOCR.execute("${cmdFirefoxUrl}")
                machineWithDockerFirefoxOCR.wait_until_succeeds("pgrep -x firefox")
                # machineWithDockerFirefoxOCR.sleep(15)
                # machineWithDockerFirefoxOCR.wait_for_window("firefox")
                machineWithDockerFirefoxOCR.screenshot("screen1")
                machineWithDockerFirefoxOCR.wait_for_text("Hello, World!")
                # machineWithDockerFirefoxOCR.sleep(12)
                machineWithDockerFirefoxOCR.screenshot("screen2")
                machineWithDockerFirefoxOCR.send_key("alt-f4")
                machineWithDockerFirefoxOCR.wait_until_fails("pgrep -x firefox")
              '';
            # hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
          };

        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
            appFlaskAPI
            packageFlaskAPI
          ];

          shellHook = ''
            echo ${appFlaskAPI}
            echo ${packageFlaskAPI}
            echo ${python3WithFlask}

            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true             
          '';
        };

        # Shell for poetry.
        #     nix develop .#poetry
        # Use this shell for changes to pyproject.toml and poetry.lock.
        devShells.poetry = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };
      }
    )
  );
}
