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
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'


    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        packageFlaskAPI = prev.python3Packages.buildPythonPackage rec {
          pname = "packageFlaskAPI";
          version = "0.0.1";

          src = ./fl4sk;

          doCheck = false;

          propagatedBuildInputs = with prev.python3Packages; [
            flask
          ];
        };

        python3WithPackage =
          let
            # pyCustom = (prev.python3Minimal.override {
            pyCustom = (prev.python3.override {
              self = pyCustom;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (pyPkgs: with pyPkgs; [
            final.packageFlaskAPI
            # scipy
          ]);


        appFl4skAPI = prev.python3Packages.buildPythonApplication {
          pname = "fl4sk";
          version = "0.0.1";

          propagatedBuildInputs = with prev.python3Packages; [
            flask

            uvicorn
            opentelemetry-instrumentation
            opentelemetry-instrumentation-flask
          ];

          src = ./fl4sk;

          meta.mainProgram = "fl4sk";
        };

        # docker run --rm -ti --publish=8080:8080 fl4sk-app:0.0.1
        OCIImageAppFl4skAPI = prev.dockerTools.buildImage {
          name = "fl4sk-app";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.appFl4skAPI
          ];
          config = {
            Cmd = [ "${prev.lib.getExe final.appFl4skAPI}" ];
          };
        };
        # docker run --rm -ti --publish=8080:8080 python-with-package:0.0.1
        OCIImagePythonWithPackage = prev.dockerTools.buildImage {
          name = "python-with-package";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.python3WithPackage
          ];
          config.Entrypoint = [ "${prev.lib.getExe final.python3WithPackage}" ];
          config.Cmd = [ "-m" "fl4sk" ];
        };


        testFl4skBin = prev.testers.runNixOSTest {
          name = "test-fl4sk";
          nodes.machineWithPythonCustom =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.environment.systemPackages = with final; [
                lsof
                file
                python3WithPackage
              ];
            };

          globalTimeout = 60;

          testScript = { nodes, ... }:
            let
              apiPort = "${ toString 8080}";

              url = "http://127.0.0.1:${apiPort}";
              cmdCurlAndGrep = "curl ${url} | grep --quiet -F 'Hello, World! vQrEwlbbw94pj96bpvxb7d7p'";

              isThreAnServerOnPort = "lsof -t -i tcp:${apiPort} -s tcp:listen";
            in
            ''
              start_all()

              machineWithPythonCustom.wait_for_unit("default.target")
              machineWithPythonCustom.succeed("type lsof")
              machineWithPythonCustom.succeed("type file")
              machineWithPythonCustom.succeed("type fl4sk")
              assert ", dynamically linked, interpreter /nix/store/" in machineWithPythonCustom.succeed("file $(readlink -f $(which fl4sk))")

              machineWithPythonCustom.succeed("fl4sk >&2 &")

              machineWithPythonCustom.wait_for_open_port(${apiPort})
              machineWithPythonCustom.succeed("pgrep -f fl4sk")
              machineWithPythonCustom.succeed("pgrep -f python3")
              machineWithPythonCustom.wait_until_succeeds("${cmdCurlAndGrep}")
              machineWithPythonCustom.succeed("kill -9 $(${isThreAnServerOnPort})") #  ps -ww -fp $(lsof -t -i tcp:${apiPort}" -s tcp:listen)
              machineWithPythonCustom.fail("${isThreAnServerOnPort}")
              machineWithPythonCustom.fail("pgrep -f fl4sk")
              machineWithPythonCustom.fail("pgrep -f python3")
            '';
        };


        testFl4skPythonModule = prev.testers.runNixOSTest {
          name = "test-fl4sk-python-module";
          nodes.machineWithPythonCustom =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.environment.systemPackages = with final; [
                lsof
                file
                python3WithPackage
              ];
            };

          globalTimeout = 60;

          testScript = { nodes, ... }:
            let
              apiPort = "${ toString 8080}";

              url = "http://127.0.0.1:${apiPort}";
              cmdCurlAndGrep = "curl ${url} | grep --quiet -F 'Hello, World! vQrEwlbbw94pj96bpvxb7d7p'";
            in
            ''
              start_all()

              machineWithPythonCustom.wait_for_unit("default.target")

              machineWithPythonCustom.succeed("type lsof")
              machineWithPythonCustom.succeed("type file")

              assert 'fl4sk is /run/current-system/sw/bin/fl4sk' in machineWithPythonCustom.succeed("type fl4sk")
              assert ', dynamically linked, interpreter /nix/store/' in machineWithPythonCustom.succeed("file $(readlink -f $(which fl4sk))")

              machineWithPythonCustom.succeed("python -c 'import fl4sk'")
              machineWithPythonCustom.succeed("python -m fl4sk >&2 &")

              machineWithPythonCustom.wait_for_open_port(${apiPort})
              machineWithPythonCustom.succeed("pgrep -f fl4sk")
              machineWithPythonCustom.succeed("pgrep -f python3")
              machineWithPythonCustom.wait_until_succeeds("${cmdCurlAndGrep}")
              machineWithPythonCustom.succeed("kill -9 $(lsof -t -i tcp:${apiPort} -s tcp:listen)") #  ps -ww -fp $(lsof -t -i tcp:8080 -s tcp:listen)
              machineWithPythonCustom.fail("lsof -t -i tcp:${apiPort} -s tcp:listen")
              machineWithPythonCustom.fail("pgrep -f fl4sk")
              machineWithPythonCustom.fail("pgrep -f python3")
            '';
        };

        testFl4skPythonApplication = prev.testers.runNixOSTest {
          name = "test-only-fl4sk-application";
          nodes.machineWithOnlyFl4skApplication =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.environment.systemPackages = with final; [
                lsof
                file
                appFl4skAPI
              ];
            };

          globalTimeout = 60;

          testScript = { nodes, ... }:
            let
              apiPort = "${ toString 8080}";

              url = "http://127.0.0.1:${apiPort}";
              cmdCurlAndGrep = "curl ${url} | grep --quiet -F 'Hello, World! vQrEwlbbw94pj96bpvxb7d7p'";
            in
            ''
              start_all()

              machineWithOnlyFl4skApplication.wait_for_unit("default.target")
              machineWithOnlyFl4skApplication.succeed("type lsof")
              machineWithOnlyFl4skApplication.succeed("type file")
              machineWithOnlyFl4skApplication.succeed("type fl4sk")
              assert 'bash -e script, ASCII text executable' in machineWithOnlyFl4skApplication.succeed("file $(readlink -f $(which fl4sk))")

              machineWithOnlyFl4skApplication.fail("python")
              machineWithOnlyFl4skApplication.fail("python3")
              # assert 'python3: command not found' in machineWithOnlyFl4skApplication.fail("python3")

              machineWithOnlyFl4skApplication.succeed("fl4sk >&2 &")

              machineWithOnlyFl4skApplication.wait_for_open_port(${apiPort})
              machineWithOnlyFl4skApplication.succeed("pgrep -f fl4sk")
              machineWithOnlyFl4skApplication.succeed("pgrep -f python3")
              machineWithOnlyFl4skApplication.wait_until_succeeds("${cmdCurlAndGrep}")
              machineWithOnlyFl4skApplication.succeed("kill -9 $(lsof -t -i tcp:${apiPort} -s tcp:listen)") #  ps -ww -fp $(lsof -t -i tcp:8080 -s tcp:listen)
              machineWithOnlyFl4skApplication.fail("lsof -t -i tcp:${apiPort} -s tcp:listen")
              machineWithOnlyFl4skApplication.fail("pgrep -f fl4sk")
              machineWithOnlyFl4skApplication.fail("pgrep -f python3")
            '';
        };

        testOCIImageAppFl4skAPIDocker = prev.testers.runNixOSTest {
          name = "test-oci-image-app-fl4sk-api-docker";
          nodes.machineWithDocker =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.environment.systemPackages = with pkgs; [
                dive
              ];
            };

          globalTimeout = 1 * 60;

          testScript = { nodes, ... }:
            let
              apiPort = "${ toString 8080}";
              textFromAPI = "'Hello, World! vQrEwlbbw94pj96bpvxb7d7p'";
              imageNameAndTag = "${final.OCIImageAppFl4skAPI.imageName}:${final.OCIImageAppFl4skAPI.imageTag}";

              url = "http://127.0.0.1:${apiPort}";
              cmdCurlAndGrep = "curl ${url} | grep --quiet -F ${textFromAPI}";
            in
            ''
              start_all()

              machineWithDocker.succeed("docker load < ${final.OCIImageAppFl4skAPI}")
              machineWithDocker.succeed("dive --ci ${imageNameAndTag}")
              machineWithDocker.succeed("docker run -d --name=container-app --rm --publish=${apiPort}:${apiPort} ${imageNameAndTag}")
              machineWithDocker.wait_for_open_port(${apiPort})
              machineWithDocker.wait_until_succeeds("${cmdCurlAndGrep}")
            '';
        };

        testOCIImagePythonWithPackageDocker = prev.testers.runNixOSTest {
          name = "test-oci-image-python-with-package-docker";
          nodes.machineWithDocker =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.environment.systemPackages = with pkgs; [
                dive
              ];
            };

          enableOCR = true;
          globalTimeout = 1 * 60;

          testScript = { nodes, ... }:
            let
              apiPort = "${ toString 8080}";
              textFromAPI = "Hello, World! vQrEwlbbw94pj96bpvxb7d7p";
              imageNameAndTag = "${final.OCIImagePythonWithPackage.imageName}:${final.OCIImagePythonWithPackage.imageTag}";

              url = "http://127.0.0.1:${apiPort}";
              cmdCurlAndGrep = "curl ${url} | grep --quiet -F '${textFromAPI}'";
            in
            ''
              start_all()

              machineWithDocker.succeed("type dive")

              machineWithDocker.succeed("docker load < ${final.OCIImagePythonWithPackage}")
              machineWithDocker.succeed("dive --ci ${imageNameAndTag}")
              machineWithDocker.succeed("docker run -d --name=container-app --rm --publish=${apiPort}:${apiPort} ${imageNameAndTag}")
              machineWithDocker.wait_for_open_port(${apiPort})
              machineWithDocker.wait_until_succeeds("${cmdCurlAndGrep}")
            '';
        };

        testOCIImageAppFl4skAPIDockerFirefoxOCR = prev.testers.runNixOSTest {
          name = "test-oci-image-app-fl4sk-api-docker-firefox-ocr";
          nodes.machineWithDockerFirefoxOCR =
            { config, pkgs, lib, modulesPath, ... }:
            {
              imports = [
                "${dirOf modulesPath}/tests/common/x11.nix"
              ];

              config.services.xserver.enable = true;
              # config.services.xserver.displayManager.startx.enable = true;

              # config.services.xserver.desktopManager.xfce.enable = true;
              # config.services.xserver.desktopManager.xfce.enableScreensaver = false;

              config.environment.systemPackages = with pkgs; [
                final.appFl4skAPI
                lsof
                file
                xdotool
                firefox
              ];

            };

          enableOCR = true;
          globalTimeout = 2 * 60;

          testScript = { nodes, ... }:
            let
              apiPort = "${ toString 8080}";
              textFromAPI = "'Hello, World! vQrEwlbbw94pj96bpvxb7d7p'";
              imageNameAndTag = "${final.OCIImageAppFl4skAPI.imageName}:${final.OCIImageAppFl4skAPI.imageTag}";

              url = "http://127.0.0.1:${apiPort}";
              cmdCurlAndGrep = "curl ${url} | grep --quiet -F ${textFromAPI}";
              cmdFirefoxUrl = "firefox ${url} >&2 &";
            in
            ''
              start_all()

              machineWithDockerFirefoxOCR.succeed("type lsof")
              machineWithDockerFirefoxOCR.succeed("type file")
              machineWithDockerFirefoxOCR.succeed("type firefox")

              machineWithDockerFirefoxOCR.succeed("type fl4sk")
              assert "script, ASCII text executable" in machineWithDockerFirefoxOCR.succeed("file $(readlink -f $(which fl4sk))")

              machineWithDockerFirefoxOCR.execute("fl4sk >&2 &")

              machineWithDockerFirefoxOCR.wait_for_open_port(${apiPort})
              machineWithDockerFirefoxOCR.succeed("pgrep -f fl4sk")
              machineWithDockerFirefoxOCR.succeed("pgrep -f python3")
              machineWithDockerFirefoxOCR.succeed("${cmdCurlAndGrep}")

              machineWithDockerFirefoxOCR.wait_for_unit("default.target")
              machineWithDockerFirefoxOCR.wait_for_x()

              machineWithDockerFirefoxOCR.execute("${cmdFirefoxUrl}")
              machineWithDockerFirefoxOCR.wait_until_succeeds("pgrep -f '.firefox-wrapped'")
              machineWithDockerFirefoxOCR.wait_for_window("Mozilla Firefox")
              machineWithDockerFirefoxOCR.sleep(5) # TODO: race condition!

              machineWithDockerFirefoxOCR.screenshot("screen0")
              machineWithDockerFirefoxOCR.execute("xdotool key ctrl+plus")
              machineWithDockerFirefoxOCR.execute("xdotool key ctrl+plus")
              machineWithDockerFirefoxOCR.execute("xdotool key ctrl+plus")
              machineWithDockerFirefoxOCR.execute("xdotool key ctrl+plus")
              machineWithDockerFirefoxOCR.execute("xdotool key ctrl+plus")
              machineWithDockerFirefoxOCR.screenshot("screen1")
              machineWithDockerFirefoxOCR.wait_for_text(r"Hello, World! vQrEwlbbw94pj96bpvxb7d7p")
              machineWithDockerFirefoxOCR.screenshot("screen2")
            '';
        };

        testOCIImagePythonWithPackageDockerFirefoxOCR = prev.testers.runNixOSTest {
          name = "test-oci-image-python-with-package-docker-firefox-ocr";
          nodes.machineWithDockerFirefoxOCR =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;

              config.services.xserver.enable = true;
              config.services.displayManager.autoLogin.user = "alice";
              config.services.xserver.desktopManager.xfce.enable = true;
              config.services.xserver.desktopManager.xfce.enableScreensaver = false;

              config.environment.systemPackages = with pkgs; [
                firefox
                dive
              ];
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
          globalTimeout = 3 * 60;

          testScript = { nodes, ... }:
            let
              apiPort = "${ toString 8080}";
              textFromAPI = "Hello, World! vQrEwlbbw94pj96bpvxb7d7p";
              imageNameAndTag = "${final.OCIImagePythonWithPackage.imageName}:${final.OCIImagePythonWithPackage.imageTag}";

              url = "http://127.0.0.1:${apiPort}";
              cmdCurlAndGrep = "curl ${url} | grep --quiet -F '${textFromAPI}'";

              user = nodes.machineWithDockerFirefoxOCR.users.users.alice;

              su = command: "su - ${user.name} -c '${command}'";

              suId = su "id -u";
              suWhichFirefox = su "which firefox";
              suFirefox = su "firefox http://127.0.0.1:${apiPort} >&2 &";
              suPgrepFirefox = su "pgrep -f firefox";
            in
            ''
              start_all()

              machineWithDockerFirefoxOCR.succeed("type firefox")
              machineWithDockerFirefoxOCR.succeed("type dive")

              machineWithDockerFirefoxOCR.succeed("docker load < ${final.OCIImagePythonWithPackage}")
              machineWithDockerFirefoxOCR.succeed("dive --ci ${imageNameAndTag}")
              machineWithDockerFirefoxOCR.succeed("docker run -d --name=container-app --rm --publish=${apiPort}:${apiPort} ${imageNameAndTag}")
              machineWithDockerFirefoxOCR.wait_for_open_port(${apiPort})
              machineWithDockerFirefoxOCR.wait_until_succeeds("${cmdCurlAndGrep}")

              machineWithDockerFirefoxOCR.wait_for_unit("default.target")
              machineWithDockerFirefoxOCR.wait_for_x()

              machineWithDockerFirefoxOCR.succeed("${suId} | grep -q '1000'")
              machineWithDockerFirefoxOCR.succeed("${suWhichFirefox}")

              machineWithDockerFirefoxOCR.execute("${suFirefox}")
              machineWithDockerFirefoxOCR.wait_until_succeeds("${suPgrepFirefox}")
              machineWithDockerFirefoxOCR.screenshot("screen0")

              machineWithDockerFirefoxOCR.wait_for_text(r"${textFromAPI}")
              machineWithDockerFirefoxOCR.screenshot("screen12")
            '';
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
                    echo "Loading OCI Images in docker..."

                    docker load <"${pkgs.OCIImageAppFl4skAPI}"
                    docker load <"${pkgs.OCIImagePythonWithPackage}"
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
                    git
                    jq
                    lsof
                    findutils
                    dive
                    foo-bar
                    # uwsgi
                    final.appFl4skAPI
                    python3WithPackage
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

                environment.variables.OCI_PATH = "${pkgs.OCIImageAppFl4skAPI}";

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

              ${final.lib.getExe final.myvm} & PID_QEMU="$!"

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
      {
        packages = {
          inherit (pkgs)
            appFl4skAPI
            automatic-vm
            myvm
            OCIImageAppFl4skAPI
            OCIImagePythonWithPackage
            packageFlaskAPI
            python3WithPackage
            ;
          default = pkgs.python3WithPackage;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automatic-vm}";
            meta.description = "Run the NixOS VM with QEMU and connect to it with remote-viewer";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testFl4skBin
            testFl4skPythonModule
            testFl4skPythonApplication

            testOCIImageAppFl4skAPIDocker
            testOCIImagePythonWithPackageDocker

            testOCIImageAppFl4skAPIDockerFirefoxOCR
            testOCIImagePythonWithPackageDockerFirefoxOCR

            automatic-vm
            ;
          default = pkgs.testFl4skBin;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            foo-bar
            appFl4skAPI
            python3WithPackage
          ];

          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true

            # echo ${pkgs.OCIImagePythonWithPackage}
          '';
        };
      }
    )
  );
}
