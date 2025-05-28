{
  description = "";

  /*
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

        ubuntu2204Virtualbox = prev.fetchurl {
          url = "https://app.vagrantup.com/generic/boxes/ubuntu2204/versions/4.3.8/providers/virtualbox.box";
          hash = "sha256-GYecWtGWCiA+YEYTe7Wlo2LKHk8X/3d0WXJegxK+/rk=";
        };

        /*
        sudo apt-get update
        sudo apt-get install -y build-essential dkms linux-headers-$(uname -r)
        && sudo mkdir -pv /mnt/cdrom \
        && sudo mount /dev/cdrom /mnt/cdrom \
        && cd /mnt/cdrom \
        && sudo ./VBoxLinuxAdditions.run

        Refs.:
        - https://stackoverflow.com/a/57513296
        - https://stackoverflow.com/a/39633781
        - https://askubuntu.com/a/1435032
        */
        vagrantfileUbuntuVirtualbox = prev.writeText "vagrantfile-ubuntu-virtualbox" ''
          Vagrant.configure(2) do |config|
            config.vm.box = "generic/ubuntu2204"
            config.vm.provider "virtualbox" do |vb|
              # Display the VirtualBox GUI when booting the machine
              vb.gui = true
            end

            # Install xfce and VirtualBox additions
            config.vm.provision "shell", inline: <<-SHELL
              sudo \
              apt-get \
              update

              sudo \
              apt-get \
              install \
              --no-install-recommends \
              --no-install-suggests \
              --yes \
              linux-headers-$(uname -r) \
              build-essential \
              dkms \
              xfce4 \
              virtualbox-guest-utils \
              virtualbox-guest-x11
            SHELL
            # Permit anyone to start the GUI
            # config.vm.provision "shell", inline: <<-SHELL
            #   sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' \
            #     /etc/X11/Xwrapper.config
            # SHELL
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
          && cd "$HOME"/vagrant-examples/virtualbox/ubuntu/ \
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
                  let
                    isLinuxAndIsx86_64 = (pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64);
                  in
                  {
                    # It does not work for many hardwares...
                    # About cache miss:
                    # https://www.reddit.com/r/NixOSMasterRace/comments/17e4fvw/new_user_entered_the_lobby/
                    # TODO: still not working, had to manually add the group vboxusers
                    users.extraGroups.vboxusers.members = if isLinuxAndIsx86_64 then [ "nixuser" ] else [ ];
                    virtualisation.virtualbox.guest.enable = isLinuxAndIsx86_64;
                    # virtualisation.virtualbox.guest.x11 = isLinuxAndIsx86_64;
                    virtualisation.virtualbox.host.enable = isLinuxAndIsx86_64;
                    virtualisation.virtualbox.host.enableExtensionPack = isLinuxAndIsx86_64;
                    # https://github.com/NixOS/nixpkgs/issues/76108#issuecomment-1977580798
                    virtualisation.virtualbox.host.enableHardening = ! isLinuxAndIsx86_64;

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
                      BASE_DIR=/home/nixuser/vagrant-examples/virtualbox
                      mkdir -pv "$BASE_DIR"/{alpine,archlinux,ubuntu}

                      cd "$BASE_DIR"

                      cp -v "${pkgs.vagrantfileUbuntuVirtualbox}" ubuntu/Vagrantfile

                      PROVIDER=virtualbox \
                      && vagrant box list \
                      && vagrant \
                          box \
                          add \
                          generic/ubuntu2204 \
                          "${pkgs.ubuntu2204Virtualbox}" \
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
                    "vboxusers"
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

                    # (pkgs.makeAutostartItem {
                    #   name = "virtualbox";
                    #   package = pkgs.virtualbox;
                    # })                    
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

                # virtualisation.libvirtd.enable = true;

                nix.extraOptions = "experimental-features = nix-command flakes";
                nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
                  "vagrant"
                  "Oracle_VM_VirtualBox_Extension_Pack"
                ];

                programs.dconf.enable = true;

                environment.variables = {
                  # VAGRANT_DEFAULT_PROVIDER = "libvirt";
                  VAGRANT_DEFAULT_PROVIDER = "virtualbox"; # Is it an must for vagrant snapshots?
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
            ubuntu2204Virtualbox
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
            # ubuntu2204Virtualbox
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
            automatic-vm
            # ubuntu2204Virtualbox
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
