{
  description = "NixOS tests example";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      nixosModules = {
        helloNixosModule = import ./hello-module.nix;
      };
    } //
    (
      let
        suportedSystems = [
          "x86_64-linux"
          "aarch64-linux"
          # "aarch64-darwin"
        ];
      in
      flake-utils.lib.eachDefaultSystem (system:
        let
          overlay = final: prev: {
            helloNixosTests = self.packages.${system}.helloNixosTests;
          };
          pkgs = nixpkgs.legacyPackages.${system}.extend overlay;
        in
        {
          checks = {
            helloNixosTest = pkgs.callPackage ./hello-boots.nix { inherit self; };
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              helloNixosTests
              python310
              # python311
            ];
          };

          formatter = pkgs.nixpkgs-fmt;

          packages = {
            default = pkgs.callPackage ./hello-boots.nix { inherit self; };
            helloNixosTests = pkgs.writeScriptBin "hello-nixos-tests" ''
              ${pkgs.netcat}/bin/nc -l 3000
            '';
          };
        })
    );
}
