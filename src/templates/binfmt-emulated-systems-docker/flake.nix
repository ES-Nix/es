{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/345c263f2f53a3710abe117f28a5cb86d0ba4059' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'


    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
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

        # docker manifest inspect alpine:3.20.3
        cachedOCIImageAlpineArm64 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-arm64";
          imageDigest = "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-UslbIYjEyuCaRJPY5KbfndUtoEFhmNvP5/iPahqW7BI=";
          os = "linux";
          arch = "arm64";
        };

        cachedOCIImageAlpineArm32v7 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-arm32v7";
          imageDigest = "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-G5VwDBeL6RkJVZSgmpk8vsg5/QadEZ+3kozRDCU9kGc=";
          os = "linux";
          arch = "arm32v7";
        };

        cachedOCIImageAlpineArm32v6 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-arm32v6";
          imageDigest = "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-ybtmOG3X90qMhhbOrxKmrsGXaS/PhTZIq3Fse0RCDfQ=";
          os = "linux";
          arch = "arm32v6";
        };

        cachedOCIImageAlpineS390x = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-s390x";
          imageDigest = "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-iJ1Eg130MxPxe9exjduhvjpqjBDfO2MCYhPijw6Y5Vc=";
          os = "linux";
          arch = "s390x";
        };

        cachedOCIImageAlpineRiscv64 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-riscv64";
          imageDigest = "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-b3IQWcm8/B5qK+qi70ux5/pCYDz6l+5f3jeRBYEWRVY=";
          os = "linux";
          arch = "riscv64";
        };

        cachedOCIImageAlpinePpc64le = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-ppc64le";
          imageDigest = "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-TL0J0CK1qfbT0q6veW048kNF99nX7cNPsLFqChaatLg=";
          os = "linux";
          arch = "ppc64le";
        };

        cachedOCIImageAlpineI386 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-i386";
          imageDigest = "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-bVEGcj0A+fnYBktDp7hHgTnc4G+qW0XpiisTzpG5pFA=";
          os = "linux";
          arch = "386";
        };

        cachedOCIImageAlpineAmd64 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-amd64";
          imageDigest = "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-MyuP5ZMP0SbCsyAOxwJnzdjbOPCeoaQmQTWCSFNDEjU=";
          os = "linux";
          arch = "amd64";
        };

        # docker manifest inspect busybox:1.36.1-glibc
        cachedOCIImageAlpineMips64el = prev.dockerTools.pullImage {
          finalImageTag = "1.36.1-glibc-mips64le";
          imageDigest = "sha256:5d4fe778cdb7f30d46b87cd1c3cb8ab9b4facea1701838363e27f8f6a61ee611";
          imageName = "busybox";
          name = "busybox";
          sha256 = "sha256-O+sQtBZd4MWT+5DLatVQXfVmcT0R88BZMQfXpfnGoag=";
          os = "linux";
          arch = "mips64le";
        };

        #
        cachedOCIImageTonistiigiBinfmt = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:66e11bea77a5ea9d6f0fe79b57cd2b189b5d15b93a2bdb925be22949232e4e55";
          imageName = "tonistiigi/binfmt";
          name = "tonistiigi/binfmt";
          sha256 = "sha256-Fax1Xf7OUch5hnFaW4SarIfkHJPNyoNoQfhsCw6f2NM=";
        };

        testBinfmtMany = prev.testers.runNixOSTest {
          name = "test-binfmt-many";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;

              config.boot.binfmt.emulatedSystems = [
                "aarch64-linux"
                "armv7l-linux"
                "i686-linux"
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
            };

          globalTimeout = 2 * 60;

          testScript = { nodes, ... }: ''
            start_all()
            machine.wait_for_unit("default.target")

            machine.succeed("docker load <${final.cachedOCIImageAlpineAmd64}")
            machine.succeed("docker load <${final.cachedOCIImageAlpineArm32v6}")
            machine.succeed("docker load <${final.cachedOCIImageAlpineArm32v7}")
            machine.succeed("docker load <${final.cachedOCIImageAlpineArm64}")
            machine.succeed("docker load <${final.cachedOCIImageAlpineI386}")
            machine.succeed("docker load <${final.cachedOCIImageAlpineMips64el}")
            machine.succeed("docker load <${final.cachedOCIImageAlpinePpc64le}")
            machine.succeed("docker load <${final.cachedOCIImageAlpineRiscv64}")
            machine.succeed("docker load <${final.cachedOCIImageAlpineS390x}")

            print(machine.succeed("docker images"))

            with subtest("i386"):
                expected = 'x86_64 Linux' # TODO: Why i386 and i686 is x86_64? https://serverfault.com/a/610320
                result = machine.succeed("docker run --rm --platform linux/386 alpine:3.20.3-i386 uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("amd64"):
                expected = 'x86_64 Linux'
                result = machine.succeed("docker run --rm --platform linux/amd64 alpine:3.20.3-amd64 uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("arm32v6"):
                expected = 'armv7l Linux'
                result = machine.succeed("docker run --rm --platform linux/arm alpine:3.20.3-arm32v6 uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("arm32v7"):
                expected = 'armv7l Linux'
                result = machine.succeed("docker run --rm --platform linux/arm alpine:3.20.3-arm32v7 uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("arm64"):
                expected = 'aarch64 Linux'
                result = machine.succeed("docker run --rm --platform linux/arm64 alpine:3.20.3-arm64 uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("mips64le"):
                expected = 'mips64 GNU/Linux'
                result = machine.succeed("docker run --rm busybox:1.36.1-glibc-mips64le uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("ppc64le"):
                expected = 'ppc64le Linux'
                result = machine.succeed("docker run --rm --platform linux/ppc64le alpine:3.20.3-ppc64le uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("riscv64"):
                expected = 'riscv64 Linux'
                result = machine.succeed("docker run --rm --platform linux/riscv64 alpine:3.20.3-riscv64 uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"

            with subtest("s390x"):
                expected = 's390x Linux'
                result = machine.succeed("docker run --rm --platform linux/s390x alpine:3.20.3-s390x uname -a")
                assert expected in result, f"expected = {expected}, result = {result}"
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

                    docker load <"${final.cachedOCIImageTonistiigiBinfmt}"

                    docker load <"${final.cachedOCIImageAlpineAmd64}"
                    docker load <"${final.cachedOCIImageAlpineArm32v6}"
                    docker load <"${final.cachedOCIImageAlpineArm32v7}"
                    docker load <"${final.cachedOCIImageAlpineArm64}"
                    docker load <"${final.cachedOCIImageAlpineI386}"
                    docker load <"${final.cachedOCIImageAlpineMips64el}"
                    docker load <"${final.cachedOCIImageAlpinePpc64le}"
                    docker load <"${final.cachedOCIImageAlpineRiscv64}"
                    docker load <"${final.cachedOCIImageAlpineS390x}"
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
        };

      }
    )
  );
}
