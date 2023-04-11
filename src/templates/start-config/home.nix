{ pkgs, ... }:

{

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  # home.username = "ubuntu";
  # home.homeDirectory = "/home/ubuntu";

  home.packages = with pkgs; [
    # Graphical packages
    #anydesk
    #blender
    #brave
    #dbeaver
    #discord
    #gimp
    #gitkraken
    #google-chrome
    #inkscape
    #insomnia
    #jetbrains.pycharm-community
    #keepassxc
    #kolourpaint
    #libreoffice
    #obsidian
    #okular
    #peek
    #postman
    #qbittorrent
    #slack
    #spotify
    #tdesktop
    #virt-manager
    #vlc
    #vscodium

    # sudo $(which lshw) -C display
    # sudo dmesg | grep drm
    # glxgears -info
    # lspci | grep -i vga
    # mesa
    # mesa-demos
    # libglvnd # find / -name 'libGL.so' 2>/dev/null
    # vulkan-loader
    # vulkan-headers
    # mesa_drivers
    # linuxPackages.nvidia_x11
    # cudatoolkit
    # cudatoolkit.lib
    # mpi

    #
    # steam-run

    xorg.xclock
    hello
    sl
#    asciiquarium
#    figlet
#    cowsay
#    ponysay
#    cmatrix

    # Just enabling it is ok, and might be better
    # nix
    # nixVersions.nix_2_10

    # pciutils # lspci and others
    # coreboot-utils

    # # TODO: testar com o zsh
    ## bashInteractive # https://www.reddit.com/r/NixOS/comments/zx4kmh/alpinewsl_home_manager_bash_issue/
    awscli
    coreutils
    binutils
    utillinux
    xorg.xkill
    glibc.bin
    patchelf
    gparted
    # glxinfo
    file
    findutils
    gnugrep
    gnumake
    gnused
    gawk
    hexdump
    which
    xz
    exfat
    procps
    curl
    wget
    lsof
    tree
    killall
    nmap
    netcat
    nettools
    ripgrep
    tmate
    strace
    # ptrace
    traceroute
    man
    man-db
    (aspellWithDicts (d: with d; [ de en pt_BR ])) # nix repl --expr 'import <nixpkgs> {}' <<<'builtins.attrNames aspellDicts' | tr ' ' '\n'
    gnome.simple-scan
    imagemagick
    nix-prefetch-git
    nixfmt
    hydra-check
    nixos-option
    shellcheck

    nano
    neovim

    fontconfig
    # fontforge-gtk # TODO: testar fontes usando esse programa
    # pango

    # arphic-ukai
    # arphic-uming
    # aurulent-sans
    # comic-relief
    # corefonts           # Microsoft free fonts
    # dejavu_fonts
    # dina-font
    # fira                # Monospace
    # fira-code
    # fira-code-symbols
    # font-awesome # font-awesome-ttf, font-awesome_4
    # freefont_ttf
    # hack-font
    # hasklig
    # inconsolata         # Monospace
    # ionicons
    # lato
    # liberation_ttf
    # lineicons
    # montserrat
    # mplus-outline-fonts
    nerdfonts # Really big, but only with this font some issues with starship were fixed.
    # noto-fonts
    # noto-fonts-emoji
    # noto-fonts-extra
    powerline
    powerline-fonts
    # source-han-sans-japanese
    # source-han-sans-korean
    # source-han-sans-simplified-chinese
    # source-han-sans-traditional-chinese
    # source-sans
    # source-sans-pro
    # sudo-font
    # symbola
    # twemoji-color-font
    # ubuntu_font_family
    # unifont             # International languages
    # wqy_microhei
    # wqy_zenhei
    # xkcd-font

    # (nerdfonts.override { fonts = [ "FiraCode"]; })
    #      (
    #        nerdfonts.override {
    #          fonts = [
    #            "AnonymousPro"
    #            "DroidSansMono"
    #            "FiraCode"
    #            "JetBrainsMono"
    #            "Noto"
    #            "Terminus"
    #            "Hack"
    #            "Ubuntu"
    #            "UbuntuMono"
    #          ];
    #        }
    #      )

    # zsh-nix-shell
    # zsh-powerlevel10k
    # zsh-powerlevel9k
    # zsh-syntax-highlighting

    oh-my-zsh
    # zsh-completions-latest

    # gcc
    # gdb
    # clang
    # rustc
    # python3Full
    python3
    # julia-bin

    graphviz # dot command comes from here
    jq
    unixtools.xxd

    gzip
    # unrar
    unzip
    gnutar

    btop
    htop
    asciinema
    git
    openssh
    # sshfs # TODO: testar

    # #podman
    # runc
    # skopeo
    # conmon
    # slirp4netns
    # shadow

      (
        writeScriptBin "ix" ''
         #! ${pkgs.runtimeShell} -e
           "$@" | "curl" -F 'f:1=<-' ix.io
        ''
      )

      (
        writeScriptBin "fix-kvm" ''
         #! ${pkgs.runtimeShell} -e

            echo "Start kvm stuff..." \
            && getent group kvm || sudo groupadd kvm \
            && sudo usermod --append --groups kvm "$USER" \
            && echo "End kvm stuff!"
        ''
      )

      (
        writeScriptBin "erw" ''
         #! ${pkgs.runtimeShell} -e
         echo "$(readlink -f "$(which $1)")"
       ''
       )

      (
        writeScriptBin "crw" ''
         #! ${pkgs.runtimeShell} -e
         cat "$(readlink -f "$(which $1)")"
       ''
      )

      (
        writeScriptBin "myexternalip" ''
         #! ${pkgs.runtimeShell} -e
         # https://askubuntu.com/questions/95910/command-for-determining-my-public-ip#comment1985064_712144

         curl https://checkip.amazonaws.com
       ''
      )

      (
        writeScriptBin "mynatip" ''
         #! ${pkgs.runtimeShell} -e
            # https://unix.stackexchange.com/a/569306
            # https://serverfault.com/a/256506

            NETWORK_INTERFACE_NAME=$(route | awk '
                    BEGIN           { min = -1 }
                    $1 == "default" {
                                        if (min < 0  ||  $5 < min) {
                                            min   = $5
                                            iface = $8
                                        }
                                    }
                    END             {
                                        if (iface == "") {
                                            print "No \"default\" route found!" > "/dev/stderr"
                                            exit 1
                                        } else {
                                            print iface
                                            exit 0
                                        }
                                    }
                    '
            )

            ip addr show dev $NETWORK_INTERFACE_NAME | grep "inet " | awk '{ print $2 }' | cut -d'/' -f1
       ''
      )

      (
        writeScriptBin "generate-new-ed25519-key-pair" ''
         #! ${pkgs.runtimeShell} -e

         ssh-keygen \
         -t ed25519 \
         -C "$(git config user.email)" \
         -f "$HOME"/.ssh/id_ed25519 \
         -N "" \
         && echo \
         && cat "$HOME"/.ssh/id_ed25519.pub \
         && echo
        ''
      )

      (
        writeScriptBin "nfm" ''
          #! ${pkgs.runtimeShell} -e
          nix flake metadata $1 --json | jq -r '.url'
        ''
      )

      (
        writeScriptBin "build-pulling-all-from-cache" ''
         #! ${pkgs.runtimeShell} -e

            set -x

            export NIXPKGS_ALLOW_UNFREE=1

            nix \
            --option eval-cache false \
            --option extra-trusted-public-keys binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg= \
            --option extra-substituters https://playing-bucket-nix-cache-test.s3.amazonaws.com \
            build \
            --impure \
            --keep-failed \
            --max-jobs 0 \
            --no-link \
            --print-build-logs \
            --print-out-paths \
            ~/.config/nixpkgs#homeConfigurations."$(id -un)"-"$(hostname)".activationPackage
        ''
      )

      (
        writeScriptBin "build-in-local-remote-builder" ''
         #! ${pkgs.runtimeShell} -e

            set -x

            export NIXPKGS_ALLOW_UNFREE=1

            nix \
            build \
            --impure \
            --eval-store auto \
            --keep-failed \
            --max-jobs 0 \
            --no-link \
            --print-build-logs \
            --print-out-paths \
            --store ssh-ng://builder \
            --substituters "" \
            ~/.config/nixpkgs#homeConfigurations."$(id -un)"-"$(hostname)".activationPackage
        ''
      )

    (
      writeScriptBin "hms" ''
        #! ${pkgs.runtimeShell} -e

        export NIXPKGS_ALLOW_UNFREE=1;

        home-manager switch --impure --flake "$HOME/.config/nixpkgs"#"$(id -un)"-"$(hostname)"
      ''
    )

    (
      writeScriptBin "gphms" ''
        #! ${pkgs.runtimeShell} -e

        echo $(cd "$HOME/.config/nixpkgs" && git pull) \
        && export NIXPKGS_ALLOW_UNFREE=1; \
        home-manager switch --impure --flake "$HOME/.config/nixpkgs"#"$(id -un)"-"$(hostname)"
      ''
    )

    (
      writeScriptBin "gphms-cache" ''
        #! ${pkgs.runtimeShell} -e

        build-pulling-all-from-cache

        echo $(cd "$HOME/.config/nixpkgs" && git pull) \
        && export NIXPKGS_ALLOW_UNFREE=1; \
        home-manager switch --impure --flake "$HOME/.config/nixpkgs"#"$(id -un)"-"$(hostname)"
      ''
    )

    (
      writeScriptBin "nr" ''
        #! ${pkgs.runtimeShell} -e

        nix repl --expr 'import <nixpkgs> {}'
      ''
    )

    (
      writeScriptBin "self-send-to-cache" ''
        #! ${pkgs.runtimeShell} -e

            nix path-info --impure --recursive \
              /home/"$USER"/.config/nixpkgs#homeConfigurations.$(nix eval --impure --raw --expr 'builtins.currentSystem').\""$(id -un)"-"$(hostname)"\".activationPackage \
            | wc -l

            nix path-info --impure --recursive \
              /home/"$USER"/.config/nixpkgs#homeConfigurations.$(nix eval --impure --raw --expr 'builtins.currentSystem').\""$(id -un)"-"$(hostname)"\".activationPackage \
            | xargs -I{} nix \
                copy \
                --max-jobs $(nproc) \
                -vvv \
                --no-check-sigs \
                {} \
                --to 's3://playing-bucket-nix-cache-test'
      ''
    )
  ];

  # https://github.com/nix-community/home-manager/blob/782cb855b2f23c485011a196c593e2d7e4fce746/modules/targets/generic-linux.nix
  # targets.genericLinux.enable = true;

  nix = {
    enable = true;
    # What about github:NixOS/nix#nix-static can it be injected here? What would break?
    # package = pkgs.pkgsStatic.nixVersions.nix_2_10;
    package = pkgs.nixVersions.nix_2_10;
    # Could be useful:
    # export NIX_CONFIG='extra-experimental-features = nix-command flakes'
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      # use-sandbox = true;
      show-trace = true;
      # system-features = [ "big-parallel" "kvm" "recursive-nix" "nixos-test" ];
      keep-outputs = true;
      keep-derivations = true;

      tarball-ttl = 60 * 60 * 24 * 7 * 4; # = 2419200 = one month
      # readOnlyStore = true;

      # trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      # trusted-substituters = "fooooo";
    };
  };

  nixpkgs.config = {
    allowBroken = false;
    allowUnfree = true;
    # TODO: test it
    # android_sdk.accept_license = true;
  };

  # services.systembus-notify.enable = true;
  # services.spotifyd.enable = true;

  fonts = {
    # enableFontDir = true;
    # enableGhostscriptFonts = true;
    # fonts = with pkgs; [
    #   powerline-fonts
    # ];
    fontconfig = {
      enable = true;
      #  defaultFonts = {
      #      monospace = [ "Droid Sans Mono Slashed for Powerline" ];
      #  };
    };
  };

  # TODO: documentar e testar
  home.extraOutputsToInstall = [
    "/share/zsh"
    "/share/bash"
    "/share/fish"
    "/share/fonts" # fc-cache -frv
    # /etc/fonts
  ];

  # https://www.reddit.com/r/NixOS/comments/fenb4u/zsh_with_ohmyzsh_with_powerlevel10k_in_nix/
  programs.zsh = {
    # Your zsh config
    enable = true;
    enableCompletion = true;
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    envExtra = ''
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        . ~/.nix-profile/etc/profile.d/nix.sh
      fi
    '';

    # initExtra = "neofetch --ascii_distro NixOS_small --color_blocks off --disable cpu gpu memory term de resolution kernel model";
    # initExtra = "${pkgs.neofetch}/bin/neofetch"; # TODO: checar se esse pacote é seguro

    # promptInit = ''
    #   export POWERLEVEL9K_MODE=nerdfont-complete
    #   source ${pkgs.zsh-powerlevel9k}/share/zsh-powerlevel9k/powerlevel9k.zsh-theme
    # '';

    # initExtraBeforeCompInit = ''eval "$(direnv hook zsh)"'';
    autocd = true;


    shellAliases = {
      l = "ls -al";

      #
      nb = "nix build";
      npi = "nix profile install nixpkgs#";
      ns = "nix shell";
      # nr = "nix repl --expr 'import <nixpkgs> {}'";
    };

    # > closed and reopened the terminal. Then it worked.
    # https://discourse.nixos.org/t/home-manager-doesnt-seem-to-recognize-sessionvariables/8488/8
    sessionVariables = {
      # EDITOR = "nvim";
      # DEFAULT_USER = "foo-bar";
      # ZSH_AUTOSUGGEST_USE_ASYNC="true";
      # ZSH_AUTOSUGGEST_MANUAL_REBIND="true";
      # PROMPT="|%F{153}%n@%m%f|%F{174}%1~%f> ";

      LANG = "en_US.utf8";
      # fc-match list
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      FONTCONFIG_PATH = "${pkgs.fontconfig.out}/etc/fonts/";
    };

    historySubstringSearch.enable = true;

    history = {
      save = 50000;
      size = 50000;
      path = "$HOME/.cache/zsh_history";
      expireDuplicatesFirst = true;
    };

    oh-my-zsh = {
      enable = true;
      # https://github.com/Xychic/NixOSConfig/blob/76b638086dfcde981292831106a43022588dc670/home/home-manager.nix
      plugins = [
        # "autojump"
        "aws"
        # "cargo"
        "catimg"
        "colored-man-pages"
        "colorize"
        "command-not-found"
        "common-aliases"
        "copyfile"
        "copypath"
        "cp"
        "direnv"
        "docker"
        "docker-compose"
        "emacs"
        "encode64"
        "extract"
        "fancy-ctrl-z"
        "fzf"
        "gcloud"
        "git"
        "git-extras"
        "git-flow-avh"
        "github"
        "gitignore"
        "gradle"
        "history"
        "history-substring-search"
        "kubectl"
        "man"
        "mvn"
        "node"
        "npm"
        "pass"
        "pip"
        "poetry"
        "python"
        "ripgrep"
        "rsync"
        "rust"
        "scala"
        "ssh-agent"
        "sudo"
        "systemadmin" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/systemadmin
        "systemd"
        "terraform"
        # "thefuck"
        "tig"
        "timer"
        # "tmux" # It needs tmux to be installed
        "vagrant"
        "vi-mode"
        "vim-interaction"
        "yarn"
        "z"
        "zsh-navigation-tools"
      ];
      theme = "robbyrussell";
      # theme = "bira";
      # theme = "powerlevel10k";
      # theme = "powerlevel9k/powerlevel9k";
      # theme = "agnoster";
      # theme = "gallois";
      # theme = "gentoo";
      # theme = "af-magic";
      # theme = "half-life";
      # theme = "rgm";
      # theme = "crcandy";
      # theme = "fishy";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # https://nix-community.github.io/home-manager/options.html#opt-programs.direnv.config
  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # enableBashIntegration = true;
    # enableFishIntegration = true;
  };

  # This makes it so that if you type the name of a program that
  # isn't installed, it will tell you which package contains it.
  # https://eevie.ro/posts/2022-01-24-how-i-nix.html
  #
  programs.nix-index = {
    enable = true;
    # enableFishIntegration = true;
    # enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.home-manager = {
    enable = true;
  };
}
