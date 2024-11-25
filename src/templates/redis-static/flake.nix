{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ecbc1ca8ffd6aea8372ad16be9ebbb39889e55b6' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/c1dfcf08411b08f6b8615f7d8971a2bfa81d5e8a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/c1dfcf08411b08f6b8615f7d8971a2bfa81d5e8a'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        redisStatic = prev.pkgsStatic.redis.overrideAttrs (oldAttrs:
          {
            preBuild = (oldAttrs.preBuild or "") + ''
              # ls -alh src
              sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' src/config.c
              # exit 1
            '';
          }
        );

        OCIImageStaticRedisCLI =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "redis-cli-static";
            tag = "latest";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc
              mkdir -pv ./data

              cp -aTv ${final.redisStatic}/bin/redis-cli ./bin/redis-cli

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            config.Entrypoint = [ "/bin/redis-cli" ];
            config.Cmd = [ "PING" ];
            config.Env = [ "PATH=/bin" ];
            config.ExposedPorts = { "6379/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.User = "${user}:${group}";
            config.Volumes = { "/data" = { }; };
            config.WorkingDir = "/data";
          };

        /*
          docker run -p 6379:6379 --name=container-redis -d --rm redis:7.2.5-alpine3.20 sh -c 'redis-server'
          docker run --net=host --rm redis:7.2.5-alpine3.20 sh -c 'redis-cli PING'
          timeout 1 docker stop container-redis && echo $?
          docker run --net=host --rm redis:7.2.5-alpine3.20 sh -c 'redis-cli PING'

          docker run -p 6379:6379 --name=container-redis-server -d --rm redis-server-static:latest
          docker run --net=host --rm redis-cli-static:latest
          timeout 1 docker stop container-redis-server
          docker run --net=host --rm redis-cli-static:latest
        */
        OCIImageStaticRedisServer =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "redis-server-static";
            tag = "latest";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m1777 ./tmp
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc
              mkdir -pv ./data

              cp -aTv ${final.redisStatic}/bin/redis-server ./bin/redis-server

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./data ./bin
            '';

            # config.Entrypoint = [ "/bin/gosu" "${user}" ];
            # config.Entrypoint = [ "/bin/gosu" ];
            config.Cmd = [ "/bin/redis-server" ];
            # config.Entrypoint = [ "/bin/redis-server" ];
            # config.Entrypoint = [ "redis-server" ];
            # config.Entrypoint = [ "busybox" ];
            # config.Cmd = [ "sh" ];
            # config.Env = [ "PATH=/bin" ];
            # config.Cmd = [ "redis-server" ];
            config.ExposedPorts = { "6379/tcp" = { }; }; # "<port>/<tcp|udp>": {}
            config.User = "${user}:${group}";
            # config.User = "root:root}";
            config.Volumes = { "/data" = { }; };
            config.WorkingDir = "/data";
          };

        testRedisStatic = prev.testers.runNixOSTest {
          name = "test-redis-static";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
            };

          globalTimeout = 2 * 60;

          testScript = { nodes, ... }: ''
            start_all()
            machine.wait_for_unit("default.target")

            machine.succeed("docker load <${final.OCIImageStaticRedisCLI}")
            machine.succeed("docker load <${final.OCIImageStaticRedisServer}")
            print(machine.succeed("docker images"))

            expected = 'sha256:9adc771a01a438e00aefd527cacf5071c3c8f40d81fb989a693501a834eee2d3 3.44MB'
            result = machine.succeed("docker images redis-server-static:latest --no-trunc --format '{{.ID}} {{.Size}}'")

            expected = 'sha256:c74d221d3ab471a90f236974cb01644e68e2cd5978160a6a267b4150fd44be5a 1.36MB'
            result = machine.succeed("docker images redis-server-static:latest --no-trunc --format '{{.ID}} {{.Size}}'")

            machine.succeed("docker run --name=container-redis-server -d --rm -p=6379:6379 redis-server-static:latest")
            machine.wait_for_open_port(6379)
            machine.succeed("docker run --net=host --rm redis-cli-static:latest | grep PONG")

            machine.succeed("timeout 1 docker stop container-redis-server")

            expected = 'Could not connect to Redis at 127.0.0.1:6379: Connection refuse'
            result = machine.fail("docker run --net=host -it --rm redis-cli-static:latest")
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

                    docker load <"${final.OCIImageStaticRedisCLI}"
                    docker load <"${final.OCIImageStaticRedisServer}"
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
                    pkgsStatic.redis
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
            testRedisStatic
            ;

          default = pkgs.testRedisStatic;
        };

        packages.myvm = pkgs.myvm;
        packages.automatic-vm = pkgs.automatic-vm;

        packages.redisStatic = pkgs.redisStatic;

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            redisStatic
            testRedisStatic
            automatic-vm
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
