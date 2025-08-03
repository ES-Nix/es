{
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334 \
    --override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }:
    let
      inherit (self) outputs;
      overlays.default = final: prev: {
        inherit self final prev;

        f00Bar = prev.hello;

        nf00 = (nixpkgs.lib.nixosSystem {
          system = final.system;
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

                    virtualisation.useNixStoreImage = false; # TODO: hardening
                    virtualisation.writableStore = true; # TODO: hardening

                    programs.dconf.enable = true;

                    virtualisation.memorySize = 1024 * 5; # Use MiB memory.
                    virtualisation.diskSize = 1024 * 25; # Use MiB memory.
                    virtualisation.cores = 8; # Number of cores.
                    virtualisation.graphics = true;

                    virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                    virtualisation.qemu.options = [
                      # Better display option
                      # TODO: -display sdl,gl=on
                      # https://gitlab.com/qemu-project/qemu/-/issues/761
                      "-vga virtio"
                      "-display gtk,zoom-to-fit=false"
                      # Enable copy/paste
                      # https://www.kraxel.org/blog/2021/05/qemu-cut-paste/
                      "-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on"
                      "-device virtio-serial-pci"
                      "-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0"
                    ];
                  };

                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;

                security.sudo.wheelNeedsPassword = false; # TODO: hardening
                users.users.nixuser = {
                  isSystemUser = true; # TODO: hardening
                  password = "101"; # TODO: hardening
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "kvm"
                    "libvirtd"
                    "nixgroup"
                    "podman"
                    "qemu-libvirtd"
                    "root"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    btop
                    starship
                    foo-bar
                  ];
                  shell = pkgs.zsh;
                  uid = 1234;
                  autoSubUidGidRange = true;
                };

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
                  fonts = with pkgs; [
                    powerline
                    powerline-fonts
                  ];
                  enableDefaultFonts = true;
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

                services.sshd.enable = true;

                # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
                services.openssh = {
                  allowSFTP = true;
                  kbdInteractiveAuthentication = false;
                  enable = true;
                  forwardX11 = false;
                  passwordAuthentication = false;
                  permitRootLogin = "yes";
                  ports = [ 10022 ];
                };

                # https://nixos.wiki/wiki/Libvirt
                # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
                boot.extraModprobeConfig = "options kvm_intel nested=1";

                services.qemuGuest.enable = true;

                services.xserver.enable = true;
                services.xserver.layout = "br";

                services.xserver.displayManager.autoLogin.user = "nixuser";
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

                services.spice-vdagentd.enable = true; # TODO: For copy/paste to work

                nix = {
                  extraOptions = "experimental-features = nix-command flakes";
                  # package = pkgs.nixVersions.nix_2_10;
                  readOnlyStore = true;
                  registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
                  nixPath = [ "nixpkgs=${pkgs.path}" ];
                };

                environment.etc."channels/nixpkgs".source = "${pkgs.path}";

                environment.systemPackages = with pkgs; [
                  bashInteractive
                  direnv
                  fzf
                  jq
                  neovim
                  nix-direnv
                  oh-my-zsh
                  openssh
                  zsh
                  zsh-autosuggestions
                  zsh-completions
                ];

                system.stateVersion = "25.05";
              })

            { nixpkgs.overlays = [ overlays.default ]; }

          ];
          specialArgs = { inherit nixpkgs inputs; };
        });

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

                home.packages = with pkgs; [
                  git
                  nix
                  zsh

                  hello
                  nano
                  file
                  which
                  f00Bar
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
                    experimental-features = nix-command flakes
                  '';
                  registry.nixpkgs.flake = nixpkgs;
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
                      # "direnv"
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
          ;
        default = pkgs.homeManagerVagrant;
      });

      checks = forAllSystems (pkgs: {
        inherit (pkgs)
          f00Bar
          homeManagerVagrant
          ;
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);

      homeConfigurations = forAllSystems (pkgs: pkgs.homeManagerVagrant);

      nixosConfigurations.nixos = forAllSystems (pkgs: pkgs.nf00);
    };
}
