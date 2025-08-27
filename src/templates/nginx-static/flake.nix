{
  description = "An OCI Image with a statically linked nginx, and a NixOS VM to test it";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/78b848881f3b58b3c04c005a7999800d013fa9b7' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'


    fe866c653c24adf1520628236d4e70bbb2fdd949
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'


    # pkgsStatic.nginx works!
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/78b848881f3b58b3c04c005a7999800d013fa9b7' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'


    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/e2605d0744c2417b09f8bf850dfca42fcf537d34' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/11415c7ae8539d6292f2928317ee7a8410b28bb9' \
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
        # perl540 = prev.pkgsStatic.perl540;

        # nginxMusl = prev.pkgsMusl.nginx;
        # nginxStaticPerl356 = prev.nginx.override {
        #   perl = prev.pkgsStatic.perl536;
        # };
        #nginxStatic = prev.pkgsStatic.nginx.overrideAttrs (oldAttrs:
        #  {
        #    configureFlags = prev.lib.subtractLists [
        #      "--with-http_xslt_module"
        #      "--disable-shared"
        #      "--enable-static"
        #    ]
        #      oldAttrs.configureFlags;
        #  }
        #);
        nginxStatic = (prev.pkgsStatic.nginx.override {
          perl = prev.pkgsStatic.perl540;
        }).overrideAttrs (oldAttrs:
          {
            configureFlags = (prev.lib.subtractLists [
              "--with-http_xslt_module"
              "--disable-shared"
              "--enable-static"
            ]
              oldAttrs.configureFlags
            )
            ++
            [
              "--user=nginx"
              "--group=nginx"
            ];

            postInstall = (oldAttrs.postInstall or "") + ''
              ls -alh $out/bin
              # exit 1
            '';
          }
        );

        #nginxStatic = (prev.pkgsCross.aarch64-multiplatform.pkgsStatic.nginx.override {
        #  perl = prev.pkgsStatic.perl536;
        #}).overrideAttrs (oldAttrs:
        #  {
        #    configureFlags = (prev.lib.subtractLists [
        #      "--with-http_xslt_module"
        #      "--disable-shared"
        #      "--enable-static"
        #    ]
        #      oldAttrs.configureFlags
        #    )
        #    ++
        #    [
        #      "--user=nginx"
        #      "--group=nginx"
        #    ];
        #
        #    postInstall = (oldAttrs.postInstall or "") + ''
        #      ls -alh $out/bin
        #      # exit 1
        #    '';
        #  }
        #);

        OCIImageNginxStatic =
          let
            user = "nginx";
            group = "nginx";
            uid = "1234";
            gid = "9876";

            conf = {
              nginxWebRoot = prev.writeTextDir "index.html"
                ''
                  <html>
                    <body>
                      <center>
                      <marquee><h1>all ur PODZ is belong to ME</h1></marquee>
                      </center>
                    </body>
                  </html>\n
                '';

              nginxPort = "80";
              nginxConf = prev.writeTextDir "nginx.conf" ''
                daemon off;
                error_log /dev/stdout info;
                pid /dev/null;
                events {}
                http {
                  access_log /dev/stdout;
                  server {
                    listen ${conf.nginxPort};
                    index index.html;
                    location / {
                      root /etc/nginx;
                    }
                  }
                }
              '';
            };
          in
          prev.dockerTools.buildLayeredImage {
            name = "joshrosso";
            tag = "1.4";
            includeStorePaths = false;

            extraCommands = ''
              mkdir -pv -m0700 ./bin
              mkdir -pv ./etc/nginx

              cp -aTv ${final.nginxStatic}/bin/nginx ./bin/nginx
              cp -Tv ${conf.nginxConf}/nginx.conf ./etc/nginx/nginx.conf
              cp -Tv ${conf.nginxWebRoot}/index.html ./etc/nginx/index.html

              ls -lah ./etc/nginx

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group

              mkdir -pv tmp/nginx_client_body
              # nginx still tries to read this directory even if error_log
              # directive is specifying another file :/
              mkdir -pv var/log/nginx
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./var/log/nginx ./tmp ./etc/nginx
            '';

            config.Cmd = [ "nginx" "-c" "/etc/nginx/nginx.conf" ];
            config.ExposedPorts = { "${conf.nginxPort}/tcp" = { }; };
            config.User = "${user}:${group}";
            config.Env = [ "PATH=/bin" ];
          };

        testNginxStatic = prev.testers.runNixOSTest {
          name = "test-nginx-static";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.environment.systemPackages = with pkgs; [
                pkgs.nginxStatic
                file
              ];
            };

          globalTimeout = 2 * 60;

          testScript = { nodes, ... }: ''
            start_all()
            machine.wait_for_unit("default.target")

            machine.succeed("docker load <${final.OCIImageNginxStatic}")
            print(machine.succeed("docker images"))

            expected = 'not a dynamic executable'
            result = machine.fail("ldd $(readlink -f $(which nginx)) 2>&1")
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = '10.3MB'
            result = machine.succeed('docker images --format "{{.Size}}"')
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = '9.9M'
            result = machine.succeed("du -chs $(readlink -f $(which nginx))") 
            assert expected in result, f"expected = {expected}, result = {result}"
            
            expected = 'nginx version: nginx/1.28.0'
            result = machine.succeed("nginx -V 2>&1")
            assert expected in result, f"expected = {expected}, result = {result}"

            machine.execute("docker run --name=container-nginx -d --rm -p=8000:80 joshrosso:1.4")
            machine.wait_for_open_port(8000)

            result = machine.succeed("curl localhost:8000")
            expected = 'all ur PODZ is belong to ME'
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

                    docker load <"${final.OCIImageNginxStatic}"
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
                    nginxStatic
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
            automatic-vm
            myvm
            nginxStatic
            OCIImageNginxStatic
            perl540
            testNginxStatic
            ;
          default = pkgs.testNginxStatic;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
          meta.description = "Run the NixOS VM";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            automatic-vm
            myvm
            nginxStatic
            OCIImageNginxStatic
            perl540
            testNginxStatic
            ;
          default = pkgs.testNginxStatic;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            automatic-vm
            myvm
            nginxStatic
            # OCIImageNginxStatic
            perl540
            testNginxStatic
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
