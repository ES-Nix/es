{ config, pkgs, lib, modulesPath, ... }:
with lib;
{

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # https://github.com/NixOS/nixpkgs/issues/23912#issuecomment-1462770738
  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "95%";

  boot.loader = {
    systemd-boot.enable = true;

    efi = {
      canTouchEfiVariables = true;
      # efiSysMountPoint = "/dev/disk/by-label/nixos"; # <= use the same mount point here.
    };

    #grub = {
    #   efiSupport = true;
    #   efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
    #   device = "/dev/sda";
    #   # device = "nodev";
    #   version = 2;
    #};
    # It conflicts...
    # timeout = 2;
  };

}
