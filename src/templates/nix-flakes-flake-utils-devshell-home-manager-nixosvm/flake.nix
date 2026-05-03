{
  description = "It is an nix flake example of a devShell and uses flake-utils support multiple architectures";
  /*
    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input home-manager 'github:nix-community/home-manager/f63d0fe9d81d36e5fc95497217a72e02b8b7bcab' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'    
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, home-manager, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        f00Bar = prev.hello;

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
              && nix flake check --verbose '.#' \
              && home-manager build --flake '.#vagrant' --no-out-link --dry-run \
              && nix build --no-link --print-build-logs --print-out-paths \
                   '.#homeConfigurations.vagrant.activationPackage'
            '';
          } // { meta.mainProgram = name; };

        hms = (final.writeScriptBin "hms" ''
          #! ${final.runtimeShell} -e
            nix \
            build \
            --no-link \
            --print-build-logs \
            --print-out-paths \
            "$HOME"'/.config/home-manager#homeConfigurations.'"$(id -un)".activationPackage

            home-manager switch --flake "$HOME/.config/home-manager"#"$(id -un)"
        '');

        runNixOSVm = let name = "run-nixosvm"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [
              nixOsVm
            ];
            text = ''
              ${ final.nixOsVm.meta.mainProgram }
            '';
          } // { meta.mainProgram = name; };

        nixOsVmWithDocker = nixpkgs.lib.nixosSystem {
          # system = "x86_64-linux";
          system = final.stdenv.hostPlatform.system;
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

                # journalctl -u sshd -o json-pretty
                services.sshd.enable = true;

                nixpkgs.config.allowUnfree = true;
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

        nixOsVm = final.nixOsVmWithDocker.config.system.build.vm;

        hm =
          let
            userName = "vagrant";
            homeDirectory = "/home/${userName}";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = final;
            modules = [
              ({ config, pkgs, ... }:
                {
                  home.stateVersion = "25.11";
                  home.username = "${userName}";
                  home.homeDirectory = "${homeDirectory}";

                  programs.home-manager.enable = true;

                  home.activation = {
                    startPythonHttpServer = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                      "${pkgs.lib.getExe pkgs.runNixOSVm}"
                    '';
                  };

                  home.packages = with pkgs; [
                    git
                    nix
                    nano
                    file
                    which                    
                    # path # TODO: Why it breaks??
                    zsh
                    direnv
                    starship

                    f00Bar
                    hms
                    runNixOSVm
                  ];

                  nix = {
                    enable = true;
                    package = pkgs.nix;
                    # package = pkgs.nixVersions.nix_2_29;
                    extraOptions = ''
                      experimental-features = nix-command flakes
                    '';
                    settings = {
                      bash-prompt-prefix = "(nix:$name)\\040";
                      keep-build-log = true;
                      keep-derivations = true;
                      keep-env-derivations = true;
                      keep-failed = true;
                      keep-going = true;
                      keep-outputs = true;
                      nix-path = "nixpkgs=flake:nixpkgs";
                      tarball-ttl = 2419200; # 60 * 60 * 24 * 7 * 4 = one month
                    };
                    registry.nixpkgs.flake = nixpkgs;
                  };

                  programs.zsh = {
                    enable = true;
                    enableCompletion = true;
                    dotDir = "${config.home.homeDirectory}";
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
                      NIX_PATH = "nixpkgs=${pkgs.path}";
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
          };

        hmActivationPackage = final.hm.activationPackage;

        homeManager = home-manager.packages.${final.stdenv.hostPlatform.system}.home-manager;
      };
    } //
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs {
            overlays = [ self.overlays.default ];
            system = suportedSystem;
            config.allowUnfreePredicate = (_: true);
            config.android_sdk.accept_license = true;
            config.allowUnfree = true;
            config.cudaSupport = false;
          };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          apps = {
            allTests = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.allTests}";
              meta.description = "Run all tests";
            };
          };

          packages = {
            inherit (pkgsAllowUnfree)
              allTests
              f00Bar
              # hm
              hmActivationPackage
              ;
            default = pkgsAllowUnfree.hmActivationPackage;
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            packages = with pkgsAllowUnfree; [
              # home-manager
              homeManager
              f00Bar
              python313
              uv
              bashInteractive
              pleaseKeepMyInputs
            ];

            shellHook = ''
              test -d .profiles || mkdir -v .profiles
              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build --impure .#devShells."$system".default --out-link .profiles/dev-shell-"$system"-default

              home-manager --version
            '';
          };

          checks = {
            inherit (pkgsAllowUnfree)
              allTests
              f00Bar
              hmActivationPackage
              ;
            default = pkgsAllowUnfree.hmActivationPackage;
          };
        }
      )

    //
    { homeConfigurations.vagrant = (import nixpkgs { overlays = [ self.overlays.default ]; system = "aarch64-linux"; }).hm; }
    //
    { homeConfigurations.vagrant = (import nixpkgs { overlays = [ self.overlays.default ]; system = "x86_64-linux"; }).hm; };
  # flake-utils.lib.eachSystem suportedSystems
  #   (suportedSystem:
  #     {
  #       # home-manager build --flake '.#vagrant' --no-out-link --dry-run
  #       # nix build --no-link --print-build-logs --print-out-paths '.#homeConfigurations.vagrant.activationPackage'
  #       # homeConfigurations.vagrant = self.outputs.packages.x86_64-linux.hm;

  #       homeConfigurations.vagrant = (import nixpkgs { overlays = [ self.overlays.default ]; system = suportedSystem; }).hm;
  #     });
}
