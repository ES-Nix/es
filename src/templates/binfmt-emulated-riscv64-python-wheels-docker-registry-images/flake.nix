{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/345c263f2f53a3710abe117f28a5cb86d0ba4059' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/2d2a9ddbe3f2c00747398f3dc9b05f7f2ebb0f53' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        # docker manifest inspect riscv64/python:3.9.19-alpine | jq -r '.manifests.[0].digest' | cut -d':' -f2
        OCIImageAlpineRiscv64 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "riscv64/python";
          imageDigest = "sha256:36a1c88eab2ff9f68e268eb5de75131805273d98e357dda5d924540f1796de7d";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-DZ5lJffpW2BML5vTSIUkqnrzV9oni86elb0urLjBsns=";
          os = "linux";
          arch = "riscv64";
        };

        distRiscv64 = prev.pkgsCross.riscv64.python312Packages.mmh3.dist;

        riscv64Python312 = prev.pkgsCross.riscv64.python312.withPackages (pyPkgs: with pyPkgs; [
          mmh3 # for tests
          # Not packaged?!
          # maturin
          # msgpack
          # psutils

          # charset_normalizer
          # rpds_py
          # ruamel.yaml.clib
          # opencv-python

          # llvmlite
          # numba

          # Broken in Riscv64 arch
          # ray
          # pytorch

          # Broken build Riscv64
          # tokenizers
          # torchaudio
          # torchvision

          # Broken
          # transformers
          # fastapi
          # watchfiles
          # uv
          # sentencepiece
          # safetensors
          # pandas
          # jiter
          # scikit-learn

          # Compiles!
          # TODO: test again!
          #aiohttp
          #cffi
          #cryptography
          #frozenlist
          #httptools
          #lxml
          #msgspec
          #multidict
          #nh3
          #orjson
          #protobuf
          #pyzmq
          #regex
          #tiktoken
          #ujson
          #uvicorn
          #uvloop
          #websockets
          #xxhash
          #yarl
        ]);

        testBinfmtMany = prev.testers.runNixOSTest {
          name = "test-riscv64-python-wheels";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {

              config.virtualisation.diskSize = 1024 * 6;

              config.virtualisation.docker.enable = true;

              config.environment.systemPackages = with final; [
                pkgsCross.riscv64.python312
                riscv64Python312
              ];

              config.boot.binfmt.emulatedSystems = [
                "riscv64-linux"
              ];

              config.boot.binfmt.registrations = {
                riscv64-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv64";
                  fixBinary = true;
                };
              };
            };

          globalTimeout = 2 * 60;

          /*
              ${
                final.python39Packages.mmh3.pname
                + "-"
                + final.python39Packages.mmh3.version
                + "-"
                + "cp"
                + final.python39.sourceVersion.major
                + final.python39.sourceVersion.minor
                + "-"
                + "cp"
                + final.python39.sourceVersion.major
                + final.python39.sourceVersion.minor
                + "-"
                + final.stdenv.hostPlatform.parsed.kernel.name
                + "_"
                + final.stdenv.hostPlatform.parsed.cpu.name
                + ".whl"
              }
            */
          testScript = { nodes, ... }: ''
            start_all()
            machine.wait_for_unit("default.target")

            print(machine.succeed("cp -v ${final.distRiscv64}/*.whl ."))
            print(machine.succeed("ls -alh *.whl"))

            print(machine.succeed("""
                    python3 -m venv .venv \
                    && source .venv/bin/activate \
                    && pip install --root-user-action=ignore *.whl \
                    && python3 -c "import mmh3; assert mmh3.hash128(bytes(123)) == 126000048256919600573431412872524959502"
                  """))
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

                boot.binfmt.registrations = {
                  riscv64-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv64";
                    fixBinary = true;
                  };
                };

                boot.binfmt.emulatedSystems = [
                  "riscv64-linux"
                ];

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

                    docker load <"${pkgs.OCIImageAlpineRiscv64}"
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
                    foo-bar
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
          text = ''
            export VNC_PORT=3001

            ${final.myvm}/bin/run-nixos-vm & PID_QEMU="$!"

            for _ in {0..50}; do
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
            testBinfmtMany
            ;

          default = pkgs.testBinfmtMany;
        };

        packages.myvm = pkgs.myvm;
        packages.automatic-vm = pkgs.automatic-vm;

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            # testBinfmtMany
            # automatic-vm
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
          ];
          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true
          '';
        };

      }
    )
  );
}
