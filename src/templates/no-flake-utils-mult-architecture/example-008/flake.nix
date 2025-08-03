{
  outputs = inputs @ { nixpkgs, ... }:
    let
      overlays.default = final: prev: {
        f00Bar = prev.hello;
      };

      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ]
          (system:
            function (import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [
                # inputs.something.overlays.default
                overlays.default
              ];
            }));

    in
    {
      packages = forAllSystems (pkgs: {
        inherit (pkgs) f00Bar;
        default = pkgs.hello;
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem { };

    };
}
