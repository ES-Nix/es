{ inputs, config, pkgs, lib, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
    };
    timeout = 0;
  };

  boot.readOnlyNixStore = true;

  # https://gist.github.com/andir/88458b13c26a04752854608aacb15c8f#file-configuration-nix-L11-L12
  boot.loader.grub.extraConfig = "serial --unit=0 --speed=115200 \n terminal_output serial console; terminal_input serial console";
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
    # Set sensible kernel parameters
    # https://nixos.wiki/wiki/Bootloader
    # https://git.redbrick.dcu.ie/m1cr0man/nix-configs-rb/commit/ddb4d96dacc52357e5eaec5870d9733a1ea63a5a?lang=pt-PT
    "boot.shell_on_fail"
    "panic=30"
    "boot.panic_on_fail" # reboot the machine upon fatal boot issues
  ];
  # https://nixos.wiki/wiki/Libvirt
  # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
  boot.extraModprobeConfig = "options kvm_intel nested=1";
  boot.kernelModules = [ "kvm-intel" ];

  system.stateVersion = "25.05";

  environment.systemPackages = with pkgs; [
    gitMinimal
    sudo
  ];

  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Recife";

  networking.networkmanager.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
  };
  nix.channel.enable = true; # TODO: remove nix-channel related tools & configs, we use flakes instead.
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  security.sudo.wheelNeedsPassword = false; # TODO: hardening
  users.extraGroups.nixgroup.gid = 5678;
  users.users.nixuser = {
    home = "/home/nixuser";
    createHome = true;
    homeMode = "0700";
    isSystemUser = true;
    description = "nix user";
    extraGroups = [
      "networkmanager"
      "libvirtd"
      "wheel"
      "nixgroup"
      "kvm"
      "qemu-libvirtd"
    ];
    # packages = with pkgs; [ firefox ];
    shell = pkgs.bashInteractive;
    uid = 1234;
    initialPassword = "";
    group = "nixgroup";
  };
}
