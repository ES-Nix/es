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
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        opensuse = prev.fetchurl {
          # alvistack/opensuse-tumbleweed
          url = "https://vagrantcloud.com/alvistack/boxes/opensuse-tumbleweed/versions/20250415.1.1/providers/libvirt/amd64/vagrant.box";
          hash = "sha256-LetbsudsWzReLMM2pl0+LUKAaG68vOSJQW0El9hii6M=";
        };

        vagrantfileOpensuse = prev.writeText "vagrantfile-opensuse" ''
          Vagrant.configure("2") do |config|
            config.vm.box = "alvistack/opensuse-tumbleweed"

            config.vm.provider :libvirt do |v|
              v.cpus=4
              v.memory = "4096"
              # v.memorybacking :access, :mode => "shared"
              # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1460
            end

            config.vm.synced_folder '.', '/home/vagrant/code'

            config.vm.provision "shell", inline: <<-SHELL
              ls -alh
            SHELL
          end
        '';

        prepareVagrantVms = prev.writeScriptBin "prepare-vagrant-vms" ''
          #! ${prev.runtimeShell} -e
          # set -x
          for i in {0..100};do
            echo "The iteration number is: $i. Time: $(date +'%d/%m/%Y %H:%M:%S:%3N')";
            vagrant box list
            if (vagrant box list | grep -q opensuse); then
              break
            fi
          done;
        '';

        runVagrantDebian = prev.writeScriptBin "run-vagrant-opensuse" ''
          #! ${prev.runtimeShell} -e
          # set -x
          prepare-vagrant-vms \
          && cd "$HOME"/vagrant-examples/libvirt/opensuse/ \
          && vagrant up \
          && vagrant ssh
        '';

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
                      && mkdir -pv "$BASE_DIR"/{alpine,almalinux,archlinux,debian,fedora,nixos,opensuse,ubuntu} \
                      && cd "$BASE_DIR" \
                      && cp -v "${pkgs.vagrantfileOpensuse}" opensuse/Vagrantfile \
                      && chmod 0644 opensuse/Vagrantfile \
                      && vagrant \
                          box \
                          add \
                          alvistack/opensuse-tumbleweed \
                          "${pkgs.opensuse}" \
                          --force \
                          --debug \
                          --provider \
                          libvirt \
                      && vagrant box list
                  '';
                  wantedBy = [ "default.target" ];
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
                    "kvm"
                    "libvirtd"
                    "nixgroup"
                    "podman"
                    "qemu-libvirtd"
                    "root"
                    "vboxsf"
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
                    runVagrantDebian
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

                virtualisation.libvirtd.enable = true;
                # virtualisation.services.libvirtd.serviceOverrides = { PrivateUsers="no"; };

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
                  xdotool type run-vagrant-opensuse \
                  && xdotool key Return
                '';

                environment.systemPackages = with pkgs; [
                  vagrant
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
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "vagrant"
          ];
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            myvm
            ;
          default = pkgs.automatic-vm;
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
            ;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            foo-bar
            automatic-vm
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
