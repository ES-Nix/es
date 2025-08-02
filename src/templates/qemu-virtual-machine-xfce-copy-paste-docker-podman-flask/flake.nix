{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/8a18db56dd62edd26458a87e4d335b7df84c3f3f'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/b9a98080beff0903a5e5fe431f42cde1e3e50d6b'    
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

  outputs = { self, nixpkgs, flake-utils, poetry2nix, }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      poetry2nix.overlays.default

      (final: prev: {
        foo-bar = prev.hello;

        myapp = prev.poetry2nix.mkPoetryApplication {
          src = prev.poetry2nix.cleanPythonSources { src = ./.; };
          projectDir = ./.;
          # python = prev.python3Minimal;

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

        /*
          xhost + || nix run nixpkgs#xorg.xhost -- +

          podman run --env="DISPLAY=${DISPLAY:-:0.0}" --interactive=true --mount=type=tmpfs,destination=/var \
          --privileged=false --rm=true --tty=true --user=1234 --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
          localhost/static-xorg-xclock:latest

          podman run --interactive=true --name=container-xclock --rm=true --tty=true \
          localhost/static-xorg-xclock:latest bash

          podman exec -it -u 0 container-xclock bash
        */
        cachedOCIImageStaticXorgXclock = prev.dockerTools.buildLayeredImage {
          # https://github.com/NixOS/nixpkgs/issues/176081
          name = "static-xorg-xclock";
          tag = "latest";
          config = {

            contents = with prev; [
              dockerTools.binSh
              dockerTools.caCertificates
              dockerTools.usrBinEnv
              bashInteractive
              coreutils
              hello
              xorg.xclock
              (dockerTools.fakeNss.override {
                extraPasswdLines = [ "newuser:x:9001:9001:new user:/home/newuser:/bin/sh" ];
                extraGroupLines = [ "newuser:x:9001:" ];
              })

              (runCommand "tmp-dir" { } ''
                mkdir -p $out/tmp
                mkdir -p $out/var
                mkdir -p $out/home/newuser
              '')
            ];

            fakeRootCommands = ''
              chmod 1777 tmp
              chmod 1777 var
              chown -v newuser:newuser home/newuser
            '';

            Env = [
              # https://access.redhat.com/solutions/409033
              # https://github.com/nix-community/home-manager/issues/703#issuecomment-489470035
              # https://bbs.archlinux.org/viewtopic.php?pid=1805678#p1805678
              "LC_ALL=C"
              "DISPLAY=:0"
              "HOME=/tmp"
              # "PATH=/bin"
            ];

            # Entrypoint = [ "/bin/sh" "-c" ];
            Cmd = [ "bash" ];

            User = "newuser";
            WorkingDir = "/home/newuser";
            # Tty = true;
          };
        };

        /*
          docker run --interactive=true --name=container-base-env1 --rm=true --tty=true base-env1:latest

        docker \
        run \
        --device=/dev/kvm:rw \
        --interactive=true \
        --rm=true \
        --tty=true \
        base-env1:latest \
        sh

        --mount=type=tmpfs,tmpfs-size=2G,destination=/tmp \
        --workdir=/tmp \

        */
        cachedOCIImageBase1 = prev.dockerTools.buildImage {
          name = "base-env1";
          tag = "latest";

          copyToRoot = [
            prev.bashInteractive
            prev.coreutils

            # final.myvmNoGRaphicalPkg

            (prev.runCommand "cretes-tmp-home" { } ''
              mkdir -p $out/tmp
              mkdir -p $out/home/nobody
            '')

            prev.dockerTools.fakeNss
            prev.dockerTools.usrBinEnv
            prev.dockerTools.binSh
            prev.dockerTools.caCertificates
            prev.dockerTools.fakeNss
          ];

          runAsRoot = ''
            chmod 1777 tmp
            chown -v nobody: home/nobody
          '';

          config = {

            Cmd = [ "/bin/sh" ];

            Env = [
              "PATH=/bin"
            ];
            User = "nobody";
          };
        };


        /*
        docker \
        run \
        --device=/dev/kvm:rw \
        --interactive=true \
        --rm=true \
        --tty=true \
        layered-image-with-fake-root-commands:latest \
        sh
        */

        fakeNss = prev.fakeNss.override {
          extraPasswdLines = [ "newuser:x:9001:9001:new user:/home/newuser:/bin/sh" ];
          extraGroupLines = [ "newuser:x:9001:" ];
        };

        cachedOCIImageBase2 = prev.dockerTools.buildLayeredImage {
          name = "layered-image-with-fake-root-commands";
          tag = "latest";
          contents = [
            prev.pkgsStatic.busybox

            # final.myvmNoGRaphicalPkg
            # prev.openssh

            (prev.runCommand "cretes-tmp-home" { } ''
              mkdir -p $out/tmp
              mkdir -p $out/home/newuser
            '')

            prev.dockerTools.fakeNss
            prev.dockerTools.usrBinEnv
            prev.dockerTools.binSh
            prev.dockerTools.caCertificates
            final.dockerTools.fakeNss

          ];

          enableFakechroot = true;
          fakeRootCommands = ''
            chmod 1777 tmp
            chown -v newuser: home/newuser tmp
          '';

          config = {
            Cmd = [ "/bin/sh" ];
            WorkingDir = "/home/newuser";
            Env = [
              "PATH=/bin"
              "HOME=/home/newuser"
            ];
            User = "newuser";
          };
        };

        /*
           docker pull python:3.11.9-slim-bullseye
           docker pull python:3.11.9-alpine3.20

          cat > Containerfile << 'EOF'
          FROM python:3.11.9-alpine3.20
          ENV PYTHONDONTWRITEBYTECODE=1
          ENV PYTHONUNBUFFERED=1
          RUN pip install --no-cache-dir mmh3
          EOF

          docker \
          build \
          --file Containerfile \
          --tag python-3.11.9-alpine3.20-mmh3 \
          .

           docker images

           docker run --rm -ti stripped:nix python -c 'import magic'

           docker run --rm -ti stripped:nix python -c 'import numpy as np; print(np.arange(24).reshape(2, 3, 4))'
           docker run --rm -ti stripped:nix python -c 'import numpy as np; np.show_config(); print(np.__version__)'
           docker run --rm -ti stripped:nix python -c \
           'import mmh3; assert mmh3.hash128(bytes(123)) == 126000048256919600573431412872524959502'

           du -shc $(nix-store -qR $(nix build --no-link --print-build-logs --print-out-paths \
           'github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8#python3Minimal' ))

           nix eval --json nixpkgs#python3Minimal.override.__functionArgs | jq

            (let
                self = (prev.pkgsStatic.python3Minimal.override {
                  inherit self;
                  includeSiteCustomize = true;
                });
              in self.withPackages (p: [ p.magic ]))


        python3Static = prev.pkgsStatic.python3;
        # python3Static = prev.pkgsStatic.python3Minimal;
        # python3Static = prev.pkgsStatic.python3Packages.python;
        # python3 = prev.pkgsStatic.python3Packages.python;
        # python3Packages = final.python3Custom.pkgs;
        python3Custom =
          let
            pyCustom = (final.python3.override {
              self = final.python3Static;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (p: with p; [ magic ]);

        */
        python3MinimalMuslWithMagic =
          let
            pyCustom = (prev.pkgsMusl.python3Minimal.override {
              self = pyCustom;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (p: [ p.magic ]);

        strippedNix = prev.dockerTools.buildImage {
          name = "stripped";
          tag = "nix";
          created = "now";
          copyToRoot = [
            final.python3MinimalMuslWithMagic
          ];
          config = {
            cmd = [ "python" ];
          };
        };


        python3MinimalMuslWithMmh3 =
          let
            pyCustom = (prev.pkgsMusl.python3Minimal.override {
              self = pyCustom;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (p: [ p.mmh3 ]);

        OCIImagePython3MinimalMuslWithMmh3 = prev.dockerTools.buildImage {
          name = "python3-mmh3";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.python3MinimalMuslWithMagic
          ];
          config = {
            cmd = [ "python" ];
          };
        };


        # docker run --rm -ti --publish=6789:6789 python3-http-server:0.0.1
        python3FHttpServerOCIImage = prev.dockerTools.buildImage {
          name = "python3-http-server";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            prev.pkgsMusl.python3Minimal
            # prev.pkgsMusl.pkgsStatic.python3Minimal
            # prev.pkgsStatic.pkgsMusl.python3Minimal
          ];
          config = {
            Cmd = [ "python" "-m" "http.server" "6789" ];
          };
        };

        python3WithFlask =
          let
            pyCustom = (prev.python3.override {
              self = pyCustom;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (pyPkgs: with pyPkgs ; [ flask ]);

        # https://flask.palletsprojects.com/en/2.0.x/quickstart/#a-minimal-application
        helloFlaskMinimal = prev.writeTextDir "hello.py" "${ builtins.readFile ./hello.py}";

        # docker run --rm -ti --publish=5001:5001 python3-flask:0.0.1
        python3FlaskOCIImage = prev.dockerTools.buildImage {
          name = "python3-flask";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.python3WithFlask
          ];
          config = {
            Cmd = [ "python" "-m" "flask" "run" "--host=0.0.0.0" "--port=5001" "--debugger" ];
            Env = [
              # https://flask.palletsprojects.com/en/3.0.x/cli/#application-discovery
              "FLASK_APP=${final.helloFlaskMinimal}/hello.py"
            ];
          };
        };

        python3WithFlaskRedis =
          let
            pyCustom = (prev.python3.override {
              self = pyCustom;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (pyPkgs: with pyPkgs ; [ flask redis ]);

        #
        helloFlaskRedis = prev.writeTextDir "hello-couter-redis.py" "${ builtins.readFile ./hello-couter-redis.py}";

        # docker run --rm -ti --publish=5002:5002 python3-flask-redis:0.0.1
        python3FlaskRedisOCIImage = prev.dockerTools.buildImage {
          name = "python3-flask-redis";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.python3WithFlaskRedis
          ];
          config = {
            Cmd = [ "python" "-m" "flask" "run" "--host=0.0.0.0" "--port=5002" "--debugger" ];
            Env = [
              "FLASK_APP=${final.helloFlaskRedis}/hello-couter-redis.py"
            ];
          };
        };


        python3FlaskOCIImage2 = prev.dockerTools.buildImage {
          name = "python3-flask";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.python3WithFlask
            final.helloFlaskMinimal
          ];
          config = {
            Cmd = [ "python" "-m" "flask" "run" "--host=0.0.0.0" "--port=5001" "--debug" ];
            Env = [
              "FLASK_APP=${final.helloFlaskMinimal}"
            ];
          };
        };

        python3WithOpentelemetryInstrumentationFastapi =
          let
            pyCustom = (prev.python3.override {
              self = pyCustom;
              includeSiteCustomize = true;
            });
          in
          pyCustom.withPackages (pyPkgs: with pyPkgs ; [ fastapi uvicorn opentelemetry-instrumentation-fastapi ]);

        #
        opentelemetryInstrumentationFastapi = prev.writeTextDir "opentelemetry-instrumentation-fastapi.py"
          "${ builtins.readFile ./opentelemetry-instrumentation-fastapi.py}";

        # docker run --rm -ti --publish=8000:8000 python3-opentelemetry-instrumentation-fastapi:0.0.1
        python3WithOpentelemetryInstrumentationFastapiOCIImage = prev.dockerTools.buildImage {
          name = "python3-opentelemetry-instrumentation-fastapi";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.python3WithOpentelemetryInstrumentationFastapi
          ];
          config = {
            Cmd = [ "uvicorn" "opentelemetry-instrumentation-fastapi:app" "--host" "0.0.0.0" "--port" "8000" ];
            WorkingDir = "${final.opentelemetryInstrumentationFastapi}";
          };
        };


        # docker run --interactive=true --rm=true --tty=true static-nix-cacert run nixpkgs#hello
        cachedOCIImageStaticNixCacert =
          let
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "static-nix-cacert";
            tag = "latest";
            includeStorePaths = false;

            # cp -aTrv ${prev.pkgsStatic.busybox-sandbox-shell}/bin/busybox ./bin/sh
            extraCommands = ''

              mkdir -pv -m1777 ./tmp
              mkdir -pv ./etc/ssl/certs
              mkdir -pv -m0700 ./bin ./home/${user}/.local/bin
              mkdir -pv -m1777 ./home/${user}/tmp
              mkdir -pv -m1735 ./nix/var/nix

              cp -aTrv ${prev.pkgsStatic.busybox}/bin/ ./bin/
              cp -aTrv ${prev.pkgsStatic.nix}/bin/ ./home/${user}/.local/bin/
              cp -v ${prev.cacert}/etc/ssl/certs/ca-bundle.crt ./etc/ssl/certs/

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./nix ./home/${user}/
            '';

            config.Entrypoint = [ "/home/${user}/.local/bin/nix" ];
            config.User = "${user}:${group}";
            config.Content = [ prev.python3Minimal ];
            # config.Cmd = [ "nix" ];
            config.WorkingDir = "/home/${user}";
            config.Env = [
              "PATH=/bin:/home/${user}/.local/bin"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "NIX_CONFIG=extra-experimental-features = nix-command flakes"
              "TMPDIR=/home/${user}"
            ];
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


                #                systemd.user.services.podman-custom-bootstrap-1 = {
                #                  description = "Podman Custom Bootstrap 1";
                #                  wantedBy = [ "default.target" ];
                #                  after = [ "podman.service" ];
                #                  path = with pkgs; [ "/run/wrappers" podman ];
                #                  script = ''
                #                    echo "Loading OCI Image in podman..."
                #                    podman load <"${pkgs.myappOCIImage}"
                #
                #                    podman load <"${pkgs.cachedOCIImageStaticXorgXclock}"
                #                    podman load <"${pkgs.cachedOCIImageBase1}"
                #
                #                    # "''${pkgs.cachedOCIImageBase1}" | podman load
                #                    # "''${pkgs.cachedOCIImageStaticXorgXclock}" | podman load
                #
                #                    podman load <"${pkgs.cachedOCIImageStaticRedisServerMinimal}"
                #                    podman load <"${pkgs.cachedOCIImageStaticRedisCLIMinimal}"
                #                    podman load <"${pkgs.python3FlaskRedisOCIImage}"
                #                    podman load <"${pkgs.cachedOCIImageStaticMemcachedMinimal}"
                #                  '';
                #                  serviceConfig = {
                #                    Type = "oneshot";
                #                  };
                #                };

                /*

                journalctl --unit docker-custom-bootstrap-1.service -b -f

                    docker load <"${pkgs.myappOCIImage}"

                    docker load <"${pkgs.cachedOCIImageStaticNixCacert}"
                    docker load <"${pkgs.cachedOCIImageStaticXorgXclock}"
                    docker load <"${pkgs.cachedOCIImageBase1}"
                    docker load <"${pkgs.cachedOCIImageBase2}"

                */
                systemd.services.docker-custom-bootstrap-1 = {
                  description = "Docker Custom Bootstrap 1";
                  wantedBy = [ "multi-user.target" ];
                  after = [ "docker.service" ];
                  path = with pkgs; [ docker ];
                  script = ''
                    # set -x
                    echo "Loading OCI Image in docker..."

                    # docker load <"''${pkgs.strippedNix}"
                    # docker load <"''${pkgs.python3FlaskOCIImage}"


                    # "''${pkgs.cachedOCIImageBase1}" | docker load
                    # "''${pkgs.cachedOCIImageStaticXorgXclock}" | docker load

                    # docker load <"''${pkgs.cachedOCIImageStaticRedisServerMinimal}"
                    # docker load <"''${pkgs.cachedOCIImageStaticRedisCLIMinimal}"
                    # docker load <"''${pkgs.python3FlaskRedisOCIImage}"
                    docker load <"${pkgs.python3WithOpentelemetryInstrumentationFastapiOCIImage}"

                    # docker load <"''${pkgs.cachedOCIImageStaticMemcachedMinimal}"

                    # docker load <"''${pkgs.vmNoGraphicalOCIImage}"
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

                system.stateVersion = "25.05";
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


        myvmNoGRaphicalPkg = final.nixos-vm-no-graphical.config.system.build.vm;
        nixos-vm-no-graphical = nixpkgs.lib.nixosSystem {
          system = prev.system;
          modules = [
            (

              { lib, config, pkgs, ... }:
              let
                nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w";
              in
              {
                # Internationalisation options
                # i18n.defaultLocale = "en_US.UTF-8";
                i18n.defaultLocale = "pt_BR.UTF-8";
                console.keyMap = "br-abnt2";

                virtualisation.vmVariant = {
                  virtualisation.useNixStoreImage = true;
                  virtualisation.writableStore = true; # TODO
                  virtualisation.docker.enable = true;

                  virtualisation.memorySize = 1024 * 3; # Use maximum of RAM MiB memory.
                  virtualisation.diskSize = 1024 * 16; # Use maximum of hard disk MiB memory.
                  virtualisation.cores = 4; # Number of cores.

                  # https://discourse.nixos.org/t/nixpkgs-support-for-linux-builders-running-on-macos/24313/2
                  virtualisation.forwardPorts = [
                    {
                      from = "host";
                      # host.address = "127.0.0.1";
                      host.port = 10022;
                      # guest.address = "34.74.203.201";
                      guest.port = 10022;
                    }
                  ];
                  # https://lists.gnu.org/archive/html/qemu-discuss/2020-05/msg00060.html
                  virtualisation.qemu.options = [
                    "-display none "
                    "-daemonize"
                    "-pidfile pidfile.txt"
                  ];

                };

                users.users.root = {
                  password = "root";
                  # initialPassword = "root";
                  openssh.authorizedKeys.keyFiles = [
                    "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                  ];
                };

                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;

                security.sudo.wheelNeedsPassword = false;
                users.users.nixuser = {
                  isSystemUser = true;
                  password = "121";
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "kvm"
                    "libvirtd"
                    "qemu-libvirtd"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    bashInteractive
                    coreutils
                    direnv
                    file
                    gnumake
                    openssh
                    which
                  ];
                  shell = pkgs.bashInteractive;
                  uid = 1234;
                  autoSubUidGidRange = true;

                  openssh.authorizedKeys.keyFiles = [
                    "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                  ];

                  openssh.authorizedKeys.keys = [
                    "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w"
                  ];
                };

                # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
                services.openssh = {
                  allowSFTP = true;
                  settings.KbdInteractiveAuthentication = false;
                  enable = true;
                  settings.X11Forwarding = false;
                  settings.PasswordAuthentication = false;
                  settings.PermitRootLogin = "yes";
                  ports = [ 10022 ];
                  authorizedKeysFiles = [
                    "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                  ];
                };

                # X configuration
                services.xserver.enable = true;
                services.xserver.xkb.layout = "br";

                # services.xserver.displayManager.autoLogin.user = "nixuser";

                # Enable ssh
                # journalctl -u sshd -o json-pretty
                services.sshd.enable = true;

                nixpkgs.config.allowUnfree = true;
                boot.readOnlyNixStore = true; # TODO: hardening
                nix = {
                  extraOptions = "experimental-features = nix-command flakes";
                  package = pkgs.nix;
                  registry.nixpkgs.flake = nixpkgs;
                  nixPath = [ "nixpkgs=${pkgs.path}" ];
                };
                environment.etc."channels/nixpkgs".source = "${pkgs.path}";

                environment.systemPackages = with pkgs; [
                ];

                system.stateVersion = "25.05";
              }
            )
          ];
        };



        vmNoGraphicalOCIImage =
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

              (
                prev.stdenv.mkDerivation {
                  name = "tmp";
                  phases = [ "installPhase" "fixupPhase" ];

                  installPhase = ''
                    mkdir -p $out/tmp
                    mkdir -p $out/home/${user}
                  '';
                }
              )
            ];
          in
          prev.dockerTools.buildLayeredImage {
            name = "vm-no-graphical-oci-image";
            tag = "0.0.1";
            contents = [
              prev.busybox
              prev.openssh
              final.myvmNoGRaphicalPkg
            ]
            ++
            (nonRootShadowSetup { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; })
            ;

            config = {
              Cmd = [ "sh" ];
              # Cmd = [ "${prev.lib.getExe final.myvmNoGRaphicalPkg}" ];
            };
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
          overlays = [ self.overlays.default ];
        };
      in
      rec {
        packages = {
          inherit (pkgs)
            myapp
            myappOCIImage
            # python3Custom
            # python3MinimalWithMagic
            ;
        };
        packages.default = pkgs.myapp;

        packages.myvm = pkgs.myvm;
        packages.automatic-vm = pkgs.automatic-vm;

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };

        apps.NixOSVMNoGraphical = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.myvmNoGRaphicalPkg}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          testAutomatic-vm = pkgs.automatic-vm;
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
            globalTimeout = 60;

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
          buildInputs = [
            foo-bar
            myapp
            # poetry
            # python3Custom
          ];

          shellHook = ''
            echo ''${helloFlaskMinimal}
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

        # nixosConfigurations.vm = pkgs.nixos-vm;
      }
    )
  );
  #  // {
  #    nixosConfigurations.vm = pkgs.nixos-vm;
  #  };
}
