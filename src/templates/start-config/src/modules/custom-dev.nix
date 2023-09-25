{ config, pkgs, lib, modulesPath, ... }:
with lib;
{

  environment.systemPackages = with pkgs; [
    hydra-check
    nixos-option

    pciutils # lspci and others
    coreboot-utils
    coreutils
    binutils
    utillinux
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
    xorg.xhost

    curl
    git
    wget
    lsof
    tree
    killall
    nmap
    netcat
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
    shellcheck
    mesa-demos

    fontconfig
    pango
    fontforge-gtk

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

    # pkgsStatic.python3
    # pkgsStatic.hello
    hello
    #    (python3.withPackages (ps: with ps; [
    #      pottery
    #      django
    #      django-six
    #      # django-ip
    #      pycpfcnpj
    #      python-decouple
    #      # django-admin-shell
    #
    #      # django-simple-history
    #      # django-extended-choices
    #      # django-celery-results
    #      # django-user-agents
    #      # django-dry-rest-permissions
    #      # django-ufilter
    #      # django-ses
    #    ]))

    # darwin.builder

    #    (
    #      writeScriptBin "darwin-builder" ''
    #        mkdir -pv ~/sandbox/sandbox \
    #        cd ~/sandbox/sandbox
    #
    #        export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
    #        nix run --impure -L github:NixOS/nixpkgs/nixpkgs-unstable#darwin.builder
    #      ''
    #    )


    asciinema
    tmate
    (
      writeScriptBin "ix" ''
        "$@" | curl -F 'f:1=<-' ix.io
      ''
    )

  ];


  environment.etc."/doas.conf" = {
    mode = "0644";
    text = "permit :wheel\n";
  };

  security.wrappers = {
    doas =
      {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${pkgs.pkgsStatic.doas}/bin/doas";
      };
  };

  #  security.wrappers = {
  #    sudo =
  #      {
  #        setuid = true;
  #        owner = "root";
  #        group = "root";
  #        source = "${pkgs.sudo}/libexec/sudo/sudoers.so";
  #      };
  #  };
}

