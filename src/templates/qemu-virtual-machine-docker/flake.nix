{
  description = "VM";

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

              users.users.root = {
                password = "root";
                initialPassword = "root";
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
                kbdInteractiveAuthentication = false;
                enable = true;
                forwardX11 = false;
                passwordAuthentication = false;
                permitRootLogin = "yes";
                ports = [ 10022 ];
                authorizedKeysFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                ];
              };

              # X configuration
              services.xserver.enable = true;
              services.xserver.layout = "br";

              # services.xserver.displayManager.autoLogin.user = "nixuser";

              # Enable ssh
              # journalctl -u sshd -o json-pretty
              services.sshd.enable = true;

              nixpkgs.config.allowUnfree = true;

              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                package = pkgs.nix;
                readOnlyStore = true;
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
        '';
      };
    };
}
