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
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        # docker manifest inspect arm64v8/python:3.9.19-alpine3.20 | jq -r '.manifests.[0].digest' | cut -d':' -f 2
        # docker inspect arm64v8/python:3.9.19-alpine3.20
        OCIImageAlpinePythonArm64 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "arm64v8/python";
          imageDigest = "sha256:f4ea62bac1c88afff3a1f7636b07f6ec7b88b2dac4700eab67a780b9d58e6b85";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-lWR5/mtbs3D3hJDW4Vcrbmzubht0rSty4LdmsV3RcT8=";
          os = "linux";
          arch = "arm64";
        };

        OCIImageAlpinePythonArm32v7 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "arm32v7/python";
          imageDigest = "sha256:4e0a03de7fef5f3c869f38e9007589b89d307eb01fe97d82598bf66775e005a1";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-XLk9XAuenbtGSIYfDk945kXUKs5bR9V8R2t0RGO9huU=";
          os = "linux";
          arch = "arm32v7";
        };

        OCIImageAlpinePythonArm32v6 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "arm32v6/python";
          imageDigest = "sha256:82611729afdd581bc0e05ef5ecc1634799ef0ee673e7296a586aef38b106a8bc";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-XHUBcAOwScD7qJ6xi+Mle9q1u2ADQ5bwENjVxh1RDwQ=";
          os = "linux";
          arch = "arm32v6";
        };

        OCIImageAlpinePythonArm32v5 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-bookworm";
          finalImageName = "arm32v5/python";
          imageDigest = "sha256:247fe8a580eae523aee81504c20aeca9323114afdbcb9fba2c5229fc4c0c4903";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-cYdo2IV/8Q2BtZNCa6hjFGwb7mbFb0YhN5yrmBV4CBA=";
          os = "linux";
          arch = "arm32v5";
        };

        OCIImageAlpinePythonS390x = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "s390x/python";
          imageDigest = "sha256:21324df35e10d53f79b9587ad0d91bd89181df9f6d022e0229b4291cb65a4fc0";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-c2u+O8nxUBARbLx6fd/FoAYe3WgC++Ln9XljmSnQvRA=";
          os = "linux";
          arch = "s390x";
        };
        # docker manifest inspect riscv64/python:3.9.19-alpine | jq -r '.manifests.[0].digest' | cut -d':' -f2
        OCIImageAlpinePythonRiscv64 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "riscv64/python";
          imageDigest = "sha256:36a1c88eab2ff9f68e268eb5de75131805273d98e357dda5d924540f1796de7d";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-DZ5lJffpW2BML5vTSIUkqnrzV9oni86elb0urLjBsns=";
          os = "linux";
          arch = "riscv64";
        };

        OCIImageAlpinePythonPpc64le = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "ppc64le/python";
          imageDigest = "sha256:f56318bbaa479265e03493c5bf402e26f1a51692f6661e1ec7e07be89d104ebf";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-SCFUZfClFIDoS29z97UNF9nbToDjBzkufG5BDAPSJ1k=";
          os = "linux";
          arch = "ppc64le";
        };

        OCIImageAlpinePythonI386 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "i386/python";
          imageDigest = "sha256:2533bb5bc9d63eb0252c4d5902a7308ac850e8ef98e3412eec33332d6ad56c99";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-xqDVS8iIM/5GawcfIuGilw070cOr00zaZPvwXwqmUAw=";
          os = "linux";
          arch = "386";
        };

        OCIImageAlpinePythonAmd64 = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-alpine3.20";
          finalImageName = "amd64/python";
          imageDigest = "sha256:08c95d38ed6f5291c4c213d3d89738cdfd439ddb3f1833649b012650b41597e3";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-bIdjnotIoMrpUOlzIIPlIbBxrXs+jyLiXz+rZinYcx0=";
          os = "linux";
          arch = "amd64";
        };

        #
        OCIImageAlpineBookwormMips64el = prev.dockerTools.pullImage {
          finalImageTag = "3.9.19-slim-bookworm";
          finalImageName = "mips64le/python";
          imageDigest = "sha256:bfaf671636651d1a449fc586e1b5875d73f47e47d7be7b35d9550191d0030320";
          imageName = "docker.io/library/python";
          name = "mips64le/docker.io/library/python";
          sha256 = "sha256-16ro6oNHNNRcA20kkhHRIbb2/eD32e18rBzciOMz9Rw=";
          os = "linux";
          arch = "mips64le";
        };

        #
        OCIImageTonistiigiBinfmt = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:66e11bea77a5ea9d6f0fe79b57cd2b189b5d15b93a2bdb925be22949232e4e55";
          imageName = "tonistiigi/binfmt";
          name = "tonistiigi/binfmt";
          sha256 = "sha256-Fax1Xf7OUch5hnFaW4SarIfkHJPNyoNoQfhsCw6f2NM=";
        };

        testBinfmtManyEmulatedSystems = prev.testers.runNixOSTest {
          name = "test-binfmt-many";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {

              # config.boot.tmp.useTmpfs = true;
              # config.boot.tmp.cleanOnBoot = true;
              # config.boot.tmp.tmpfsSize = "98%";
              # config.virtualisation.memorySize = 1024 * 3;
              config.virtualisation.diskSize = 1024 * 6;

              config.virtualisation.docker.enable = true;

              config.boot.binfmt.emulatedSystems = [
                "aarch64-linux"
                # "armv6l-linux" # TODO: why arm32v5, arm32v6 and arm32v7 work?
                "armv7l-linux" # TODO: why arm32v5, arm32v6 and arm32v7 work?
                # "i386-linux"
                # "i686-linux"
                "mips64el-linux"
                "powerpc64le-linux"
                "riscv64-linux"
                "s390x-linux"
              ];

              config.boot.binfmt.registrations = {
                aarch64-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-aarch64";
                  fixBinary = true;
                };
                armv7l-linux = {
                  # TODO: why armv6l-linux gives the same result?
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-arm";
                  # interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-armeb";
                  fixBinary = true;
                };
                #i686-linux = {
                #  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-i386";
                #  fixBinary = true;
                #};
                #
                #i686-linux = {
                #  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-x86_64";
                #  fixBinary = true;
                #};
                mips64el-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-mips64el";
                  fixBinary = true;
                };
                powerpc64le-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-ppc64le";
                  fixBinary = true;
                };
                riscv64-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv64";
                  fixBinary = true;
                };
                s390x-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-s390x";
                  fixBinary = true;
                };
              };
            };

          globalTimeout = 4 * 60;

          testScript = { nodes, ... }: ''
            start_all()
            machine.wait_for_unit("default.target")

            machine.succeed("docker load <${final.OCIImageAlpinePythonArm64}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonArm32v7}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonArm32v6}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonArm32v5}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonS390x}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonRiscv64}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonPpc64le}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonI386}")
            machine.succeed("docker load <${final.OCIImageAlpinePythonAmd64}")
            machine.succeed("docker load <${final.OCIImageAlpineBookwormMips64el}")

            # machine.succeed("docker load <${final.OCIImageTonistiigiBinfmt}")

            print(machine.succeed("docker images"))

            # machine.succeed("docker run --privileged --rm tonistiigi/binfmt --install all")
            # machine.succeed("docker run --privileged --rm tonistiigi/binfmt --install arm64,riscv64,arm,s390x,ppc64le,mips64le")

            with subtest("arm32v5"):
                expected = 'armel armv7l Python 3.9.19 linux-armv7l little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/arm arm32v5/python:3.9.19-bookworm \
                  sh -c \
                  '
                   dpkg --print-architecture \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("arm32v6"):
                expected = 'armhf armv7l Python 3.9.19 linux-armv7l little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/arm arm32v6/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("arm32v7"):
                expected = 'armv7 armv7l Python 3.9.19 linux-armv7l little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/arm arm32v7/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("arm64v8"):
                expected = 'aarch64 aarch64 Python 3.9.19 linux-aarch64 little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/arm64 arm64v8/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("s390x"):
                expected = 's390x s390x Python 3.9.19 linux-s390x big '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/s390x s390x/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("riscv64"):
                expected = 'riscv64 riscv64 Python 3.9.19 linux-riscv64 little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/riscv64 riscv64/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("ppc64le"):
                expected = 'ppc64le ppc64le Python 3.9.19 linux-ppc64le little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/ppc64le ppc64le/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("mips64le"):
                expected = 'mips64el mips64 Python 3.9.19 linux-mips64 little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/mips64le mips64le/python:3.9.19-slim-bookworm \
                  sh -c \
                  '
                   dpkg --print-architecture \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("i386"):
                expected = 'x86 x86_64 Python 3.9.19 linux-x86_64 little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/386 i386/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"

            with subtest("amd64"):
                expected = 'x86_64 x86_64 Python 3.9.19 linux-x86_64 little '
                result = machine.succeed("""
                  docker run -it --rm --platform linux/amd64 amd64/python:3.9.19-alpine3.20 \
                  sh -c \
                  '
                   apk --print-arch \
                   && uname -m && \
                   python3 --version \
                   && python -c "import sys; import sysconfig; print(sysconfig.get_platform(), sys.byteorder)"
                  '
                """).replace("\r\n", ' ')
                assert expected == result, f"expected = {expected}, result = {result}"
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
                  aarch64-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-aarch64";
                    fixBinary = true;
                  };

                  armv7l-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-arm";
                    fixBinary = true;
                  };

                  i686-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-i386";
                    fixBinary = true;
                  };

                  mips64el-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-mips64el";
                    fixBinary = true;
                  };

                  powerpc64le-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-ppc64le";
                    fixBinary = true;
                  };

                  riscv64-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv64";
                    fixBinary = true;
                  };

                  s390x-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-s390x";
                    fixBinary = true;
                  };
                };

                boot.binfmt.emulatedSystems = [
                  "aarch64-linux"
                  "armv7l-linux"
                  "i686-linux"
                  "mips64el-linux"
                  "powerpc64le-linux"
                  "riscv64-linux"
                  "s390x-linux"
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

                    docker load <"${final.OCIImageTonistiigiBinfmt}"

                    docker load <"${final.OCIImageAlpinePythonArm64}"
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
            myvm
            automatic-vm
            testBinfmtManyEmulatedSystems
            ;

          default = pkgs.testBinfmtManyEmulatedSystems;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            OCIImageAlpinePythonArm64
            OCIImageAlpinePythonArm32v7
            OCIImageAlpinePythonArm32v6
            OCIImageAlpinePythonArm32v5
            OCIImageAlpinePythonS390x
            OCIImageAlpinePythonRiscv64
            OCIImageAlpinePythonPpc64le
            OCIImageAlpinePythonI386
            OCIImageAlpinePythonAmd64
            OCIImageAlpineBookwormMips64el
            OCIImageTonistiigiBinfmt

            myvm
            automatic-vm
            testBinfmtManyEmulatedSystems
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
