{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    # ...
  };

  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: {

    packages.default = nixpkgs.legacyPackages.${system}.callPackage = ./package.nix {
    some-special-arg = ...;
  };

    });
}
