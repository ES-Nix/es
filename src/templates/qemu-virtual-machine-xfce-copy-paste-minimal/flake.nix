{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    allAttrs@{ self
    , nixpkgs
    , ...
    }:
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        foo-bar = prev.hello;

      };
    } //
    allAttrs.flake-utils.lib.eachDefaultSystem
      (system:
      let
        name = "My VM with xfce";

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

        apps.vm = {
          type = "app";
          program = "${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm";
        };

        # nix fmt
        formatter = pkgsAllowUnfree.nixpkgs-fmt;

        devShells.default = pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            coreutils
            curl
            jq
            patchelf
            xclip
            xsel
            virt-viewer
          ];

          shellHook = ''
            # TODO:
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
    // {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = builtins.currentSystem; # It forces the usage of --impure flag with nix

        modules = [

          # (nixpkgs + "/nixos/modules/virtualisation/qemu-vm.nix")
          # (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")

          # (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5-new-kernel.nix")
          # (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix")

          ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
            {
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/hda1"; };

              virtualisation.vmVariant =
                {
                  virtualisation.writableStore = true; # TODO: hardening
                  virtualisation.useNixStoreImage = true; # sudo needs this

                  virtualisation.memorySize = 1024 * 3; # Use MiB of RAM memory. free -h
                  virtualisation.diskSize = 1024 * 10; # Use MiB of HD/disk memory. df -h
                  virtualisation.cores = 2; # Number of cores. nproc

                  virtualisation.graphics = true;

                  virtualisation.qemu.options = [
                    # "-device qemu-xhci,id=xhci"
                    # "-display sdl,gl=off"

                    # "-vga virtio"
                    # "-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on"
                    # "-device virtio-serial-pci"
                    # "-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0"

                    # https://www.spice-space.org/spice-user-manual.html#Running_qemu_manually
                    # remote-viewer spice://localhost:3001
                    "-machine vmport=off"
                    "-vga qxl"
                    "-spice port=3001,disable-ticketing=on"
                    "-device virtio-serial"
                    "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                    "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                  ];
                };

              users.extraGroups.nixgroup.gid = 999;
              users.users.nixuser = {
                isSystemUser = true;
                password = "101"; # TODO: hardening
                createHome = true;
                home = "/home/nixuser";
                homeMode = "0700";
                description = "The VM tester user";
                group = "nixgroup";
                extraGroups = [ "wheel" ]; # TODO: hardening
                packages = with pkgs; [ foo-bar ];
                shell = pkgs.bashInteractive;
                uid = 1234;
              };

              # For copy/paste to work
              services.spice-vdagentd.enable = true;

              services.xserver.enable = true;
              services.xserver.layout = "br";

              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;
              services.xserver.displayManager.autoLogin.user = "nixuser";

              # services.xserver.displayManager.sddm.enable = true;
              # services.xserver.desktopManager.plasma5.enable = true;

              # services.xserver.displayManager.gdm.enable = true;
              # services.xserver.desktopManager.gnome.enable = true;

              documentation.nixos.enable = false; # Not a Must!
              documentation.man.enable = false; # Not a Must!
              documentation.dev.enable = false; # Not a Must!

              systemd.user.services.populate-history = {
                script = ''
                  DESTINATION=/home/nixuser/.bash_history
                  echo "echo foo-guest-bar | DISPLAY=:0 xsel -ib" >> "$DESTINATION"
                  echo "echo foo-guest-bar | DISPLAY=:0 xsel -i" >> "$DESTINATION"
                  echo "xclip -o -rmlastnl -selection clipboard" >> "$DESTINATION"
                  echo "copy-paste-debug" >> "$DESTINATION"
                  echo "udevadm info /dev/virtio-ports/com.redhat.spice.0" >> "$DESTINATION"
                  echo "udevadm info --query=all --name=/dev/input/mice" >> "$DESTINATION"
                  echo "udevadm info --query=all --name=/dev/input/mouse0" >> "$DESTINATION"
                  echo "lspci | grep -F 'Red Hat, Inc.'" >> "$DESTINATION"
                  echo "ps -lef | grep spice-vdagent" >> "$DESTINATION"
                  echo "find /sys/class/input/ -name mouse* -exec udevadm info -a {} \; | grep 'ATTRS{name}'" >> "$DESTINATION"
                  echo "sudo lsof /dev/vport7p1" >> "$DESTINATION"
                '';
                wantedBy = [ "default.target" ];
              };

              environment.systemPackages = with pkgs; [
                evemu
                lsof
                file
                pciutils
                python310Packages.evdev
                xdotool
                xclip
                xsel
                (
                  writeScriptBin "copy-paste-debug" ''
                    #! ${pkgs.runtimeShell} -e

                    # set -x

                    # cat /var/log/X.0.log
                    grep QXL /var/log/X.0.log || true
                    grep virtio /var/log/X.0.log

                    ls -alh /dev/virtio-ports/com.redhat.spice.0
                    lspci | grep -F 'Red Hat, Inc.'

                    ps -lef | grep spice-vdagent
                    pgrep spice-vdagent | xargs -I{} echo /proc/{}/cmdline

                    systemctl is-active spice-vdagentd.service

                  ''
                )
              ];

              # Not a Must! Just really usefull
              services.xserver.displayManager.sessionCommands = ''
                exo-open \
                  --launch TerminalEmulator \
                  --zoom=-3 \
                  --geometry 154x40

                echo foo-guest-bar | DISPLAY=:0 xsel -ib
              '';

              system.stateVersion = "${lib.versions.majorMinor lib.version}"; # Not a Must! Just avoid an warning.
            })
          { nixpkgs.overlays = [ self.overlays.default ]; } # Not a Must!
        ];
        specialArgs = { inherit nixpkgs allAttrs; }; # Not a Must!
      };
    };
}
