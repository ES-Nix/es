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

    25.05:
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/40ee5e1944bebdd128f9fbada44faefddfde29bd'

    25.11:

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852'
    
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = all@{ self, nixpkgs, ... }:
    let
      overlays.default = nixpkgs.lib.composeManyExtensions [
        (final: prev: {
          fooBar = prev.hello;

          allTests = let name = "all-tests"; in final.writeShellApplication
            {
              name = name;
              runtimeInputs = with final; [ ];
              text = ''
                nix fmt . \
                && nix flake show '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#' \
                && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
                && nix develop '.#' --command sh -c 'true' \
                && nix flake check --all-systems --verbose '.#'
              '';
            } // { meta.mainProgram = name; };

          healthCheck = let name = "health-check"; in final.writeShellApplication
            {
              name = name;
              runtimeInputs = with final; [ openssh ];
              text = ''
                ssh \
                  -o ConnectTimeout=1 \
                  -oStrictHostKeyChecking=accept-new \
                  -p 10022 \
                  nixuser@localhost \
                    -- \
                    sh <<<'docker images' 1>/dev/null 2>/dev/null
              '';
            } // { meta.mainProgram = name; };

          cleanPort = let name = "clean-port"; in final.writeShellApplication
            {
              name = name;
              runtimeInputs = with final; [ coreutils lsof nixOsVm ];
              text = ''
                lsof -i :10022 \
                && kill "$(pgrep .qemu-system)" \
                || echo 'No QEMU process running.'          
              '';
            } // { meta.mainProgram = name; };

          qdocker = let name = "qdocker"; in final.writeShellApplication
            {
              name = name;
              runtimeInputs = with final; [
                bashInteractive
                nixOsVm
                docker
                healthCheck
                cleanPort
              ];
              text = ''
                # set +x

                if ! health-check 
                then
                  clean-port 
                  "${ final.nixOsVm.meta.mainProgram }" 

                  chmod -v 0600 id_ed25519 \
                  && { ssh-add -l 1> /dev/null 2> /dev/null ; test $? -eq 2 && eval "$(ssh-agent -s)"; } || true \
                  && { ssh-add -L | grep -q "$(cat id_ed25519.pub)" || ssh-add -v id_ed25519; } \
                  && { ssh-add -L | grep -q "$(cat id_ed25519.pub)" || echo 'erro in ssh-add -L'; } \
                  && { ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null  || true; } \
                  && for i in {1..600}; do
                    ssh \
                        -o ConnectTimeout=1 \
                        -oStrictHostKeyChecking=accept-new \
                        -p 10022 \
                        nixuser@localhost \
                          -- \
                          sh <<<'docker images' 1>/dev/null 2>/dev/null \
                    && break

                    ! ((i % 11)) && echo Iteration "$i", date "$(date +'%d/%m/%Y %H:%M:%S:%3N')"
                    sleep 0.1
                  done \
                  && echo 'Connected to VM via SSH.'
                fi

                export DOCKER_HOST=ssh://nixuser@localhost:10022
                docker "$@"
              '';
            } // { meta.mainProgram = name; };

          nixOsVm = self.nixosConfigurations.nixOsVmWithDocker.config.system.build.vm;
        })
      ];

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        # system = "aarch64-linux";
        overlays = [ overlays.default ];
        config = { allowUnfree = true; };
      };
    in
    {
      overlays.default = overlays.default;

      nixosConfigurations.nixOsVmWithDocker = nixpkgs.lib.nixosSystem {
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
                virtualisation.diskSize = 1024 * 10; # Use maximum of hard disk MiB memory.
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

              system.stateVersion = "25.11";
            }
          )
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      apps.x86_64-linux = {
        allTests = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.allTests}";
          meta.description = "Run all tests for this flake";
        };
        default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.nixOsVm}";
          meta.description = "QEMU NixOS Virtual Machine with Docker enabled";
        };
        qdocker = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.qdocker}";
          meta.description = "Connect to the QEMU NixOS Virtual Machine with Docker enabled";
        };
      };

      packages.x86_64-linux = {
        inherit (pkgs)
          allTests
          fooBar
          nixOsVm
          qdocker
          ;
        default = pkgs.nixOsVm;
      };

      checks.x86_64-linux = {
        inherit (pkgs)
          allTests
          fooBar
          nixOsVm
          qdocker
          ;
        default = pkgs.nixOsVm;
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          bashInteractive
          coreutils
          file
          nixpkgs-fmt
          which

          qdocker
          fooBar
        ];

        shellHook = ''
          export TMPDIR=/tmp

          test -d .profiles || mkdir -v .profiles
          test -L .profiles/dev \
          || nix develop --impure .# --profile .profiles/dev --command true

          # Too much hardcoded?
          # export DOCKER_HOST=ssh://nixuser@localhost:10022
        '';
      };
    };
}
