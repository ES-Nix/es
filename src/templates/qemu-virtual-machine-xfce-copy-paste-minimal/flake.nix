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
                  virtualisation.writableStore = true; # TODO: hardening

                  virtualisation.memorySize = 1024 * 3; # Use MiB memory.
                  virtualisation.diskSize = 1024 * 10; # Use MiB memory.
                  virtualisation.cores = 2; # Number of cores.
                  virtualisation.graphics = true;

                  virtualisation.qemu.options = [
                    "-vga virtio"
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
                extraGroups = [ "wheel" ];
                packages = with pkgs; [ foo-bar ];
                shell = pkgs.bashInteractive;
                uid = 1234;
              };

              # programs.dconf.enable = true; # Not a Must!
              # boot.extraModprobeConfig = "options kvm_intel nested=1"; # Not a Must!
              # services.qemuGuest.enable = true; # Not a Must!
              # services.xserver.videoDrivers = [ "qxl" ]; # Not a Must!
              # virtualisation.useNixStoreImage = false; # TODO: hardening # Not a Must!
              # virtualisation.resolution = lib.mkForce { x = 1024; y = 768; }; # Not a Must!

              # For copy/paste to work
              services.spice-vdagentd.enable = true;

              services.xserver.enable = true;
              services.xserver.layout = "br";
              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;
              services.xserver.displayManager.autoLogin.user = "nixuser";
              services.xserver.displayManager.sessionCommands = ''
                exo-open \
                  --launch TerminalEmulator \
                  --zoom=-3 \
                  --geometry 154x40
              '';

              system.stateVersion = "22.11";
            })
          { nixpkgs.overlays = [ self.overlays.default ]; }
        ];
        specialArgs = { inherit nixpkgs allAttrs; };
      };
    };
}
