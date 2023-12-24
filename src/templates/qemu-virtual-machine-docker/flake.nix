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
                virtualisation.cores = 8; # Number of cores.
                virtualisation.graphics = false;

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

              # Included packages here
              nixpkgs.config.allowUnfree = true;

              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                package = pkgs.nixVersions.nix_2_10;
                readOnlyStore = true;
                registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
                /*
                  echo $NIX_PATH
                  nixpkgs=/nix/store/mzdg05xhylnw743qapcd80c10f0vfbnl-059pc9vdgzwgd0xsm2i8hsysxlxs2al7-source

                  nix eval --raw nixpkgs#pkgs.path
                  /nix/store/375da3gc24ijmjz622h0wdsqnzvkajbh-b1l1kkp1g07gy67wglfpwlwaxs1rqkpx-source

                  nix-info -m | grep store | cut -d'`' -f2

                  nix eval --impure --expr '<nixpkgs>'
                  nix eval --impure --raw --expr '(builtins.getFlake "nixpkgs").outPath'
                  nix-instantiate --eval --attr 'path' '<nixpkgs>'
                  nix-instantiate --eval --attr 'pkgs.path' '<nixpkgs>'
                  nix-instantiate --eval --expr 'builtins.findFile builtins.nixPath "nixpkgs"'

                  nix eval nixpkgs#path
                  nix eval nixpkgs#pkgs.path
                */
                nixPath = ["nixpkgs=${pkgs.path}"]; # TODO: test it
                /*
                nixPath = [
                  "nixpkgs=/etc/channels/nixpkgs"
                  "nixos-config=/etc/nixos/configuration.nix"
                  # "/nix/var/nix/profiles/per-user/root/channels"
                ];
                */
              };

              # environment.etc."channels/nixpkgs".source = nixpkgs.outPath;
              # environment.etc."channels/nixpkgs".source = "${pkgs.path}";
              environment.etc."channels/nixpkgs".source = "${pkgs.path}";

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
            export DOCKER_HOST=ssh://nixuser@localhost:10022

            chmod -v 0600 id_ed25519

            ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
            # There could be an race condition in here?
            (ssh-add -l | grep -q "$(cat id_ed25519.pub)") || ssh-add id_ed25519

            ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null;
            ssh -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true'

            docker images
        '';
      };
    };
}
