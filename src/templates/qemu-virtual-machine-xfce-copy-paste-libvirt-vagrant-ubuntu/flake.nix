{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'    
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        ubuntu2204 = prev.fetchurl {
          url = "https://app.vagrantup.com/generic/boxes/ubuntu2204/versions/4.3.8/providers/libvirt.box";
          hash = "sha256-ZkzHC1WJITQWSxKCn9VsuadabZEnu+1lR4KD58PVGrQ=";
        };

        ubuntu2304 = prev.fetchurl {
          url = "https://app.vagrantup.com/generic/boxes/ubuntu2304/versions/4.3.8/providers/libvirt/amd64/vagrant.box";
          hash = "sha256-NJSYFp7RmL0BlY8VBltSFPCCdajk5J5wMD2++aBnxCw=";
        };

        ubuntu2404Old = prev.fetchurl {
          url = "https://app.vagrantup.com/alvistack/boxes/ubuntu-24.04/versions/20240415.1.1/providers/libvirt/amd64/vagrant.box";
          hash = "sha256-vuaPLzdWV5ehJdlBBpWqf1nXh4twdHfPdX19bnY4yBk=";
        };

        ubuntu2404 = prev.fetchurl {
          url = "https://vagrantcloud.com/gnome-shell-box/boxes/ubuntu2404/versions/0.0.10/providers/libvirt/amd64/vagrant.box";
          hash = "sha256-iDLWXvO3tmCPxlarGzVzlBHRRKsvKZrjQW8JiiVUM1Q=";
        };

        # vagrantfiles
        vagrantfileUbuntu = prev.writeText "vagrantfile-ubuntu" ''
          Vagrant.configure("2") do |config|
            config.vm.box = "generic/ubuntu2204"
            # config.vm.box = "generic/ubuntu2304"
            # config.vm.box = "gnome-shell-box/ubuntu2404"
            # config.vm.box = "alvistack/ubuntu-24.04"

            config.vm.provider :libvirt do |v|
              v.cpus=5
              v.memory = "5000"
              # v.memorybacking :access, :mode => "shared"
              # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1460
            end

            # 
            # config.vm.network :public_network, :bridge => 'br0', :dev => 'br0'

            config.vm.synced_folder '.', '/home/vagrant/code'

            config.vm.provision "shell", inline: <<-SHELL

              # TODO: revise it, test it!
              # https://unix.stackexchange.com/a/400140
              # https://stackoverflow.com/a/69288266
              RAM_IN_GIGAS=$(expr $(sed -n '/^MemTotal:/ s/[^0-9]//gp' /proc/meminfo) / 1024 / 1024)
              echo "$RAM_IN_GIGAS"
              # df -h /tmp && sudo mount -o remount,size="$RAM_IN_GIGAS"G /tmp/ && df -h /tmp

              # Could not access KVM kernel module: Permission denied
              # qemu-kvm: failed to initialize kvm: Permission denied
              # qemu-kvm: falling back to tcg
              echo "Start kvm stuff..." \
              && (getent group kvm || groupadd kvm) \
              && sudo usermod --append --groups kvm vagrant \
              && echo "End kvm stuff!"

              su vagrant -lc \
              '
                # env | sort
                # echo
                # wget -qO- http://ix.io/4Cj0 | sh -
                # echo $PATH
                # export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                # echo $PATH
                # wget -qO- http://ix.io/4Bqg | sh -
              '

              mkdir -pv /etc/sudoers.d \
              && echo 'vagrant:1' | chpasswd \
              && echo 'vagrant ALL=(ALL) PASSWD:SETENV: ALL' > /etc/sudoers.d/vagrant

            SHELL
          end
        '';


        prepareVagrantVms = prev.writeScriptBin "prepare-vagrant-vms" ''
          #! ${prev.runtimeShell} -e
          # set -x
          for i in {0..100};do
            echo "The iteration number is: $i. Time: $(date +'%d/%m/%Y %H:%M:%S:%3N')";
            vagrant box list

            if (vagrant box list | grep -q 'ubuntu'); then
              break
            fi
          done;
        '';

        runVagrantUbuntu = prev.writeScriptBin "run-vagrant-ubuntu" ''
          #! ${prev.runtimeShell} -e
          # set -x
          prepare-vagrant-vms \
          && cd "$HOME"/vagrant-examples/libvirt/ubuntu/ \
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
                    # virtualisation.docker.enable = true;
                    # virtualisation.podman.enable = true;

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

                ## What does not work if it is desabled?
                /*
                # hardware.enableAllFirmware = true;
                hardware.enableRedistributableFirmware = true;
                # hardware.opengl.driSupport = true;
                hardware.opengl.driSupport32Bit = true;
                hardware.opengl.enable = true;
                hardware.opengl.extraPackages = with pkgs; [ pipewire pulseaudioFull libva-utils ];
                hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ pipewire pulseaudioFull libva-utils ];
                hardware.opengl.package = pkgs.mesa.drivers;
                # hardware.opengl.setLdLibraryPath = true;
                # hardware.pulseaudio.package = pkgs.pulseaudioFull;
                hardware.pulseaudio.support32Bit = true;
                # hardware.steam-hardware.enable = true;
                # programs.steam.enable = true;
                */

                /*
                journalctl --user --unit copy-vagrant-examples-vagrant-up.service --boot --follow

                systemctl --user is-active copy-vagrant-examples-vagrant-up.service; 
                test $? -eq 3 && echo 1 || echo 2

                while ! (systemctl --user is-active copy-vagrant-examples-vagrant-up.service; test $? -eq 3); do \
                  echo $(date +'%d/%m/%Y %H:%M:%S:%3N'); 
                  sleep 0.3; 
                done 

                */
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
                      set -x
                      BASE_DIR=/home/nixuser/vagrant-examples/libvirt
                      mkdir -pv "$BASE_DIR"/{alpine,archlinux,ubuntu,nixos}

                      cd "$BASE_DIR"

                      cp -v "${pkgs.vagrantfileUbuntu}" ubuntu/Vagrantfile

                      PROVIDER=libvirt \
                      && vagrant box list \
                      && vagrant \
                          box \
                          add \
                          generic/ubuntu2204 \
                          "${pkgs.ubuntu2204}" \
                          --force \
                          --provider \
                          $PROVIDER \
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
                    runVagrantUbuntu
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
                  xdotool type run-vagrant-ubuntu \
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
              export LD_LIBRARY_PATH="${prev.libcanberra-gtk3}"/lib/gtk-3.0/modules

              ${final.myvm}/bin/run-nixos-vm & PID_QEMU="$!"

              export VNC_PORT=3001

              for _ in web{0..100}; do
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
            ubuntu2204
            # ubuntu2404
            myvm
            ;
          default = pkgs.automatic-vm;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            automatic-vm
            # ubuntu2204
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
            automatic-vm
            # ubuntu2204
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
