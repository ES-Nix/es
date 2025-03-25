{
  description = "Base configuration home-manager";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input home-manager 'github:nix-community/home-manager/208df2e558b73b6a1f0faec98493cb59a25f62ba'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input home-manager 'github:nix-community/home-manager/2f23fa308a7c067e52dfcc30a0758f47043ec176'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input home-manager 'github:nix-community/home-manager/f6af7280a3390e65c2ad8fd059cdc303426cbd59'  
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    allAttrs@{ self
    , nixpkgs
    , flake-utils
    , home-manager
    ,
    }:
    let

      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      f = { system, username, arg-pkgs, home ? "", stateVersion ? "24.05" }:
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
                  # sl
                  # cowsay
                  hello
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
      formatter = pkgsAllowUnfree.nixpkgs-fmt;

      devShells.default =
        pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            coreutils
            # hello-unfree

            pleaseKeepMyInputs
          ];

          shellHook = ''
            # echo -e 'X' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat

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

      packages.default = self.homeConfigurations."${suportedSystem}"."vagrant-alpine319.localdomain".activationPackage;
      packages.hello = pkgsAllowUnfree.hello;
      packages.python3WithPandas = pkgsAllowUnfree.python3Packages.pandas;

      #      apps.hello = {
      #        type = "app";
      #        program = self.packages."${suportedSystem}".hello;
      #      };

      #      apps."${suportedSystem}" = {
      #          hello = flake-utils.lib.mkApp {
      #            name = "hello";
      #            drv = self.packages."${suportedSystem}".hello;
      #          };
      #      };

      /*
      > Unfortunately, homeConfigurations doesn’t really support multi-arch outputs like the other flake attrs do.
      > https://discourse.nixos.org/t/how-can-i-set-up-flake-based-home-manager-config-for-both-intel-and-m1-macs/19402/2
      */
      homeConfigurations = {
        "vagrant-alpine316.localdomain" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "vagrant"; };
        "vagrant-alpine319.localdomain" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "vagrant"; };
        "ubuntu-ubuntu2204-ec2" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "ubuntu"; };
        "alvaro-Maquina-Virtual-de-Alvaro.local" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "ubuntu"; };
        "nixuser-nixos" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "ubuntu"; };
        "nixuser-container-nix" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "nixuser"; };
        "abcuser-container-nix-hm" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "abcuser"; };
        "podman-container-nix" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "podman"; };
        "nixuser" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "nixuser"; };
      };

    });
}
