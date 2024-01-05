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
        system = builtins.currentSystem;

        modules = [
          ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
            {
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/hda1"; };

              virtualisation.vmVariant =
                {

                  virtualisation.useNixStoreImage = false; # TODO: hardening
                  virtualisation.writableStore = true; # TODO: hardening

                  programs.dconf.enable = true;

                  virtualisation.memorySize = 1024 * 3; # Use MiB memory.
                  virtualisation.diskSize = 1024 * 15; # Use MiB memory.
                  virtualisation.cores = 6; # Number of cores.
                  virtualisation.graphics = true;

                  virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                  virtualisation.qemu.options = [
                    # Better display option
                    # TODO: -display sdl,gl=on
                    # https://gitlab.com/qemu-project/qemu/-/issues/761
                    "-vga virtio"
                    # "-display gtk,zoom-to-fit=false" # Not a Must!
                    # Enable copy/paste
                    # https://www.kraxel.org/blog/2021/05/qemu-cut-paste/
                    "-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on"
                    "-device virtio-serial-pci"
                    "-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0"
                  ];
                };

              users.extraGroups.nixgroup.gid = 999;

              security.sudo.wheelNeedsPassword = false; # TODO: hardening
              users.users.nixuser = {
                isSystemUser = true;
                password = "101"; # TODO: hardening
                createHome = true;
                home = "/home/nixuser";
                homeMode = "0700";
                description = "The VM tester user";
                group = "nixgroup";
                extraGroups = [
                  "docker"
                  "kubernetes"
                  "kvm"
                  "libvirtd"
                  "nixgroup"
                  "podman"
                  "qemu-libvirtd"
                  "root"
                  "wheel"
                ];
                packages = with pkgs; [
                  bashInteractive
                  btop
                  coreutils
                  direnv
                  file
                  firefox
                  git
                  which
                  foo-bar
                ];
                shell = pkgs.bashInteractive;
                uid = 1234;
              };

              boot.extraModprobeConfig = "options kvm_intel nested=1";

              services.qemuGuest.enable = true;

              services.xserver.enable = true;
              services.xserver.layout = "br";

              services.xserver.displayManager.autoLogin.user = "nixuser";
              services.xserver.displayManager.sessionCommands = ''
                exo-open \
                  --launch TerminalEmulator \
                  --zoom=-3 \
                  --geometry 154x40
              '';

              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;

              # services.xserver.videoDrivers = [ "qxl" ]; # Not a Must!

              # For copy/paste to work
              services.spice-vdagentd.enable = true;

              system.stateVersion = "22.11";
            })

          { nixpkgs.overlays = [ self.overlays.default ]; }

        ];

        specialArgs = { inherit nixpkgs allAttrs; };

      };
    };
}
