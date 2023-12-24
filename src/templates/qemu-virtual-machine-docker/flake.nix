{
  description = "VM";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
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
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i pedroalencarregis@hotmail.com";
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
                virtualisation.cores = 8; # Number of cores.
                virtualisation.graphics = false;

              };

              users.users.root = {
                password = "root";
                initialPassword = "root";
                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i pedroalencarregis@hotmail.com" }"
                ];
              };

              # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
              users.extraGroups.nixgroup.gid = 999;

              security.sudo.wheelNeedsPassword = false;
              users.users.nixuser = {
                isSystemUser = true;
                password = "";
                createHome = true;
                home = "/home/nixuser";
                homeMode = "0700";
                description = "The VM tester user";
                group = "nixgroup";
                extraGroups = [
                  "kvm"
                  "libvirtd"
                  "qemu-libvirtd"
                  "wheel"
                  "docker"
                ];
                packages = with pkgs; [
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
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i pedroalencarregis@hotmail.com" }"
                ];

                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i pedroalencarregis@hotmail.com"
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
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i pedroalencarregis@hotmail.com" }"
                ];
              };

              # X configuration
              services.xserver.enable = true;
              services.xserver.layout = "br";

              # Enable ssh
              services.sshd.enable = true;

              # Included packages here
              nixpkgs.config.allowUnfree = true;
              nix = {
                # package = nixpkgs.pkgs.nix;
                extraOptions = "experimental-features = nix-command flakes";
                readOnlyStore = true;
              };
              environment.systemPackages = with pkgs; [
              ];

              system.stateVersion = "22.11";
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
          export DOCKER_HOST=ssh://nixuser@localhost:2200
        '';
      };
    };
}
