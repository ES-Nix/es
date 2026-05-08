{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/95600680c021743fd87b3e2fe13be7c290e1cac4' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/1546c45c538633ae40b93e2d14e0bb6fd8f13347' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'


    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    In nixos-unstable it is broken!
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'  
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        nixosImage = prev.fetchurl {
          # url = "https://app.vagrantup.com/hennersz/boxes/nixos-23.05-flakes/versions/23.05.231106000354/providers/libvirt/unknown/vagrant.box";
          # hash = "sha256-x76icAXDReYe9xppwr6b77hTO44EWvBtSx+j41bvMVA=";
          # meta.boxName = "hennersz/nixos-23.05-flakes";

          # url = "https://vagrantcloud.com/gnome-shell-box/boxes/nixos/versions/2026.2.0/providers/libvirt/amd64/vagrant.box";
          # hash = "sha256-9ZhLG1mrVJQx4pX+2dLlRCRwjAQK+Gz+1/7fu2z9ums=";
          # meta.boxName = "gnome-shell-box/nixos";

          url = "https://vagrantcloud.com/boxen/boxes/nixos-25.05/versions/2025.08.20.12/providers/libvirt/amd64/vagrant.box";
          hash = "sha256-BrWGaSndbzbYDMbcHnyAuYPnPsAngVlhKB+H1u9f5Bk=";
          meta.boxName = "boxen/nixos-25.05";
        };

        vagrantfileNixos = prev.writeText "vagrantfile-nixos" ''
                    Vagrant.configure("2") do |config|
                      # config.vm.box = "''${final.nixosImage.meta.boxName}";
                      config.vm.box = "${final.nixosImage.meta.boxName}"
                      # config.vm.box = "boxen/nixos-25.05"                      

                      config.vm.provider :libvirt do |v|
                        v.cpus=7
                        v.memory = "12096"
                        # v.memorybacking :access, :mode => "shared"
                        # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1460

                        # v.graphics_type = "vnc"
                        # # v.video_type    = "cirrus" # Old-school video (most compatible?)
                        # v.video_type    = "virtio"
                        # v.video_accel3d = false
                        # v.qemu_use_session = false
                      end

                      # https://github.com/hashicorp/vagrant/issues/13688#issuecomment-3014055294
                      config.vm.allow_fstab_modification = false

                      # Force Vagrant to use a clean SSH config file, so that it doesn't mess with the host's SSH config.
                      config.ssh.extra_args = ["-F", "/dev/null"]

                      config.vm.synced_folder '.', '/home/vagrant/code'
                      # config.vm.synced_folder ".", "/home/vagrant/code", disabled: true
                      # config.vm.synced_folder ".", "/vagrant", disabled: true

                      config.vm.provision "shell", inline: <<-SHELL
                        ls -alh

                        cd /etc/nixos \
                        && cat > custom-configuration.nix << '_EOF'
                          { config, nixpkgs, pkgs, lib, modulesPath, ... }:
                          let
                            cfg = config;
                          in
                          {
                            environment.systemPackages = with pkgs; [
                                kubectl
                                kubernetes
                            ];

                            services.kubernetes.roles = [ "master" "node" ];
                            services.kubernetes.masterAddress = "''${cfg.networking.hostName}";
                            environment.variables.KUBECONFIG = "/etc/''${cfg.services.kubernetes.pki.etcClusterAdminKubeconfig}";
                          }
          _EOF

                        # cd /etc/nixos \
                        # && nix \
                        # flake \
                        # lock \
                        # --override-input nixstable github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852 \
                        # && sudo nixos-rebuild switch -L --flake .# --show-trace
                      SHELL
                    end
        '';

        prepareVagrantVms = prev.writeScriptBin "prepare-vagrant-vms" ''
          #! ${prev.runtimeShell} -e
          # set -x
          for i in {0..100};do
            echo "The iteration number is: $i. Time: $(date +'%d/%m/%Y %H:%M:%S:%3N')";
            vagrant box list
            if (vagrant box list | grep -q nixos); then
              break
            fi
          done;
        '';

        runVagrantNixOS = prev.writeScriptBin "run-vagrant-nixos" ''
          #! ${prev.runtimeShell} -e
          # set -x
          prepare-vagrant-vms \
          && cd "$HOME"/vagrant-examples/libvirt/nixos/ \
          && vagrant up \
          && vagrant ssh
        '';

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = prev.stdenv.hostPlatform.system;
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

                    virtualisation.memorySize = 1024 * 16; # Use MiB memory.
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

                # journalctl --user --unit copy-vagrant-examples-vagrant-up.service -b -f
                # journalctl --unit copy-vagrant-examples-vagrant-up.service -b -f
                systemd.user.services.copy-vagrant-examples-vagrant-up = {
                  path = with pkgs; [
                    curl
                    file
                    gnutar
                    gzip
                    procps
                    vagrant
                    xz
                  ];

                  script = ''
                    #! ${pkgs.runtimeShell} -e
                      # set -x

                      id \
                      && BASE_DIR=/home/nixuser/vagrant-examples/libvirt \
                      && mkdir -pv "$BASE_DIR"/{alpine,archlinux,ubuntu,nixos} \
                      && cd "$BASE_DIR" \
                      && cp -v "${pkgs.vagrantfileNixos}" nixos/Vagrantfile \
                      && vagrant \
                          box \
                          add \
                          ${final.nixosImage.meta.boxName} \
                          "${pkgs.nixosImage}" \
                          --force \
                          --debug \
                          --provider \
                          libvirt \
                      && vagrant box list
                  '';
                  wantedBy = [ "default.target" ];
                };

                # environment.etc."init.d/nfs-kernel-server" = {
                #   text = ''
                #     #!/bin/sh
                #     # echo $@ >> /home/nixuser/vagrant.log
                #   '';
                #   mode = "0774";
                # };

                # services.qemuGuest.enable = true;
                # # services.spice-vdagentd.enable = true;
                # services.spice-webdavd.enable = true;

                # # services.printing.enable = true;
                # services.pulseaudio.enable = false;
                # security.rtkit.enable = true;
                # services.pipewire = {
                #   enable = true;
                #   alsa.enable = true;
                #   alsa.support32Bit = true;
                #   pulse.enable = true;

                #   # use the example session manager (no others are packaged yet so this is enabled by default,
                #   # no need to redefine it in your config for now)
                #   #media-session.enable = true;
                # };

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
                    "kvm"
                    "libvirtd"
                    "networkmanager"
                    "nixgroup"
                    "podman"
                    "qemu-libvirtd"
                    "root"
                    "vboxsf"
                    "video"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    file
                    firefox
                    git
                    jq
                    lsof
                    findutils
                    xdotool
                    vagrant
                    prepareVagrantVms
                    runVagrantNixOS
                    fooBar
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

                virtualisation.libvirtd.enable = true;
                # virtualisation.services.libvirtd.serviceOverrides = { PrivateUsers="no"; };

                # boot.nixStoreMountOpts = [ "rw" ]; # TODO: What may be missing?
                nix.extraOptions = "experimental-features = nix-command flakes";
                nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
                  "vagrant"
                ];

                programs.dconf.enable = true;

                environment.variables = {
                  VAGRANT_DEFAULT_PROVIDER = "libvirt";
                  # VAGRANT_DEFAULT_PROVIDER = "virtualbox"; # Is it an must for vagrant snapshots?
                  /*
                    https://github.com/erictossell/nixflakes/blob/e97cdba0d6b192655d01f8aef5a6691f587c61fe/modules/virt/libvirt.nix#L29-L36
                    */
                  # programs.dconf.enable = true;
                  # VIRSH_DEFAULT_CONNECT_URI="qemu:///system";
                  # VIRSH_DEFAULT_CONNECT_URI = "qemu:///session";
                  # programs.dconf.profiles = pkgs.writeText "org/virt-manager/virt-manager/connections" ''
                  #  autoconnect = ["qemu:///system"];
                  #  uris = ["qemu:///system"];
                  # '';
                };

                # displayManager.job.logToJournal
                # journalctl -t xsession -b -f
                # journalctl -u display-manager.service -b
                # https://askubuntu.com/a/1434433
                services.xserver.displayManager.sessionCommands = ''
                  exo-open \
                    --launch TerminalEmulator \
                    --zoom=-3 \
                    --geometry 154x40

                  for i in {1..100}; do
                    xdotool getactivewindow
                    $? && break
                    sleep 0.1
                  done
                  # Race condition. Why?
                  # sleep 3
                  xdotool type run-vagrant-nixos \
                  && xdotool key Return
                '';

                environment.systemPackages = with pkgs; [
                  vagrant
                ];

                system.stateVersion = "25.11";
              })

            { nixpkgs.overlays = [ self.overlays.default ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvm = final.nixos-vm.config.system.build.vm;

        automaticVm = prev.writeShellApplication {
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
              # export LD_LIBRARY_PATH="''${prev.libcanberra-gtk3}"/lib/gtk-3.0/modules
              # 
              # export GTK_MODULES=""
              # export GTK_PATH=""
              # export GTK_PATH=/nonexistent
              # unset GTK3_MODULES
              # export GTK3_MODULES
              # export GTK_MODULES=gail:atk-bridge
              # export GTK_IM_MODULE=ibus              
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

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

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
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "vagrant"
          ];
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            nixosImage
            myvm
            ;
          default = pkgs.automaticVm;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automaticVm}";
            meta.description = "Run the NixOS VM";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            nixosImage
            automaticVm
            ;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            automaticVm
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
