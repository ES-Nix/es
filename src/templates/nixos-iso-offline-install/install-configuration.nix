{ inputs, config, pkgs, lib, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

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
    timeout = 2;
  };

  boot.readOnlyNixStore = true;

  system.stateVersion = "24.05";

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

  console.keyMap = "us";

  environment.systemPackages = with pkgs; [
    direnv
    git
    hello
    xorg.xhost
    xorg.xclock
    sudo
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 10000 8000 ];
  };

  nixpkgs.config = {
    allowUnfree = true;
  };
  # environment.etc."channels/nixpkgs".source = pkgs.path;
  nix = {
    package = pkgs.nixVersions.nix_2_26;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # services.sshd.enable = true;

  # https://nixos.wiki/wiki/Libvirt
  # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
  boot.extraModprobeConfig = "options kvm_intel nested=1";
  boot.kernelModules = [
    "kvm-intel"
  ];

  time.timeZone = "America/Recife";

  users.extraGroups.nixgroup.gid = 5678;
  users.users.nixuser = {
    home = "/home/nixuser";
    createHome = true;
    homeMode = "0700";

    # isNormalUser = true;
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
    packages = with pkgs; [
      # firefox
    ];
    shell = pkgs.bashInteractive;
    uid = 1234;
    initialPassword = "1";
    group = "nixgroup";
  };

}
