{
  description = "Base configuration home-manager";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input home-manager 'github:nix-community/home-manager/aecd341dfead1c3ef7a3c15468ecd71e8343b7c6' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input home-manager 'github:nix-community/home-manager/f63d0fe9d81d36e5fc95497217a72e02b8b7bcab' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input nixos-generators 'github:nix-community/nixos-generators/8946737ff703382fda7623b9fab071d037e897d5'
    
  */
  inputs = {

    # nixpkgs-darwin-stable.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    nixpkgs.url = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    allAttrs@{ self
    , nixpkgs
    , flake-utils
    , nixos-generators
    , home-manager
    ,
    }:
    let

      suportedSystems = [
        "x86_64-linux"
        # "aarch64-linux"
        "aarch64-darwin"
      ];

      mkSystem = extraModules:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            # bake the git revision of the repo into the system
            ({ ... }: { system.configurationRevision = self.sourceInfo.rev; })
          ] ++ extraModules;
        };

      f = { system, username, arg-pkgs, home ? "", stateVersion ? "22.11" }:
        let
          pkgs = arg-pkgs;
          baseHomeDirectory = "${if pkgs.stdenv.isLinux then "/home/" else "${if pkgs.stdenv.isDarwin then "/User/" else builtins.throw "Unsuported system!"}"}";
          homeDirectory = "${baseHomeDirectory}" + "${username}";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;

          modules = [
            {
              home = {
                username = "${username}";
                homeDirectory = "${homeDirectory}";
                stateVersion = "${stateVersion}";
                packages = with pkgs; [
                  sl
                  cowsay
                ];
              };

              programs.home-manager.enable = true;

            }

            "${home}"

          ];

          # TODO: how to: Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
          # extraSpecialArgs = { pkgs-unstable = pkgs; };
        };

    in
    flake-utils.lib.eachSystem suportedSystems (suportedSystem:
    let
      pkgsAllowUnfree = import nixpkgs { system = suportedSystem; config = { allowUnfree = true; }; };
      lib = nixpkgs.lib;

      # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
      pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
        (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
    in
    rec {
      devShells.default =
        pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            coreutils
            # hello-unfree

            pleaseKeepMyInputs
          ];

          shellHook = ''
            test -d .profiles || mkdir -v .profiles

            test -L .profiles/dev \
            || nix develop .# --profile .profiles/dev --command true

            test -L .profiles/dev-shell-default \
            || nix build $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default
          '';
        };
    } // {

      # nixosConfigurations = (import ./src/nixos-configurations {
      #   inherit lib;
      #   path = pkgsAllowUnfree.path;
      #   # my-overlays = my-overlays;
      # });

      checks."${suportedSystem}" = self.packages."${suportedSystem}".hello;

      formatter = pkgsAllowUnfree.nixpkgs-fmt;

      packages.allTests = let name = "all-tests"; in pkgsAllowUnfree.writeShellApplication
        {
          name = name;
          runtimeInputs = with pkgsAllowUnfree; [ ];
          text = ''
            nix fmt . \
            && nix flake show --all-systems --impure '.#' \
            && nix flake metadata --impure '.#' \
            && nix build --impure --no-link --print-build-logs --print-out-paths '.#' \
            && nix develop --impure '.#' --command sh -c 'true' \
            && nix flake check --impure --verbose '.#'

            # && nix build --impure --no-link --print-build-logs --print-out-paths --rebuild '.#' \
          '';
        } // { meta.mainProgram = name; };

      packages.hello = pkgsAllowUnfree.hello;
      packages.default = pkgsAllowUnfree.hello;
      packages.python3WithPandas = pkgsAllowUnfree.python3Packages.pandas;
      # packages.hmsystem = self.homeConfigurations."${suportedSystem}"."vagrant-alpine316.localdomain".activationPackage;

      /*
      > Unfortunately, homeConfigurations doesn’t really support multi-arch outputs like the other flake attrs do.
      > https://discourse.nixos.org/t/how-can-i-set-up-flake-based-home-manager-config-for-both-intel-and-m1-macs/19402/2
      */
      homeConfigurations = {
        "vagrant-alpine316.localdomain" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "vagrant"; };
      };

    });
}
