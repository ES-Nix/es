{ config, pkgs, lib, modulesPath, ... }:
with lib;
{

  environment.etc."nix/private-key".text = ''
    binarycache-1:LS3ApFX0izjIwKCDJFquhuF2+ENxhAv0jdF838AyhUVeI8dL9dP/OIwe7mEahDxnQrzyxrUSqLmQVNjKXfcUmA==
  '';

  environment.etc."nix/public-key".text = ''
    binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg=
  '';

  #  # https://github.com/NixOS/nix/issues/3023#issuecomment-781131502
  #  systemd.services.generate-nix-cache-key = {
  #    wantedBy = [ "multi-user.target" ];
  #    serviceConfig.Type = "oneshot";
  #    path = [ pkgs.nix ];
  #    script = ''
  #      [[ -f /etc/nix/private-key ]] && exit
  #      nix-store --generate-binary-cache-key ${config.networking.hostName}-1 \
  #      /etc/nix/private-key /etc/nix/public-key
  #
  #      chmod -v 0600 /etc/nix/private-key
  #    '';
  #  };

  nix = {
    settings = {

      # TODO: "relaxed"
      sandbox = true;

      # TODO: test
      # extra-sandbox-paths = [
      #                         "/dev"
      #                       ]

      show-trace = false;
      system-features = [ "big-parallel" "kvm" "recursive-nix" "nixos-test" "aarch64-linux" ];

      #
      keep-outputs = true;
      keep-derivations = true;

      tarball-ttl = 60 * 60 * 24 * 7 * 4; # = 2419200 = one month
      narinfo-cache-positive-ttl = 0;
      narinfo-cache-negative-ttl = 1234;

      # TODO: que tipo de bug pode ser causado por isso? Raceconditions!?!
      max-jobs = "auto";

      # readOnlyStore = true;

      # TODO: hardning
      allowed-users = [
        "root"
        "nixuser"
        "@wheel"
      ];

      #      # By default, only the key for cache.nixos.org is included.
      #      trusted-public-keys = [
      #        "binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg="
      #      ];
      #
      #      # Se eu entendi: apenas o root pode usar
      #      trusted-substituters = [
      #        "https://playing-bucket-nix-cache-test.s3.amazonaws.com"
      #      ];
      #
      #      # By default https://cache.nixos.org/ is added.
      #      # Se eu entendi: apenas o root pode usar
      #      substituters = [
      #        "https://playing-bucket-nix-cache-test.s3.amazonaws.com"
      #      ];

    };
    # keep-outputs = true
    # keep-derivations = true
    # system-features = benchmark big-parallel kvm nixos-test
    #
    # What about github:NixOS/nix#nix-static can it be injected here? What would break?
    # package = pkgs.pkgsStatic.nix;
    # package = pkgs.nixFlakes;
    package = pkgs.nixVersions.nix_2_10;

    extraOptions = ''
      experimental-features = nix-command flakes
      secret-key-files = /etc/nix/private-key
    '';
    # readOnlyStore = true;

    # TODO: How to combine this with overlays?
    # registry.nixpkgs.flake = pkgs.nixpkgs; # https://bou.ke/blog/nix-tips/

    nixPath = [ "nixpkgs=${pkgs.path}" ]; # TODO: test it

    # TODO: document it, test it with nixosTests
    # From:
    # https://github.com/sherubthakur/dotfiles/blob/be96fe7c74df706a8b1b925ca4e7748cab703697/system/configuration.nix#L44
    # pointted by: https://github.com/NixOS/nixpkgs/issues/124215
    #sandboxPaths = [
    #  "/bin/sh=${pkgs.bash}/bin/sh"
    #  # TODO: test it!
    #  # "/bin/sh=${pkgs.busybox-sandbox-shell}/bin/sh"
    #];
    #
    #trustedUsers = [ "@wheel" "nixuser" ];
    #autoOptimiseStore = true;
    #
    #optimise.automatic = true;
    #
    #gc = {
    #  automatic = true;
    #  options = "--delete-older-than 1d";
    #};
    #
    #buildCores = 4;
    #maxJobs = 4;
    #
    ## Can be a hardening thing
    ## https://github.com/sarahhodne/nix-system/blob/98dcfced5ff3bf08ccbd44a1d3619f1730f6fd71/modules/nixpkgs.nix#L16-L22
    #readOnlyStore = false;
    ## https://discourse.nixos.org/t/how-to-use-binary-cache-in-nixos/5202/4
    ## https://www.reddit.com/r/NixOS/comments/p67ju0/cachix_configuration_in_configurationnix/h9b76fs/?utm_source=reddit&utm_medium=web2x&context=3
    #binaryCaches = [
    #  "https://nix-community.cachix.org"
    #  "https://cache.nixos.org"
    #];
    #binaryCachePublicKeys = [
    #  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    #  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    #];

  };

  # TODO: isso é um workaround, o correto
  # seria entender porque o sudo está com a permissão
  # errada e ainda porque funciona fazer o chown desse arquivo
  # na /nix/store se readOnlyStore = true;

  #  systemd.services.fix-sudo-permision = {
  #    script = ''
  #      set -x
  #
  #      echo "Fixing sudo"
  #      #
  #      chown root:root -v ${pkgs.sudo}/libexec/sudo/sudoers.so
  #
  #    '';
  #    # wantedBy = [ "multi-user.target" ];
  #    after = [ "nix-store.mount" ];
  #  };


}
