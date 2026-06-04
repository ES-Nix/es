{ inputs, config, pkgs, lib, modulesPath, ... }:
let
  installConfiguration = import "${pkgs.path}/nixos" {
    system = pkgs.stdenv.hostPlatform.system;
    configuration = import ./install-configuration.nix;
  };
  installBuild = installConfiguration.config.system.build;

  off-install-script = pkgs.writeScript "off-install-script" ''
    #! ${pkgs.runtimeShell} -e

    set -x
    # set -euxo pipefail

    # Redirect all output to serial so QEMU -nographic captures installer progress
    exec >> /dev/ttyAMA0 2>&1

    # Only one instance runs; extra agetty sessions exit silently without triggering the trap
    exec 9>/var/run/off-install.lock
    flock -n 9 || exit 0

    trap 'umount -R /mnt 2>/dev/null || true; sync; systemctl poweroff; sleep 30; poweroff -f' EXIT

    [ -d /sys/firmware/efi ] && echo 'The system was detected as UEFI' || echo 'The system was detected as BIOS'

    if [ -b /dev/sda ]; then
      DISK_DEV=/dev/sda
    elif [ -b /dev/vda ]; then
      DISK_DEV=/dev/vda
    else
      echo 'ERROR: no disk device found (tried /dev/sda, /dev/vda)' && exit 1
    fi

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
    
    DISK_BYTES=$(blockdev --getsize64 "$DISK_DEV")
    DISK_MiB=$((DISK_BYTES / 1048576))
    ROOT_END_MiB=$((DISK_MiB - 1536))
    SWAP_START_MiB=$((DISK_MiB - 1536))
    SWAP_END_MiB=$((DISK_MiB - 512))

    # Stop services that hold block devices open; leave udevd running
    systemctl stop udisks2 lvm2-monitor lvm2-lvmpolld mdadm 2>/dev/null || true

    # Retry wrapper: wait for udevd to release device between partition creation and mkfs
    _retry() { for _i in $(seq 10); do "$@" && return 0; udevadm settle; sleep 1; done; return 1; }

    wipefs --all --force --json "$DISK_DEV" \
    && parted --script "$DISK_DEV" \
        mklabel gpt \
        mkpart primary 512MiB "''${ROOT_END_MiB}MiB" \
        mkpart primary linux-swap "''${SWAP_START_MiB}MiB" "''${SWAP_END_MiB}MiB" \
        mkpart ESP fat32 1MiB 512MiB \
        set 3 boot on \
    && udevadm settle \
    && _retry mkfs.ext4 -F -F -L nixos "''${DISK_DEV}1" \
    && udevadm settle \
    && _retry mkswap --label swap "''${DISK_DEV}2" \
    && udevadm settle \
    && _retry mkfs.fat -F 32 -n boot -I "''${DISK_DEV}3" \
    && udevadm settle \
    && mount /dev/disk/by-label/nixos /mnt \
    && mkdir -pv -m 0755 /mnt/boot \
    && mount -o umask=0077,sync /dev/disk/by-label/boot /mnt/boot \
    && (test -d /mnt || exit 1) \
    && nixos-generate-config --root /mnt \
    && date --rfc-3339=ns --utc \
    && _closure=$(nix-store -qR ${installBuild.toplevel} | sort -u) \
    && mkdir -p /mnt/nix/store \
    && echo "$_closure" | xargs -I{} sh -c \
         'dst="/mnt/nix/store/$(basename "$1")"; [ -e "$dst" ] || { cp -rp "$1" /mnt/nix/store/ 2>/dev/null; [ -e "$dst" ]; }' _ {} \
    && mkdir -p /mnt/nix/var/nix && cp -rp /nix/var/nix/db /mnt/nix/var/nix/db \
    && mkdir -p /mnt/boot/EFI/nixos \
    && (for _src in "$(realpath ${installBuild.toplevel}/kernel 2>/dev/null)" "$(realpath ${installBuild.toplevel}/initrd 2>/dev/null)"; do
           [ -f "''${_src}" ] || continue
           _subdir=$(basename "$(dirname "''${_src}")")
           _fname=$(basename "''${_src}")
           _dest="/mnt/boot/EFI/nixos/''${_subdir}-''${_fname}.efi"
           [ -f "''${_dest}" ] || cp -v "''${_src}" "''${_dest}"
       done) \
    && touch /mnt/etc/NIXOS \
    && mkdir -p /mnt/nix/var/nix/profiles \
    && ln -sfn ${installBuild.toplevel} /mnt/nix/var/nix/profiles/system-1-link \
    && ln -sfn system-1-link /mnt/nix/var/nix/profiles/system \
    && printf 'ID=nixos\n' > /mnt/etc/os-release \
    && mkdir -p /mnt/proc /mnt/sys /mnt/dev /mnt/run \
    && mount --bind /proc /mnt/proc \
    && mount --bind /sys /mnt/sys \
    && mount --bind /dev /mnt/dev \
    && mount --bind /run /mnt/run \
    && NIXOS_INSTALL_BOOTLOADER=1 chroot /mnt ${installBuild.toplevel}/bin/switch-to-configuration boot
  '';

in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
    # error: derivation '/nix/store/2j6939vz4slg58a55jfvp5r3hka3h21l-closure-info.drv' requires non-existent output 'bin' from input derivation '/nix/store/zd4r1jh7nmvkhlm6z6xi0z2w0bfkzfap-libidn2-2.3.2.drv'
    # "${modulesPath}/profiles/all-hardware.nix"
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
  # https://nixos.wiki/wiki/Libvirt
  # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
  boot.extraModprobeConfig = lib.optionalString pkgs.stdenv.hostPlatform.isx86_64 "options kvm_intel nested=1";
  boot.kernelModules =
    if pkgs.stdenv.hostPlatform.isx86_64 then [ "kvm-intel" ]
    else if pkgs.stdenv.hostPlatform.isAarch64 then [ "kvm" ]
    else [ ];

  # https://gist.github.com/andir/88458b13c26a04752854608aacb15c8f#file-configuration-nix-L11-L12
  boot.loader.grub.extraConfig = "serial --unit=0 --speed=115200 \n terminal_output serial console; terminal_input serial console";

  boot.consoleLogLevel = 0;
  boot.loader.timeout = lib.mkForce 0;

  system.stateVersion = "25.11";

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

  # boot.nixStoreMountOpts = [ "ro,nodev,nosuid,noexec" ]; # ?

  # https://nixos.wiki/wiki/Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 10000 8000 ];
  };

  environment.systemPackages = with pkgs; [
    git
    parted # check if this can be removed
    (
      writeScriptBin "off-install-script" off-install-script
    )

  ];

  system.nixos-generate-config.configuration = builtins.readFile ./install-configuration.nix;

  systemd.services.sshd.enable = true;

  # nix eval '.#nixosConfigurations.nixos-offline-install-iso-in-qcow2.config.system.build.isoImage.override.__functionArgs'
  # isoImage.compressImage = false;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  # isoImage.squashfsCompression = "zstd -Xcompression-level 1";
  # isoImage.squashfsCompression = "zstd -Xcompression-level 22";
  # image.baseName = "nixos-offline-installer";
  image.fileName = "${config.image.baseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
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
    serviceConfig.Type = "oneshot";
    script = ''
      echo "Started: date +'%d/%m/%Y %H:%M:%S:%3N'"

      ls -al

      test -f /home/nixos/.profile || touch /home/nixos/.profile && chown -v nixos: -Rv /home/nixos

      echo "sudo off-install-script" >> /home/nixos/.profile
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
