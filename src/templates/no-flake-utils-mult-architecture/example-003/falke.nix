{
  inputs = ...;
  outputs = { nixpkgs, ... }: {

    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.callPackage ./package.nix {
      some-special-arg = ...;
    };
    packages.aarch64-linux.default = nixpkgs.legacyPackages.aarch64-linux.callPackage ./package.nix {
      some-special-arg = ...;
    };

  };
}
