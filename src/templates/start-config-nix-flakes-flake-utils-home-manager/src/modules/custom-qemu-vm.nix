{ config, pkgs, lib, modulesPath, ... }:
with lib;
{
  imports = [
    # For virtualisation settings
    # "${pkgs.path}/nixos/modules/virtualisation/qemu-vm.nix"
    # "${pkgs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"

    # ../modules/custom-qemu-vm.nix
    # TODO: Pq resulta em erro de recursão?
    # "${pkgs.path}/nixos/modules/virtualisation/qemu-vm.nix"
    "${toString modulesPath}/virtualisation/qemu-vm.nix"
    {
      # TODO: documentar pq esse mkForce
      virtualisation = mkForce {
        cores = 8;
        memorySize = 1024 * 8;
        diskSize = 1024 * 32;
        msize = 104857600; # TODO: de onde vem esse número mágico?

        # TODO: investigar e fazer nixosTests sobre esse caso,
        # de alguma forma isso parece passar despercebido.
        # Essa opção é usada para o /nix/store ser montado como do user root
        # e coisas como sudo preservarem permissões especiais.
        # For tests:
        /*
          sudo id
          nix build nixpkgs#hello
          systemctl status nix-daemon.service
        */
        useNixStoreImage = true;
        writableStore = true; # TODO: documentar

      };
    }
  ];


  # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
  virtualisation.memorySize = 1024 * 3;

  # https://github.com/Mic92/nixos-shell/issues/30#issuecomment-823333089
  virtualisation.writableStoreUseTmpfs = false;
}
