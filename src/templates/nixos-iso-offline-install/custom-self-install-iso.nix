{ inputs, config, pkgs, lib, modulesPath, ... }:
let
  installConfiguration = import "${pkgs.path}/nixos" {
    system = "x86_64-linux";
    configuration = import ./install-configuration.nix;
  };
  installBuild = installConfiguration.config.system.build;

  off-install-script = pkgs.writeScript "off-install-script" ''
    #! ${pkgs.runtimeShell} -e

    set -euxo pipefail

    [ -d /sys/firmware/efi ] && echo 'The system was detected as UEFI' || echo 'The system was detected as BIOS'

    # If the partitions exist already as-is, parted might error out
    # telling that it can't communicate changes to the kernel...
    # TODO: there is some race condition, maybe use
    ##dd if=/dev/urandom of=/dev/sda bs=1M status=progress
    # wipefs --all --force --json /dev/sda
    # 
    # These are the exact steps from
    # https://nixos.org/nixos/manual/index.html#sec-installation-summary
    # needed to add a few -s (parted) and -F (mkfs.ext4) etc. flags to
    # supress prompts]
    # 
    # nixos-install will run "nix build --store /mnt ..." which won't be able
    # to see what we have in the installer nix store, so copy everything
    # needed over.

    parted --list \
    && fdisk --list \
    && wipefs --all --force --json /dev/sda \
    && parted --list \
    && fdisk --list \
    && parted --script /dev/sda -- mklabel gpt \
    && parted --script /dev/sda -- mkpart primary 512MiB -1GiB \
    && parted --script /dev/sda -- mkpart primary linux-swap -1GiB -500MiB \
    && parted --script /dev/sda -- mkpart ESP fat32 1MiB 512MiB \
    && parted --script /dev/sda -- set 3 boot on \
    && mkfs.ext4 -F -L nixos /dev/sda1 \
    && mkswap --label swap /dev/sda2 \
    && swapon /dev/sda2 \
    && mkfs.fat -F 32 -n boot -I /dev/sda3 \
    && parted --list \
    && fdisk --list \
    && sleep 6 \
    && parted --list \
    && fdisk --list \
    && mount /dev/disk/by-label/nixos /mnt \
    && mkdir -pv /mnt/boot \
    && mount /dev/disk/by-label/boot /mnt/boot \
    && df -h \
    && parted --list \
    && fdisk --list \
    && (test -d /mnt || exit 1) \
    && nixos-generate-config --root /mnt \
    && date --rfc-3339=ns --utc \
    && echo "${pkgs.path}" \
    && nix \
        build \
        --offline \
        --no-use-registries \
        --file "${pkgs.path}"'/nixos' system \
        -I nixos-config=/mnt/etc/nixos/configuration.nix \
        -o /out \
    && nix copy -vvv --no-check-sigs --to local?root=/mnt /out \
    && date --rfc-3339=ns --utc \
    && ls -al /nix/var/nix/profiles/per-user/root/channels \
    && date --rfc-3339=ns --utc \
    && (${installBuild.nixos-install}/bin/nixos-install --no-root-password || true) \
    && date --rfc-3339=ns --utc \
    && shutdown --poweroff
  '';

in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
    # error: derivation '/nix/store/2j6939vz4slg58a55jfvp5r3hka3h21l-closure-info.drv' requires non-existent output 'bin' from input derivation '/nix/store/zd4r1jh7nmvkhlm6z6xi0z2w0bfkzfap-libidn2-2.3.2.drv'
    # "${modulesPath}/profiles/all-hardware.nix"
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/installation-device.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
    "${modulesPath}/installer/tools/tools.nix"
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # registry.nixpkgs.flake = nixpkgs;
    # registry.nixpkgs.flake = pkgs;
    # registry.nixpkgs.flake = config.nixpkgs;
    channel.enable = false;
    nixPath = [ "nixpkgs=${pkgs.path}" ];
  };

  #  boot.initrd.kernelModules = [ "wl" ];
  #  boot.kernelModules = [ "kvm-intel" "wl" ];
  #  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  # https://gist.github.com/andir/88458b13c26a04752854608aacb15c8f#file-configuration-nix-L11-L12
  boot.loader.grub.extraConfig = "serial --unit=0 --speed=115200 \n terminal_output serial console; terminal_input serial console";

  boot.consoleLogLevel = 0;
  boot.loader.timeout = lib.mkForce 0;

  system.stateVersion = "24.05";

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


  # boot.tmpOnTmpfs = true;
  # boot.tmpOnTmpfsSize = "95%";
  boot.tmp.tmpfsSize = "95%";
  boot.tmp.useTmpfs = true;

  boot.readOnlyNixStore = true;

  # https://nixos.wiki/wiki/Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 10000 8000 ];
  };

  environment.systemPackages = with pkgs; [
    git
    parted # check if this can be removed
    cowsay
    (
      writeScriptBin "off-install-script" off-install-script
    )

  ];

  system.nixos-generate-config.configuration = builtins.readFile ./install-configuration.nix;

  systemd.services.sshd.enable = true;

  # nix eval '.#nixosConfigurations.nixos-offline-install-iso-in-qcow2.config.system.build.isoImage.override.__functionArgs'
  #isoImage.compressImage = false;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  # isoImage.squashfsCompression = "zstd -Xcompression-level 7";
  isoImage.isoBaseName = "nixos-offline-installer";
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.volumeID = "NIXOS_ISO"; # substring 0 11 "NIXOS_ISO";
  isoImage.storeContents = [ installBuild.toplevel ];
  # isoImage.includeSystemBuildDependencies = true; # unconfirmed if this is really needed


  # If you only need in-tree filesystems
  # boot.supportedFilesystems = lib.mkForce [ ];

  # If you don't need non-free firmware
  # hardware.enableRedistributableFirmware = lib.mkForce false;

  # If you only want to partition the disk
  # environment.systemPackages = mkForce [ pkgs.parted ];

  # If you don't want the docs
  documentation.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;

  # If you don't need wifi
  networking.wireless.enable = lib.mkForce false;

  # This is used to pull in stdenv to speed up the installation, so removing it
  # means you have to download it
  system.extraDependencies = lib.mkForce [ ];

  systemd.user.services.populate-history = {
    script = ''
      echo "Started"

      DESTINATION=/home/nixos/.bash_history

      echo "sudo poweroff" >> "$DESTINATION"

      echo "Ended"
    '';
    wantedBy = [ "default.target" ];
  };

  systemd.services.hack-to-install = {
    script = ''
      echo "Started: date +'%d/%m/%Y %H:%M:%S:%3N'"

      ls -al

      test -f /home/nixos/.profile || touch /home/nixos/.profile && chown -v nixos: -Rv /home/nixos

      echo "sudo off-install-script" >> /home/nixos/.profile
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
