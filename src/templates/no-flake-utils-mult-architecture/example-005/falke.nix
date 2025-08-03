{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    # ...
  };

  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: {

    #   ↓ this is wrong
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem { };
    overlays.default = final: prev: { };

    #   ↓ this is wrong
    packages.${system}.default = nixpkgs.legacyPackages.${system}.callPackage = ./pacakge.nix {
    some-special-arg = ...;
  };

    });
}
