# When you add custom packages, list them here
{ pkgs, nixos-lib }: {

  install-start-config-template = pkgs.callPackage ./install-start-config-template { };
  install-qemu-virtual-machine-docker-template = pkgs.callPackage ./install-qemu-virtual-machine-docker-template { };
  send-to-cache-install-start-config-template = pkgs.callPackage ./send-to-cache-install-start-config-template { };

  #  test-nixos = nixos-lib.runTest {
  #    imports = [ ../tests/test.nix ];
  #    hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
  #  };
}
