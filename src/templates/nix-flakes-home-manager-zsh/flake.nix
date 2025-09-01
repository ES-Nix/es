{
  description = "Home Manager configuration of nixuser";
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/d12251ef6e8e6a46e05689eeccd595bdbd3c9e60 \
    --override-input home-manager github:nix-community/home-manager/a631666f5ec18271e86a5cde998cba68c33d9ac6

    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
    --override-input home-manager github:nix-community/home-manager/f33900124c23c4eca5831b9b5eb32ea5894375ce

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input home-manager 'github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9'
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      userName = "vagrant";
      homeDirectory = "/home/${userName}";

      system = "x86_64-linux";
      # pkgs = nixpkgs.legacyPackages.${system};
      overlays.default = nixpkgs.lib.composeManyExtensions [
        (final: prev: {
          fooBar = prev.hello;

          nixos-vm = nixpkgs.lib.nixosSystem {
            system = prev.system;
            modules = [
              ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
                {
                  # Internationalisation options
                  i18n.defaultLocale = "en_US.UTF-8";
                  console.keyMap = "br-abnt2";

                  # Set your time zone.
                  time.timeZone = "America/Recife";

                  # Why
                  # nix flake show --impure .#
                  # break if it does not exists?
                  # Use systemd boot (EFI only)
                  boot.loader.systemd-boot.enable = true;
                  fileSystems."/" = { device = "/dev/hda1"; };

                  virtualisation.vmVariant =
                    {
                      virtualisation.docker.enable = true;
                      virtualisation.podman.enable = true;

                      virtualisation.memorySize = 1024 * 9; # Use MiB memory.
                      virtualisation.diskSize = 1024 * 50; # Use MiB memory.
                      virtualisation.cores = 7; # Number of cores.
                      virtualisation.graphics = true;

                      virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                      virtualisation.qemu.options = [
                        # https://www.spice-space.org/spice-user-manual.html#Running_qemu_manually
                        # remote-viewer spice://localhost:3001

                        # "-daemonize" # How to save the QEMU PID?
                        "-machine vmport=off"
                        "-vga qxl"
                        "-spice port=3001,disable-ticketing=on"
                        "-device virtio-serial"
                        "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                        "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                      ];

                      virtualisation.useNixStoreImage = false; # TODO: hardening
                      virtualisation.writableStore = true; # TODO: hardening
                    };
                  security.sudo.wheelNeedsPassword = false; # TODO: hardening
                  # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                  users.extraGroups.nixgroup.gid = 999;
                  users.users.nixuser = {
                    isSystemUser = true;
                    password = "1"; # TODO: hardening
                    createHome = true;
                    home = "/home/nixuser";
                    homeMode = "0700";
                    description = "The VM tester user";
                    group = "nixgroup";
                    extraGroups = [
                      "docker"
                      "wheel"
                    ];
                    packages = with pkgs; [
                      file
                      firefox
                      git
                      jq
                      lsof
                      findutils
                      dive
                      fooBar
                      starship
                      direnv
                      fzf
                      sudo
                      which
                    ];
                    shell = pkgs.zsh;
                    uid = 1234;
                    autoSubUidGidRange = true;
                  };

                  # https://github.com/NixOS/nixpkgs/blob/3a44e0112836b777b176870bb44155a2c1dbc226/nixos/modules/programs/zsh/oh-my-zsh.nix#L119
                  # https://discourse.nixos.org/t/nix-completions-for-zsh/5532
                  # https://github.com/NixOS/nixpkgs/blob/09aa1b23bb5f04dfc0ac306a379a464584fc8de7/nixos/modules/programs/zsh/zsh.nix#L230-L231
                  programs.zsh = {
                    enable = true;
                    shellAliases = {
                      vim = "nvim";
                    };

                    enableCompletion = true;
                    autosuggestions.enable = true;
                    syntaxHighlighting.enable = true;
                    interactiveShellInit = ''
                      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
                      export ZSH_THEME="agnoster"
                      export ZSH_CUSTOM=${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions
                      plugins=(
                                colored-man-pages
                                docker
                                git
                                #zsh-autosuggestions # Why this causes an warn?
                                #zsh-syntax-highlighting
                              )

                      # https://nixos.wiki/wiki/Fzf
                      source $ZSH/oh-my-zsh.sh

                      export DIRENV_LOG_FORMAT=""
                      eval "$(direnv hook zsh)"

                      eval "$(starship init zsh)"

                      export FZF_BASE=$(fzf-share)
                      source "$(fzf-share)/completion.zsh"
                      source "$(fzf-share)/key-bindings.zsh"
                    '';

                    ohMyZsh.custom = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
                    promptInit = "";
                  };

                  fonts = {
                    fontDir.enable = true;
                    packages = with pkgs; [
                      powerline
                      powerline-fonts
                    ];
                    enableDefaultPackages = true;
                    enableGhostscriptFonts = true;
                  };

                  # Hack to fix annoying zsh warning, too overkill probably
                  # https://www.reddit.com/r/NixOS/comments/cg102t/how_to_run_a_shell_command_upon_startup/eudvtz1/?utm_source=reddit&utm_medium=web2x&context=3
                  # https://stackoverflow.com/questions/638975/how-wdo-i-tell-if-a-regular-file-does-not-exist-in-bash#comment25226870_638985
                  systemd.user.services.fix-zsh-warning = {
                    script = ''
                      test -f /home/nixuser/.zshrc || touch /home/nixuser/.zshrc && chown nixuser: -Rv /home/nixuser
                    '';
                    wantedBy = [ "default.target" ];
                  };

                  services.xserver.enable = true;
                  services.xserver.xkb.layout = "br";
                  services.displayManager.autoLogin.user = "nixuser";
                  services.xserver.displayManager.sessionCommands = ''
                    exo-open \
                      --launch TerminalEmulator \
                      --zoom=-3 \
                      --geometry 154x40
                  '';

                  # https://nixos.org/manual/nixos/stable/#sec-xfce
                  services.xserver.desktopManager.xfce.enable = true;
                  services.xserver.desktopManager.xfce.enableScreensaver = false;
                  services.xserver.videoDrivers = [ "qxl" ];
                  services.spice-vdagentd.enable = true; # For copy/paste to work

                  nix.extraOptions = "experimental-features = nix-command flakes";

                  environment.systemPackages = with pkgs; [
                  ];

                  system.stateVersion = "25.05";
                })

              { nixpkgs.overlays = [ overlays.default ]; }
            ];
            specialArgs = { inherit nixpkgs; };
          };

          myvm = final.nixos-vm.config.system.build.vm;

          automatic-vm = prev.writeShellApplication {
            name = "run-nixos-vm";
            runtimeInputs = with final; [ curl virt-viewer ];
            text = ''
              export VNC_PORT=3001

              ${final.lib.getExe final.myvm} & PID_QEMU="$!"

              for _ in {0..50}; do
                if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
                then
                  break
                fi
                # date +'%d/%m/%Y %H:%M:%S:%3N'
                sleep 0.1
              done;

              remote-viewer spice://localhost:"$VNC_PORT"

              kill $PID_QEMU
            '';
          };

          hm = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ({ pkgs, ... }:
                {
                  home.stateVersion = "25.05";
                  home.username = "${userName}";
                  home.homeDirectory = "${homeDirectory}";

                  programs.home-manager = {
                    enable = true;
                  };

                  home.packages = with pkgs; [
                    direnv
                    git
                    nix
                    zsh
                    fooBar
                    automatic-vm
                  ];

                  nix = {
                    enable = true;
                    package = pkgs.nix; # pkgs.nixVersions.latest
                    extraOptions = ''
                      experimental-features = nix-command flakes
                    '';
                    registry.nixpkgs.flake = nixpkgs;
                    settings = {
                      bash-prompt-prefix = "(nix:$name)\\040";
                      keep-derivations = true;
                      keep-env-derivations = true;
                      keep-failed = true;
                      keep-going = true;
                      keep-outputs = true;
                      nix-path = "nixpkgs=flake:nixpkgs";
                      tarball-ttl = 2419200; # 60 * 60 * 24 * 7 * 4 = one month
                    };
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
                      # NIX_PATH = "nixpkgs=${pkgs.path}";
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
        })
      ];

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlays.default ];
      };
    in
    {
      formatter."${system}" = pkgs.nixpkgs-fmt;
      devShells."${system}".default = pkgs.mkShell {
        packages = [
        ];
        shellHook = ''
          test -d .profiles || mkdir -v .profiles
          test -L .profiles/dev \
          || nix develop .# --impure --profile .profiles/dev --command true        
        '';
      };

      packages."${system}" = {
        default = self.homeConfigurations."${userName}".activationPackage;
        automatic-vm = pkgs.automatic-vm;
      };
      checks."${system}" = {
        inherit (pkgs)
          fooBar
          ;
        default = pkgs.fooBar;
        aaaa = self.homeConfigurations."${userName}".activationPackage;
      };
      apps."${system}" = {
        automatic-vm = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
          meta.description = "Run the automatic-vm";
        };
      };

      homeConfigurations."${userName}" = pkgs.hm;
    };
}
