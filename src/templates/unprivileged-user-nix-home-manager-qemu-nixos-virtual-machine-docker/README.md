


```bash
BUILD_ID=297111184
curl -L https://hydra.nixos.org/build/$BUILD_ID/download-by-type/file/binary-dist > nix \
&& (echo 7838348c0e560855921cfa97051161bd63e29ee7ef4111eedc77228e91772958'  'nix \
| sha256sum -c) \
&& chmod +x nix \
&& ./nix --version \
&& ./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
shell \
--ignore-environment \
--keep HOME \
--keep SHELL \
--keep USER \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#file \
nixpkgs#gnused \
nixpkgs#nix \
nixpkgs#gitMinimal \
nixpkgs#home-manager \
--command \
bash \
<<'COMMANDS'
# set -x

OLD_PWD=$(pwd)

# ! test -z "$USER" || exit 1
# id "$USER" &>/dev/null || exit 1

mkdir -pv /home/"$USER"/.config/home-manager && cd $_

cat << 'EOF' > flake.nix
{
  description = "A NixOS QEMU Virtual Machine with Docker, managed by Home Manager for an unprivileged user";
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd \
    --override-input home-manager 'github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9'
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, home-manager, ... }:
    let
      overlays.default = final: prev: {
        f00Bar = prev.hello;

        nixosConfiguration = nixpkgs.lib.nixosSystem {
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
                # boot.tmpOnTmpfs = true;
                # boot.tmpOnTmpfsSize = "95%";
                boot.tmp.useTmpfs = true;
                boot.tmp.tmpfsSize = "95%";

                users.users.root = {
                  password = "root";
                  # initialPassword = "root";
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
                  # kbdInteractiveAuthentication = false;
                  settings.KbdInteractiveAuthentication = false;
                  enable = true;
                  # forwardX11 = false;
                  settings.X11Forwarding = false;
                  # passwordAuthentication = false;
                  settings.PasswordAuthentication = false;
                  # permitRootLogin = "yes";
                  settings.PermitRootLogin = "yes";
                  ports = [ 10022 ];
                  authorizedKeysFiles = [
                    "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUPGFQFJxBEaoB+ammkgnvlz0SmUTNfMZ2lOmW2lM9w" }"
                  ];
                };

                # X configuration
                services.xserver.enable = true;
                # services.xserver.layout = "br";
                services.xserver.xkb.layout = "br";

                # services.xserver.displayManager.autoLogin.user = "nixuser";

                # Enable ssh
                # journalctl -u sshd -o json-pretty
                services.sshd.enable = true;

                nixpkgs.config.allowUnfree = true;
                boot.readOnlyNixStore = true; # TODO
                nix = {
                  extraOptions = "experimental-features = nix-command flakes";
                  package = pkgs.nix;
                  registry.nixpkgs.flake = nixpkgs;
                  nixPath = [ "nixpkgs=${pkgs.path}" ];
                };
                environment.etc."channels/nixpkgs".source = "${pkgs.path}";

                environment.systemPackages = with pkgs; [
                ];

                system.stateVersion = "25.05";
              }
            )
          ];
        };

        nixosConfigurationBuildVm = final.nixosConfiguration.config.system.build.vm;

        homeManagerVagrant = (home-manager.lib.homeManagerConfiguration {
          # inherit pkgs;
          pkgs = final;
          modules = [
            ({ pkgs, ... }:
              {
                home.stateVersion = "25.05";
                home.username = "vagrant";
                home.homeDirectory = "/home/vagrant";

                programs.home-manager = {
                  enable = true;
                };

                home.activation = {
                  startPythonHttpServer = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    "${pkgs.lib.getExe pkgs.curl}" localhost:6789 \
                    && echo 'Server is up' \
                    && exit 0

                    echo 'Starting server...'
                    "${pkgs.lib.getExe pkgs.python3}" -m http.server 6789 >&2 &
                  '';
                };

                home.packages = with pkgs; [
                  git
                  nix
                  zsh
                  direnv

                  hello
                  nano
                  file
                  which
                  f00Bar
                  final.nixosConfigurationBuildVm

                  (writeScriptBin "hms" ''
                    #! ${final.runtimeShell} -e
                      nix \
                      build \
                      --no-link \
                      --print-build-logs \
                      --print-out-paths \
                      "$HOME"'/.config/home-manager#homeConfigurations.'"$(id -un)".activationPackage

                      home-manager switch --flake "$HOME/.config/home-manager"#"$(id -un)"
                  '')
                ];

                nix = {
                  enable = true;
                  package = pkgs.nix;
                  # package = pkgs.nixVersions.nix_2_29;
                  extraOptions = ''
                    bash-prompt-prefix = (nix-develop:$name)\040
                    experimental-features = nix-command flakes
                    keep-build-log = true
                    keep-derivations = true
                    keep-env-derivations = true
                    keep-failed = true
                    keep-going = true
                    keep-outputs = true
                  '';
                  registry.nixpkgs.flake = nixpkgs;
                  # settings.flake-registry = "${flake-registry}/flake-registry.json";
                  nixPath = [ "nixpkgs=${pkgs.path}" ];
                };

                programs.zsh = {
                  enable = true;
                  enableCompletion = true;
                  dotDir = ".config/zsh";
                  autosuggestion.enable = true;
                  syntaxHighlighting.enable = true;
                  envExtra = ''
                    if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
                      . ~/.nix-profile/etc/profile.d/nix.sh
                    fi
                  '';
                  shellAliases = {
                    l = "ls -alh";
                  };
                  sessionVariables = {
                    # https://discourse.nixos.org/t/what-is-the-correct-way-to-set-nix-path-with-home-manager-on-ubuntu/29736
                    NIX_PATH = "nixpkgs=${final.path}";
                    LANG = "en_US.utf8";
                  };
                  oh-my-zsh = {
                    enable = true;
                    plugins = [
                      "colored-man-pages"
                      "colorize"
                      "direnv"
                      "zsh-navigation-tools"
                    ];
                    theme = "robbyrussell";
                  };
                };
              }
            )
          ];
          extraSpecialArgs = { nixpkgs = nixpkgs; };

        }).activationPackage;
      };

      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ]
          (system:
            function (import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [
                # inputs.something.overlays.default
                overlays.default
              ];
            }));

    in
    {
      packages = forAllSystems (pkgs: {
        inherit (pkgs)
          f00Bar
          nixosConfigurationBuildVm
          ;
        default = pkgs.homeManagerVagrant;
      });

      checks = forAllSystems (pkgs: {
        inherit (pkgs)
          f00Bar
          homeManagerVagrant
          nixosConfigurationBuildVm
          ;
        default = pkgs.homeManagerVagrant;
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);

      homeConfigurations.vagrant = forAllSystems (pkgs: pkgs.homeManagerVagrant);
    };
}
EOF

test -f /home/"$USER"/.config/home-manager/flake.nix || echo 'not found flake.nix'

# sed -i 's/.*userName = ".*";/userName = "'"$USER"'";/' /home/"$USER"/.config/home-manager/flake.nix

git config init.defaultBranch \
|| git config --global init.defaultBranch main

git init \
&& git add .

"$OLD_PWD"/nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--option warn-dirty false \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd \
--override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9

# Even removing all packages it still making home-manager break, why?
"$OLD_PWD"/nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--option warn-dirty false \
profile \
remove \
'.*'

# It looks like the symbolic link breaks home-manager, why?
ls -ahl "$HOME"/.local/state/nix/profiles/profile || true
file "$HOME"/.local/state/nix/profiles || true
test -d "$HOME"/.local/state/nix/profiles && rm -frv "$HOME"/.local/state/nix/profiles

git add .

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

home-manager \
switch \
-b backup \
--print-build-logs \
--option warn-dirty false

/home/"$USER"/.nix-profile/bin/zsh \
-lc 'nix flake --version' \
|| echo 'The instalation may have failed!'


test -L /home/"$USER"/.nix-profile/bin/zsh \
&& "$OLD_PWD"/nix \
store \
gc \
--option keep-build-log false \
--option keep-derivations false \
--option keep-env-derivations false \
--option keep-failed false \
--option keep-going false \
--option keep-outputs true \
&& "$OLD_PWD"/nix \
store \
optimise

# test -L /home/"$USER"/.nix-profile/bin/zsh \
# && test -f "$OLD_PWD"/nix && rm -v "$OLD_PWD"/nix

# For some reason in the first execution it fails
# needing re loging, but this workaround allows a
# way better first developer experience.
/home/"$USER"/.nix-profile/bin/zsh \
-lc 'home-manager switch 1> /dev/null 2> /dev/null' 2> /dev/null || true
COMMANDS

./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--no-use-registries \
shell \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd#bashInteractive \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd#home-manager \
--command \
bash \
-c \
'
/home/"$USER"/.nix-profile/bin/zsh \
-cl \
"
nix --version \
&& nix flake --version \
&& home-manager --version \
&& hello \
&& home-manager switch
"
'
```



068012910f0e46501d193b9873c2c50744cc6875b3e309ec9dd1c9326be9bcc6

