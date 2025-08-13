{ inputs, config, pkgs, lib, modulesPath, ... }:
let
  installConfiguration = import "${pkgs.path}/nixos" {
    system = "x86_64-linux";
    configuration = import ./install-configuration.nix;
  };
  installBuild = installConfiguration.config.system.build;

  off-install-script = pkgs.writeScript "off-install-script" ''
    #! ${pkgs.runtimeShell} -e

    set -e
    # set -euxo pipefail

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

    ## Prints debugging information
    # dmesg | grep sda \
    # && df -h \
    # && parted --list \
    # && parted /dev/sda align-check \
    # && fdisk --list \
    # && parted --list \
    # && date --rfc-3339=ns --utc \
    # && fdisk --list \
    # && exit 1
    # wipefs --all --force --json /dev/sda \

    for i in $(seq 1 10); do

      DISK="/dev/sda"
      echo "Start erasing $DISK, attempt $i/10"

      # echo "Wiping partition table (first 2MiB)..." \
      # && dd if=/dev/zero of="$DISK" bs=1M count=2 status=progress \
      # && echo "Wiping GPT backup partition table (last 1MiB)..." \
      # && sectors=$(blockdev --getsz "$DISK") \
      # && dd if=/dev/zero of="$DISK" bs=512 seek=$((sectors - 2048)) count=2048 status=progress \

      # wipefs --all --force --json /dev/sda
      echo "End erasing $DISK" \
      && ls -l /dev/sda* \
      && partprobe /dev/sda \
      && udevadm settle \
      && parted --script /dev/sda -- mklabel gpt \
      && ls -l /dev/sda* \
      && partprobe /dev/sda \
      && udevadm settle \
      && parted /dev/sda print \
      && parted /dev/sda print free \
      && parted --script /dev/sda -- mkpart primary 512MiB 10GiB \
      && partprobe /dev/sda \
      && udevadm settle \
      && parted --script /dev/sda -- mkpart primary linux-swap -1GiB -500MiB \
      && partprobe /dev/sda \
      && udevadm settle \
      && parted --script /dev/sda -- mkpart ESP fat32 1MiB 512MiB \
      && partprobe /dev/sda \
      && udevadm settle \
      && parted --script /dev/sda -- set 3 boot on \
      && partprobe /dev/sda \
      && udevadm settle \
      && mkfs.ext4 -F -L nixos /dev/sda1 \
      && partprobe /dev/sda \
      && udevadm settle \
      && mkswap --label swap /dev/sda2 \
      && partprobe /dev/sda \
      && udevadm settle \
      && swapon /dev/sda2 \
      && partprobe /dev/sda \
      && udevadm settle \
      && mkfs.fat -F 32 -n boot -I /dev/sda3 \
      && partprobe /dev/sda \
      && udevadm settle \
      && break
    done

    mount /dev/disk/by-label/nixos /mnt \
    && mkdir -pv -m 0755 /mnt/boot \
    && mount /dev/disk/by-label/boot /mnt/boot \
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
    && date --rfc-3339=ns --utc \
    && nix copy --no-check-sigs --to local?root=/mnt /out \
    && date --rfc-3339=ns --utc \
    && ls -al /nix/var/nix/profiles/per-user/root/channels \
    && (${installBuild.nixos-install}/bin/nixos-install --no-root-password --no-channel-copy || true) \
    && date --rfc-3339=ns --utc \
    && partprobe /dev/sda \
    && udevadm settle \
    && date --rfc-3339=ns --utc \
    && shutdown --poweroff now
    # || (shutdown --poweroff now && exit 1)
  '';

in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/installation-device.nix"
    # "${modulesPath}/installer/cd-dvd/channel.nix"
    "${modulesPath}/installer/tools/tools.nix"
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    channel.enable = false;
    nixPath = [ "nixpkgs=${pkgs.path}" ];
  };

  # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
  # https://nixos.wiki/wiki/Libvirt
  # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
  boot.extraModprobeConfig = "options kvm_intel nested=1";
  boot.kernelModules = [
    "kvm-intel"
  ];

  # https://gist.github.com/andir/88458b13c26a04752854608aacb15c8f#file-configuration-nix-L11-L12
  boot.loader.grub.extraConfig = "serial --unit=0 --speed=115200 \n terminal_output serial console; terminal_input serial console";

  boot.consoleLogLevel = 0;
  boot.loader.timeout = lib.mkForce 0;

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

  boot.tmp.tmpfsSize = "95%";
  boot.tmp.useTmpfs = true;
  boot.readOnlyNixStore = true;

  # # https://nixos.wiki/wiki/Firewall
  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 80 443 10000 8000 ];
  # };

  system.stateVersion = "25.05";

  environment.systemPackages = with pkgs; [
    gitMinimal
    parted # check if this can be removed
    (
      writeScriptBin "off-install-script" off-install-script
    )

  ];

  system.nixos-generate-config.configuration = builtins.readFile ./install-configuration.nix;

  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.volumeID = "NIXOS_ISO"; # substring 0 11 "NIXOS_ISO";
  isoImage.storeContents = [ installBuild.toplevel ];

  # If you only need in-tree filesystems
  boot.supportedFilesystems = lib.mkForce [ ];

  # If you don't need non-free firmware
  hardware.enableRedistributableFirmware = lib.mkForce false;

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
      ls -alh
      test -f /home/nixos/.profile || touch /home/nixos/.profile && chown -v nixos: -Rv /home/nixos
      echo "sudo off-install-script" >> /home/nixos/.profile
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
