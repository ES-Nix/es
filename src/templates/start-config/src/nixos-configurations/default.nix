{ lib, path, ... }:
let
  # Shared base configuration.
  exampleBase = {
    system = "x86_64-linux";
    modules = [
      ../modules/common.nix
      ../modules/custom-user-and-ssh.nix

      ../modules/custom-vagrant.nix
      ../modules/custom-libvirt.nix
      ../modules/hello.nix

      # TODO:
      # { nixpkgs.overlays = [ (my-overlays) ]; }
    ];
  };

  # Shared build-vm configuration.
  exampleBuildVmBase = {
    system = "x86_64-linux";
    modules = [
      ../modules/common.nix
      ../modules/custom-user-and-ssh.nix

      ../modules/custom-nix.nix
      ../modules/custom-nixpkgs.nix

      ../modules/custom-qemu-vm.nix

      # { nixpkgs.overlays = [ (my-overlays) ]; }
    ];
  };

in
{
  nixos-vmIso = lib.nixosSystem {
    inherit (exampleBase) system;
    modules = exampleBase.modules ++ [
      "${path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      {
        # https://nixos.wiki/wiki/Creating_a_NixOS_live_CD#Building_faster
        isoImage.squashfsCompression = "gzip -Xcompression-level 1";
      }
    ];
  };

  build-vm-basic = lib.nixosSystem {
    inherit (exampleBase) system;
    modules = exampleBase.modules ++ [
      ../modules/custom-boot.nix
    ];
  };

  build-vm-nix-server = lib.nixosSystem {
    inherit (exampleBuildVmBase) system;
    modules = exampleBuildVmBase.modules ++ [
      ../modules/custom-boot.nix

      # ../modules/custom-dev.nix
      ../modules/custom-nix-server.nix

      # TODO: hardning
      ../modules/custom-qemu-vm.nix
    ];
  };

  build-vm-dev = lib.nixosSystem {
    inherit (exampleBuildVmBase) system;
    modules = exampleBuildVmBase.modules ++ [
      ../modules/custom-boot.nix
      ../modules/custom-dev.nix
      ../modules/custom-qemu-vm.nix
      ../modules/custom-docker.nix
    ];
  };

  build-vm-podman = lib.nixosSystem {
    inherit (exampleBuildVmBase) system;
    modules = exampleBuildVmBase.modules ++ [
      # Se não existir `nix flake check .#` resulta em erro
      # The ‘fileSystems’ option does not specify your root file system.
      # You must set the option ‘boot.loader.grub.devices’ or 'boot.loader.grub.mirroredBoots' to make the system bootable.
      ../modules/custom-boot.nix
      ../modules/custom-dev.nix
      ../modules/custom-qemu-vm.nix
      ../modules/custom-podman.nix
    ];
  };

  build-vm-bloated = lib.nixosSystem {
    inherit (exampleBuildVmBase) system;
    modules = exampleBuildVmBase.modules ++ [
      ../modules/custom-boot.nix
      ../modules/custom-qemu-vm.nix

      ../modules/custom-oci.nix
      ../modules/custom-oci-custom.nix
      ../modules/custom-podman.nix
    ];
  };
}


