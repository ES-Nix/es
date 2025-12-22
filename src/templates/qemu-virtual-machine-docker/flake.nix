{
  description = "VM";

/*
24.05:
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798

24.11:
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd'
*/
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = all@{ self, nixpkgs, ... }:
    let
      pkgsAllowUnfree = import nixpkgs {
        system = "x86_64-linux";
        # system = "aarch64-linux";
        config = { allowUnfree = true; };
      };
    in
    {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (

            { lib, config, pkgs, ... }:
            let
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w";
            in
            {
              # Internationalisation options
              # i18n.defaultLocale = "en_US.UTF-8";
              i18n.defaultLocale = "pt_BR.UTF-8";
              console.keyMap = "br-abnt2";

              virtualisation.vmVariant = {
                virtualisation.useNixStoreImage = true;
                virtualisation.writableStore = true; # TODO
                virtualisation.docker.enable = true;

                virtualisation.memorySize = 1024 * 3; # Use maximum of RAM MiB memory.
                virtualisation.diskSize = 1024 * 16; # Use maximum of hard disk MiB memory.
                virtualisation.cores = 4; # Number of cores.

                # https://discourse.nixos.org/t/nixpkgs-support-for-linux-builders-running-on-macos/24313/2
                virtualisation.forwardPorts = [
                  {
                    from = "host";
                    # host.address = "127.0.0.1";
                    host.port = 10022;
                    # guest.address = "34.74.203.201";
                    guest.port = 10022;
                  }
                ];
                # https://lists.gnu.org/archive/html/qemu-discuss/2020-05/msg00060.html
                virtualisation.qemu.options = [
                  "-display none "
                  "-daemonize"
                  "-pidfile pidfile.txt"
                ];

              };

              fileSystems."/" = {
                device = "/dev/disk/by-label/nixos";
                fsType = "ext4";
              };

              boot.loader.systemd-boot.enable = true;

              # # https://github.com/NixOS/nixpkgs/issues/23912#issuecomment-1462770738
              boot.tmp.useTmpfs = true;
              boot.tmp.tmpfsSize = "95%";

              users.users.root = {
                password = "root";
                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                ];
              };

              # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
              users.extraGroups.nixgroup.gid = 999;

              security.sudo.wheelNeedsPassword = false;
              users.users.nixuser = {
                isSystemUser = true;
                password = "121";
                createHome = true;
                home = "/home/nixuser";
                homeMode = "0700";
                description = "The VM tester user";
                group = "nixgroup";
                extraGroups = [
                  "docker"
                  "kvm"
                  "libvirtd"
                  "qemu-libvirtd"
                  "wheel"
                ];
                packages = with pkgs; [
                  bashInteractive
                  coreutils
                  direnv
                  file
                  gnumake
                  openssh
                  which
                ];
                shell = pkgs.bashInteractive;
                uid = 1234;
                autoSubUidGidRange = true;

                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                ];

                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w"
                ];
              };

              # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
              services.openssh = {
                allowSFTP = true;
                settings.KbdInteractiveAuthentication = false;
                enable = true;
                # settings.ForwardX11 = false;
                settings.PasswordAuthentication = false;
                settings.PermitRootLogin = "yes";
                ports = [ 10022 ];
                authorizedKeysFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                ];
              };

              # X configuration
              services.xserver.enable = true;
              services.xserver.xkb.layout = "br";

              # services.xserver.displayManager.autoLogin.user = "nixuser";

              # Enable ssh
              # journalctl -u sshd -o json-pretty
              services.sshd.enable = true;

              nixpkgs.config.allowUnfree = true;

              # boot.readOnlyNixStore = true;
              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                package = pkgs.nix;
                registry.nixpkgs.flake = nixpkgs;
                nixPath = [ "nixpkgs=${pkgs.path}" ];
              };
              environment.etc."channels/nixpkgs".source = "${pkgs.path}";

              environment.systemPackages = with pkgs; [
              ];

              system.stateVersion = "23.11";
            }
          )
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      # Utilized by `nix run .#<name>`
      apps.x86_64-linux.vm = {
        type = "app";
        program = "${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm";
      };

      apps.x86_64-linux.default = {
        type = "app";
        program = "${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm";
      };

      packages.x86_64-linux.default = self.nixosConfigurations.vm.config.system.build.vm;

      devShells.x86_64-linux.default = pkgsAllowUnfree.mkShell {
        buildInputs = with pkgsAllowUnfree; [
          bashInteractive
          coreutils
          file
          nixpkgs-fmt
          which

          docker
        ];

        shellHook = ''
          export TMPDIR=/tmp

          # Too much hardcoded?
          export DOCKER_HOST=ssh://nixuser@localhost:10022

          test -d .profiles || mkdir -v .profiles

          test -L .profiles/dev \
          || nix develop --impure .# --profile .profiles/dev --command true             
        '';
      };
    };
}
