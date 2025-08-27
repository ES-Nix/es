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
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

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

        helloAarch64Multiplatform = prev.pkgsCross.aarch64-multiplatform.hello;
        helloArmv7lHfMultiplatform = prev.pkgsCross.armv7l-hf-multiplatform.hello;
        helloGnu32 = prev.pkgsCross.gnu32.hello;
        helloGnu64 = prev.pkgsCross.gnu64.hello;
        helloMingw32 = prev.pkgsCross.mingw32.hello;
        helloMingwW64 = prev.pkgsCross.mingwW64.hello;
        helloMips64elLinuxGnuabin32 = prev.pkgsCross.mips64el-linux-gnuabin32.hello;
        helloMips64elLinuxGnuabi64 = prev.pkgsCross.mips64el-linux-gnuabi64.hello;
        helloPpc64 = prev.pkgsCross.ppc64.hello;
        helloRaspberryPi = prev.pkgsCross.raspberryPi.hello;
        helloRiscv32 = prev.pkgsCross.riscv32.hello;
        helloRiscv64 = prev.pkgsCross.riscv64.hello;
        helloS390x = prev.pkgsCross.s390x.hello;


        testBinfmtMany = prev.testers.runNixOSTest {
          name = "test-binfmt-many";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.environment.systemPackages = with final; [
                binutils
                lsof
                file

                wine
                winetricks
                # helloAarch64Multiplatform
              ];

              config.boot.binfmt.emulatedSystems = [
                "aarch64-linux"
                # "armv6l-linux"
                "armv7l-linux"
                "i686-linux"
                "mips64el-linux"
                "mips64el-linuxabin32"
                "powerpc64-linux"
                "riscv32-linux"
                "riscv64-linux"
                "s390x-linux"
                # "x86_64-linux"
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
                mips64el-linuxabin32 = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-mipsn32el";
                  fixBinary = true;
                };
                mips64el-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-mips64el";
                  fixBinary = true;
                };
                powerpc64-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-ppc64";
                  fixBinary = true;
                };
                riscv32-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv32";
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
                # x86_64-linux = {
                #   interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-x86_64";
                #   fixBinary = true;
                # };
              };
            };

          globalTimeout = 2 * 60;

          testScript = { nodes, ... }:
            let
              helloAarch64MultiplatformExe = "${prev.lib.getExe final.helloAarch64Multiplatform}";
              helloArmv7lHfMultiplatformExe = "${prev.lib.getExe final.helloArmv7lHfMultiplatform}";
              helloRaspberryPiExe = "${prev.lib.getExe final.helloRaspberryPi}";
              helloRiscv32Exe = "${prev.lib.getExe final.helloRiscv32}";
              helloRiscv64Exe = "${prev.lib.getExe final.helloRiscv64}";
              helloS390xExe = "${prev.lib.getExe final.helloS390x}";
              helloPpc64Exe = "${prev.lib.getExe final.helloPpc64}";
              helloGnu32Exe = "${prev.lib.getExe final.helloGnu32}";
              helloGnu64Exe = "${prev.lib.getExe final.helloGnu64}";
              helloMingw32Exe = "${prev.lib.getExe final.helloMingw32}.exe";
              helloMingwW64Exe = "${prev.lib.getExe final.helloMingwW64}.exe";
              helloMips64elLinuxGnuabin32Exe = "${prev.lib.getExe final.helloMips64elLinuxGnuabin32}";
              helloMips64elLinuxGnuabi64Exe = "${prev.lib.getExe final.helloMips64elLinuxGnuabi64}";
            in
            ''
              start_all()
              machine.wait_for_unit("default.target")

              machine.succeed("type file")
              machine.succeed("type which")
              machine.succeed("type readlink")
              machine.succeed("type objdump")
              machine.succeed("type readelf")
              # machine.succeed("type hello")


              #
              with subtest("file"):
                  expected = 'ELF 64-bit LSB executable, MIPS, MIPS64 rel2 version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloMips64elLinuxGnuabi64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloMips64elLinuxGnuabi64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf64-little'
                  result = machine.succeed("objdump -a ${helloMips64elLinuxGnuabi64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloMips64elLinuxGnuabi64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 32-bit LSB executable, MIPS, N32 MIPS64 rel2 version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloMips64elLinuxGnuabin32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloMips64elLinuxGnuabin32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf32-little'
                  result = machine.succeed("objdump -a ${helloMips64elLinuxGnuabin32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloMips64elLinuxGnuabin32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("file"):
                  expected = '/bin/hello.exe: PE32+ executable for MS Windows 5.02 (console), x86-64 (stripped to external PDB), 9 sections'
                  result = machine.succeed("file ${helloMingwW64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf must fail"):
                  expected = """Error: Not an ELF file - it has the wrong magic bytes at the start"""
                  result = machine.fail("readelf -h ${helloMingwW64Exe} 2>&1")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format pei-x86-64'
                  result = machine.succeed("objdump -a ${helloMingwW64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can NOT execute binary"):
                  expected = 'cannot execute binary file: Exec format error'
                  result = machine.fail("${helloMingwW64Exe} 2>&1")
                  assert expected in result, f"expected = {expected}, result = {result}"

              # with subtest("can execute binary with wine"):
              #     expected = 'cannot execute binary file: Exec format error'
              #     result = machine.succeed("wine cmd.exe ${helloMingw32Exe}")
              #     assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'PE32 executable for MS Windows 4.00 (console), Intel i386 (stripped to external PDB), 7 sections'
                  result = machine.succeed("file ${helloMingw32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf must fail"):
                  expected = 'Error: Not an ELF file - it has the wrong magic bytes at the start'
                  result = machine.fail("readelf -h ${helloMingw32Exe} 2>&1")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format pei-i386'
                  result = machine.succeed("objdump -a ${helloMingw32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can NOT execute binary"):
                  expected = 'cannot execute binary file: Exec format error'
                  result = machine.fail("${helloMingw32Exe} 2>&1")
                  assert expected in result, f"expected = {expected}, result = {result}"

              # with subtest("can execute binary with wine"):
              #     # expected = 'cannot execute binary file: Exec format error'
              #     expected = '[Errno 9] Bad file descriptor'
              #     result = machine.succeed("wine cmd.exe ${helloMingw32Exe}")
              #     assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("arm64 file"):
                  expected = 'ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloAarch64MultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("arm64 readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloAarch64MultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("arm64 objdump"):
                  expected = 'file format elf64-little'
                  result = machine.succeed("objdump -a ${helloAarch64MultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("arm64 can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloAarch64MultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloArmv7lHfMultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloArmv7lHfMultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf32-little'
                  result = machine.succeed("objdump -a ${helloArmv7lHfMultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloArmv7lHfMultiplatformExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloRaspberryPiExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloRaspberryPiExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf32-little'
                  result = machine.succeed("objdump -a ${helloRaspberryPiExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloRaspberryPiExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 32-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloRiscv32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloRiscv32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf32-little'
                  result = machine.succeed("objdump -a ${helloRiscv32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloRiscv32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloRiscv64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloRiscv64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf64-little'
                  result = machine.succeed("objdump -a ${helloRiscv64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloRiscv64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 64-bit MSB executable, IBM S/390, version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloS390xExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, big endian"""
                  result = machine.succeed("readelf -h ${helloS390xExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf64-big'
                  result = machine.succeed("objdump -a ${helloS390xExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloS390xExe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 64-bit MSB executable, 64-bit PowerPC or cisco 7500, OpenPOWER ELF V2 ABI, version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloPpc64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, big endian"""
                  result = machine.succeed("readelf -h ${helloPpc64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf64-big'
                  result = machine.succeed("objdump -a ${helloPpc64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloPpc64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 32-bit LSB executable, Intel i386, version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloGnu32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloGnu32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf32-i386'
                  result = machine.succeed("objdump -a ${helloGnu32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloGnu32Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              #
              with subtest("file"):
                  expected = 'ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter'
                  result = machine.succeed("file ${helloGnu64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("readelf"):
                  expected = """2's complement, little endian"""
                  result = machine.succeed("readelf -h ${helloGnu64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("objdump"):
                  expected = 'file format elf64-x86-64'
                  result = machine.succeed("objdump -a ${helloGnu64Exe}")
                  assert expected in result, f"expected = {expected}, result = {result}"

              with subtest("can execute binary"):
                  expected = 'Hello, world!'
                  result = machine.succeed("${helloGnu64Exe}")
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
            myvm
            testBinfmtMany
            automatic-vm
            ;
          default = pkgs.testBinfmtMany;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
          meta.description = "Run the NixOS VM";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            helloAarch64Multiplatform
            helloArmv7lHfMultiplatform
            helloGnu32
            helloGnu64
            helloMingw32
            helloMingwW64
            helloMips64elLinuxGnuabin32
            helloMips64elLinuxGnuabi64
            helloPpc64
            helloRaspberryPi
            helloRiscv32
            helloRiscv64
            helloS390x

            myvm
            testBinfmtMany
            automatic-vm
            ;
          default = pkgs.testBinfmtMany;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
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
