{
  description = "";

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


    f85a2d005e83542784a755ca8da112f4f65c4aa4
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        nginxStatic = prev.pkgsStatic.nginx.overrideAttrs (oldAttrs:
          {
            configureFlags = prev.lib.subtractLists [
              "--with-http_xslt_module"
              "--disable-shared"
              "--enable-static"
            ]
              oldAttrs.configureFlags;
          }
        );

        nginxStatic2 = (prev.nginx.override {
          perl = prev.pkgsStatic.perl536;
        }).overrideAttrs (oldAttrs:
          {
            configureFlags = prev.lib.subtractLists [
              "--with-http_xslt_module"
              "--disable-shared"
              "--enable-static"
            ]
              oldAttrs.configureFlags;
          }
        );

        nginxStaticPerl356 = prev.nginx;
        # nginxStaticPerl356 = prev.nginx.override {
        #   perl = prev.pkgsStatic.perl536;
        # };

        nginxMusl = prev.pkgsMusl.nginx;
        #        nginxMusl = prev.pkgsMusl.nginx.overrideAttrs (oldAttrs:
        #          {
        #            configureFlags = prev.lib.subtractLists [
        #              "--with-http_xslt_module"
        #              "--disable-shared"
        #              "--enable-static"
        #            ]
        #              oldAttrs.configureFlags;
        #          }
        #        );

        OCIImageNginxStatic =
          let
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
              nginxConf = prev.writeText "nginx.conf" ''
                user nobody nobody;
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
                      root ${conf.nginxWebRoot};
                    }
                  }
                }
              '';
            };
          in
          prev.dockerTools.buildLayeredImage {
            name = "joshrosso";
            tag = "1.4";
            contents = with prev; [
              fakeNss
              # final.nginxMusl
              final.nginxStatic
              # final.nginxMusl
            ];

            extraCommands = ''
              mkdir -p tmp/nginx_client_body

              # nginx still tries to read this directory even if error_log
              # directive is specifying another file :/
              mkdir -p var/log/nginx
            '';
            config = {
              Cmd = [ "nginx" "-c" conf.nginxConf ];
              ExposedPorts = { "${conf.nginxPort}/tcp" = { }; };
            };
          };

        testNginxStatic = prev.testers.runNixOSTest {
          name = "test-nginx-static";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
            };

          globalTimeout = 2 * 60;

          testScript = { nodes, ... }: ''
            # start_all()
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
                    foo-bar
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
            nginxStatic
            ;

          default = pkgs.testNginxStatic;
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
            # testNginxStatic
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
