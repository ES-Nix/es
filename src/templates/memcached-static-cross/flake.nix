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

        staticMemcachedServerArm64 = prev.pkgsCross.aarch64-multiplatform-musl.pkgsStatic.memcached;
        #staticMemcachedServerArm64 = (prev.pkgsCross.aarch64-multiplatform-musl.pkgsStatic.memcached.override {
        #  cyrus_sasl = prev.pkgsCross.aarch64-multiplatform-musl.pkgsStatic.cyrus_sasl;
        #  libevent = prev.pkgsCross.aarch64-multiplatform-musl.pkgsStatic.libevent;
        #}).overrideAttrs (oldAttrs:
        #  {
        #    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ prev.autoPatchelfHook prev.cyrus_sasl.dev ];
        #    postInstall = (oldAttrs.postInstall or "") + ''
        #      ls -alh $out/bin
        #      file $out/bin/memcached
        #    '';
        #  }
        #);

        # staticMemcachedServerArm64 = (prev.pkgsCross.aarch64-multiplatform-musl.pkgsStatic.memcached.override {
        #  cyrus_sasl = prev.pkgsCross.aarch64-multiplatform-musl.pkgsStatic.cyrus_sasl;
        #  libevent = prev.pkgsCross.aarch64-multiplatform-musl.pkgsStatic.libevent;
        #}).overrideAttrs (oldAttrs:
        #  {
        #    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ prev.autoPatchelfHook prev.cyrus_sasl.dev ];
        #    postInstall = (oldAttrs.postInstall or "") + ''
        #      ls -alh $out/bin
        #      file $out/bin/memcached
        #    ''
        # + prev.lib.optionalString prev.stdenv.hostPlatform.isStatic ''
        #  rm -f $out/nix-support/propagated-build-inputs
        #'';
        #  }
        #);

        staticMemcachedServerGnu32 = prev.pkgsCross.gnu32.pkgsStatic.memcached;
        staticMemcachedServerGnu64 = prev.pkgsCross.gnu64.pkgsStatic.memcached;
        staticMemcachedServerMips64el = prev.pkgsCross.mips64el-linux-gnuabi64.pkgsStatic.memcached;
        staticMemcachedServerPpc64 = prev.pkgsCross.ppc64.pkgsStatic.memcached;
        staticMemcachedServerRiscv64 = prev.pkgsCross.riscv64.pkgsStatic.memcached;
        staticMemcachedServerS390x = prev.pkgsCross.s390x.pkgsStatic.memcached;
        staticMemcachedServerX86_64 = prev.pkgsStatic.memcached;

        OCIImageStaticMemcachedServerMips64el =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-mips64el-linux-gnuabi64";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerMips64el}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        OCIImageStaticMemcachedServerX86_64 =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-x86_64";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerX86_64}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        OCIImageStaticMemcachedServerArm64 =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-arm64";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerArm64}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        OCIImageStaticMemcachedServerS390x =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-s390x";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerS390x}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        OCIImageStaticMemcachedServerRiscv64 =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-riscv64";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerRiscv64}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        OCIImageStaticMemcachedServerPpc64 =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-ppc64";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerPpc64}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        OCIImageStaticMemcachedServerGnu32 =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-gnu32";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerGnu32}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        OCIImageStaticMemcachedServerGnu64 =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "memcached";
            tag = "static-gnu64";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc ./data

              cp -aTv ${final.staticMemcachedServerGnu64}/bin/memcached ./bin/memcached

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/memcached" ];

            config.User = "${user}:${group}";
            config.WorkingDir = "/data";
            config.ExposedPorts = { "11211/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.Volumes = { "/data" = { }; };
            config.Env = [ "PATH=/bin" ];
          };

        testBinfmtMany = prev.testers.runNixOSTest {
          name = "test-binfmt-many";

          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.diskSize = 1024 * 6;

              config.virtualisation.docker.enable = true;
              config.environment.systemPackages = with pkgs; [
                file
                inetutils
              ];

              config.boot.binfmt.emulatedSystems = [
                "aarch64-linux"
                # "armv6l-linux" # TODO: why arm32v5, arm32v6 and arm32v7 work?
                "armv7l-linux" # TODO: why arm32v5, arm32v6 and arm32v7 work?
                # "i386-linux"
                # "i686-linux"
                "mips64el-linux"
                "powerpc64-linux"
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
                powerpc64-linux = {
                  interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-ppc64";
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

            # TODO: It is dynamically linked not statically statically
            expected = 'ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerArm64} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = 'ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked,'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerGnu32} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = 'ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked,'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerGnu64} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = 'ELF 64-bit LSB executable, MIPS, MIPS64 rel2 version 1 (SYSV), statically linked,'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerMips64el} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = 'ELF 64-bit MSB executable, 64-bit PowerPC or cisco 7500, OpenPOWER ELF V2 ABI, version 1 (SYSV), statically linked,'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerPpc64} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = 'ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), statically linked,'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerRiscv64} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = 'ELF 64-bit MSB executable, IBM S/390, version 1 (SYSV), statically linked,'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerS390x} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = 'ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked,'
            result = machine.succeed("! ldd ${final.lib.getExe final.staticMemcachedServerX86_64} && file $_")
            assert expected in result, f"expected = {expected}, result = {result}"


            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerArm64}")
            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerGnu32}")
            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerGnu64}")
            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerMips64el}")
            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerPpc64}")
            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerRiscv64}")
            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerS390x}")
            machine.succeed("docker load <${final.OCIImageStaticMemcachedServerX86_64}")

            print(machine.succeed("docker images"))

            #TODO: it is broken!
            #with subtest("Arm64"):
            #    machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-arm64")
            #    machine.wait_for_open_port(11211)
            #
            #    expected = 'STAT pointer_size 64'
            #    result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
            #    assert expected in result, f"expected = {expected}, result = {result}"
            #
            #    machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
            #    machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("mips64el-linux-gnuabi64"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-mips64el-linux-gnuabi64")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 64'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("x86_64"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-x86_64")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 64'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("gnu32"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-gnu32")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 32'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("gnu64"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-gnu64")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 64'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("riscv64"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-riscv64")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 64'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("amd64"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-x86_64")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 64'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("s390x"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-s390x")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 64'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")

            with subtest("ppc64"):
                machine.succeed("docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-ppc64")
                machine.wait_for_open_port(11211)

                expected = 'STAT pointer_size 64'
                result = machine.succeed("echo stats | nc -vn -w 1 127.0.0.1 11211")
                assert expected in result, f"expected = {expected}, result = {result}"

                machine.succeed("echo quit | timeout --signal=INT 1 telnet 127.0.0.1 11211")
                machine.succeed("timeout 2 docker stop container-memcached")
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

                  powerpc64-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-ppc64";
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
                  "powerpc64-linux"
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

                    docker load <"${final.OCIImageStaticMemcachedServerArm64}"
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

                    # staticMemcachedServerPpc64
                    staticMemcachedServerArm64
                    pkgsCross.ppc64.hello
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
            staticMemcachedServerArm64
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
            testBinfmtMany
            # automatic-vm
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [

          ];
        };

      }
    )
  );
}
