{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b' \
    --override-input flake-utils 'github:numtide/flake-utils/5aed5285a952e0b949eb3ba02c12fa4fcfef535f'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
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

        apps.default = {
          type = "app";
          program = "${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm";
        };

        formatter = pkgsAllowUnfree.nixpkgs-fmt; # nix fmt

        devShells.default = pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            coreutils
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
        # About system and maybe --impure
        # https://www.youtube.com/watch?v=90aB_usqatE&t=3483s
        system = builtins.currentSystem;

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
                package = pkgs.nixVersions.nix_2_10;
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

              system.stateVersion = "22.11";
            })

          { nixpkgs.overlays = [ self.overlays.default ]; }

        ];

        specialArgs = { inherit nixpkgs allAttrs; };

      };
    };
}
