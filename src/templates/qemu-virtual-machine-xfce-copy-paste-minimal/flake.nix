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
        system = builtins.currentSystem; # It forces the usage of --impure flag with nix

        modules = [
          ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
            {
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/hda1"; };

              virtualisation.vmVariant =
                {
                  virtualisation.writableStore = true; # TODO: hardening

                  virtualisation.memorySize = 1024 * 3; # Use MiB of RAM memory. free -h
                  virtualisation.diskSize = 1024 * 10; # Use MiB of HD/disk memory. df -h
                  virtualisation.cores = 2; # Number of cores. nproc

                  virtualisation.graphics = true;

                  virtualisation.qemu.options = [
                    "-vga virtio"
                    "-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on"
                    "-device virtio-serial-pci"
                    "-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0"
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

              documentation.nixos.enable = false;
              documentation.man.enable = false;
              documentation.dev.enable =false;

              systemd.user.services.populate-history-vagrant = {
                script = ''
                  DESTINATION=/home/nixuser/.bash_history
                  echo "copy-paste-debug" >> "$DESTINATION"
                '';
                wantedBy = [ "default.target" ];
              };

              environment.systemPackages = with pkgs; [
              pciutils
                (
                  writeScriptBin "copy-paste-debug" ''
                    #! ${pkgs.runtimeShell} -e

                    set -x

                    ls -alh /dev/virtio-ports/com.redhat.spice.0
                    lspci | grep -F 'Red Hat, Inc.'

                    ps -lef | grep spice-vdagentd
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
              '';

              system.stateVersion = "${lib.versions.majorMinor lib.version}"; # Not a Must! Just avoid an warning.
            })
          { nixpkgs.overlays = [ self.overlays.default ]; } # Not a Must!
        ];
        specialArgs = { inherit nixpkgs allAttrs; }; # Not a Must!
      };
    };
}
