{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bashInteractive
    coreutils
    curl
    file
    findutils
    gawk
    git
    glibc.bin
    gnugrep
    gnumake
    gnused
    gnutar
    hexdump
    jq
    man
    man-db
    nano
    neovim
    openssh
    patchelf
    which
    xorg.xkill
  ];

  nix = {
    enable = true;
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      show-trace = false;
      keep-outputs = true;
      keep-derivations = true;
    };
  };

  nixpkgs.config = {
    allowBroken = false;
    allowUnfree = true;
  };

  programs.home-manager = {
    enable = true;
  };
}
