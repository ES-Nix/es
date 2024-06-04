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
    git
    nix
    zsh
  ];

  nix = {
    enable = true;
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    registry.nixpkgs.flake = inputs.nixpkgs;
    # registry.nixpkgs.flake = outputs.homeConfigurations.vagrant.pkgs.unstable;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
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
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
