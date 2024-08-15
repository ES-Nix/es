{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
    --override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    allAttrs@{ self
    , nixpkgs
    , flake-utils
    , ...
    }:
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        foo-bar = prev.hello;
      };
    } //
    (
      let
        # nix flake show --allow-import-from-derivation --impure --refresh .#
        suportedSystems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

      in
      allAttrs.flake-utils.lib.eachSystem suportedSystems
        (system:
        let
          name = "kubenetes-vm";

          pkgsAllowUnfree = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
            config = {
              allowUnfree = true;
            };
          };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        rec {

          packages.vm = self.nixosConfigurations.vm.config.system.build.toplevel;

          packages.automatic-vm = pkgsAllowUnfree.writeShellApplication {
            name = "run-nixos-vm";
            runtimeInputs = with pkgsAllowUnfree; [ curl virt-viewer ];
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
              export LD_LIBRARY_PATH="${pkgsAllowUnfree.libcanberra-gtk3}"/lib/gtk-3.0/modules

              ${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm & PID_QEMU="$!"

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

          apps.default = {
            type = "app";
            program = "${self.packages."${system}".automatic-vm}/bin/run-nixos-vm";
          };

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              bashInteractive
              coreutils
              curl
              firefox
            ];

            shellHook = ''
              export TMPDIR=/tmp

              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop --impure .# --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build --impure $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default

              test -L .profiles/nixosConfigurations."$system".vm.config.system.build.vm \
              || nix build --impure --out-link .profiles/nixosConfigurations."$system".vm.config.system.build.vm .#nixosConfigurations.vm.config.system.build.vm

            '';
          };
        })
    )
    // {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = builtins.currentSystem;

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

                  # https://discourse.nixos.org/t/nixpkgs-support-for-linux-builders-running-on-macos/24313/2
                  virtualisation.forwardPorts = [
                    {
                      from = "host";
                      host.port = 8080;
                      guest.port = 8090;
                    }
                  ];
                };

              networking.firewall.allowedTCPPorts = [ (builtins.head config.virtualisation.vmVariant.virtualisation.forwardPorts).guest.port ];

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
                  # "kubernetes"
                  "wheel"
                ];
                packages = with pkgs; [
                  file
                  jq
                  foo-bar
                  python3
                  lsof
                ];
                shell = pkgs.bash;
                uid = 1234;
                autoSubUidGidRange = true;
              };

              services.xserver.enable = true;
              services.xserver.xkb.layout = "br";
              services.displayManager.autoLogin.user = "nixuser";
              services.xserver.displayManager.sessionCommands = ''
                # https://askubuntu.com/a/1434433
                exo-open \
                  --launch TerminalEmulator \
                  --zoom=-3 \
                  --geometry 154x40 \
                  -H \
                  -e 'show-nginx-html'
              '';

              # https://nixos.org/manual/nixos/stable/#sec-xfce
              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;
              services.xserver.videoDrivers = [ "qxl" ];
              services.spice-vdagentd.enable = true; # For copy/paste to work

              nix.extraOptions = "experimental-features = nix-command flakes";

              environment.systemPackages = with pkgs; [
                kubectl
                kubernetes

                firefox

                openssl
                file

                (
                  writeScriptBin "show-nginx-html" (
                    let
                      joshrossoKubecon = pkgs.writeTextDir "joshrosso-kubecon.yml"
                        ''
                          apiVersion: v1
                          kind: Pod
                          metadata:
                            name: a-message
                            namespace: default
                          spec:
                            containers:
                            - name: message
                              image: joshrosso/kubecon:1.4
                              ports:
                              - containerPort: 80
                        '';
                    in
                    ''
                      #! ${pkgs.runtimeShell}

                        while true; do
                          sudo -E kubectl get pods -n kube-system --field-selector status.phase=Running | grep Running && break;
                          sudo -E kubectl get pod --all-namespaces -o wide;
                          sleep 0.5;
                          clear;
                        done

                        sudo -E kubectl apply -f ${joshrossoKubecon};

                        while true; do
                          sudo -E kubectl get pods -n default --field-selector status.phase=Running | grep Running && break;
                          sudo -E kubectl get pod --all-namespaces -o wide;
                          sleep 0.5;
                          clear;
                        done

                        PORT="${ builtins.toString (builtins.head config.virtualisation.vmVariant.virtualisation.forwardPorts).guest.port}"

                        sudo -E kubectl port-forward --address 0.0.0.0 pods/a-message "$PORT":80 &

                        firefox localhost:"$PORT"
                    ''
                  )
                )

                (
                  writeScriptBin "wk8s-sudo" ''
                    #! ${pkgs.runtimeShell} -e
                        while true; do
                          sudo -E kubectl get pod --all-namespaces -o wide \
                          && echo \
                          && sudo -E kubectl get services --all-namespaces -o wide \
                          && echo \
                          && sudo -E kubectl get deployments.apps --all-namespaces -o wide \
                          && echo \
                          && sudo -E kubectl get nodes --all-namespaces -o wide;
                          sleep 1;
                          clear;
                        done
                  ''
                )

              ];

              services.kubernetes.roles = [ "master" "node" ];
              services.kubernetes.masterAddress = "${config.networking.hostName}";
              environment.variables.KUBECONFIG = "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}";
              # services.kubernetes.kubelet.extraOpts = "--fail-swap-on=false"; # If you use swap it is an must!


              systemd.services.kubelet-custom-bootstrap = {
                description = "Boostrap Custom Kubelet";
                wantedBy = [ "kubernetes.target" ];
                after = [ "docker.service" "network.target" ];
                path = with pkgs; [ docker ];
                script =
                  let
                    myCustomImage =
                      let
                        conf = {
                          nginxWebRoot = pkgs.writeTextDir "index.html"
                            ''
                              <html>
                                <body>
                                  <center>
                                  <marquee><h1>all ur PODZ is belong to ME</h1></marquee>
                                  <img src=\"https://m.media-amazon.com/images/M/MV5BYjBlODg3ZTgtN2ViNS00MDlmLWIyMTctZmQ2NWYwMzE2N2RmXkEyXkFqcGdeQVRoaXJkUGFydHlJbmdlc3Rpb25Xb3JrZmxvdw@@._V1_.jpg\" width=\"100%\">
                                  </center>
                                </body>
                              </html>\n
                            '';

                          nginxPort = "80";
                          nginxConf = pkgs.writeText "nginx.conf" ''
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
                      pkgs.dockerTools.buildLayeredImage {
                        name = "joshrosso";
                        tag = "1.4";
                        contents = [ pkgs.fakeNss pkgs.nginx ];

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
                  in
                  ''
                    echo "Seeding docker image..."
                    docker load <"${myCustomImage}"
                  '';
                serviceConfig = {
                  Slice = "kubernetes.slice";
                  Type = "oneshot";
                };
              };

              system.stateVersion = "24.05";
            })

          { nixpkgs.overlays = [ self.overlays.default ]; }
        ];
        specialArgs = { inherit nixpkgs allAttrs; };
      };
    };
}
