{
  description = "NixOS tests example";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8 \
    --override-input flake-utils github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
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
            helloNixosTests = pkgs.writeScriptBin "hello-nixos-tests" ''
              ${pkgs.netcat}/bin/nc -l 3000
            '';
          };
        })
    );
}
