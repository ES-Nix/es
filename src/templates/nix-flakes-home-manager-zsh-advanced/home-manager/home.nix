# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      # outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  # TODO: Set your username
  home = {
    username = "vagrant";
    homeDirectory = "/home/vagrant";
  };

  home.packages = with pkgs; [
    direnv
    fzf
    git
    nix
    zsh

    hello
    nano
    file
    which
    (writeScriptBin "hms" ''
      #! ${pkgs.runtimeShell} -e
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
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    registry.nixpkgs.flake = inputs.nixpkgs;
    # registry.nixpkgs.flake = outputs.homeConfigurations.vagrant.pkgs.unstable;
    settings = {
      bash-prompt-prefix = "(nix-devShell:$name)\\040";
      keep-derivations = true;
      keep-env-derivations = true;
      keep-failed = true;
      keep-going = true;
      keep-outputs = true;
      nix-path = "nixpkgs=flake:nixpkgs";
      tarball-ttl = 2419200; # 60 * 60 * 24 * 7 * 4 = one month
    };
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
      # NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
      NIX_PATH = "nixpkgs=${outputs.homeConfigurations.vagrant.pkgs.unstable.path}";
      LANG = "en_US.utf8";
      DIRENV_LOG_FORMAT = ""; # TODO: direnv it self must have an way to disable logging
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

  # Nicely reload system units when changing configs
  # systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
