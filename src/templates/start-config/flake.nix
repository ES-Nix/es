{
  inputs = {

    nixpkgs-darwin-stable.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    nixpkgs-linux-stable.url = "github:nixos/nixpkgs/nixos-22.11";

    nixpkgs-linux-unstable.url = "nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-linux-stable";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs-linux-stable";
    };

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs-linux-stable";

  };

  outputs =
    { self
    , nixpkgs-linux-stable
    , nixpkgs-linux-unstable
    , nixpkgs-darwin-stable
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
        nixpkgs-linux-stable.lib.nixosSystem rec {
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
      pkgsAllowUnfree = import nixpkgs-linux-stable { system = suportedSystem; config = { allowUnfree = true; }; };
      lib = nixpkgs-linux-stable.lib;
    in rec {
      devShells.default =
        pkgsAllowUnfree.mkShell { buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            # hello-unfree
          ];
        };
    } // {

      nixosConfigurations = (import ./src/nixos-configurations {
        inherit lib;
        path = pkgsAllowUnfree.path;
        # my-overlays = my-overlays;
      });

      checks."${suportedSystem}" = self.packages."${suportedSystem}".hello;

      packages.hello = pkgsAllowUnfree.hello;
      packages.python3WithPandas = pkgsAllowUnfree.python3Packages.pandas;

#      apps.hello = {
#        type = "app";
#        program = self.packages."${suportedSystem}".hello;
#      };

      apps."${suportedSystem}" = {
          hello = flake-utils.lib.mkApp {
            name = "hello";
            drv = self.packages."${suportedSystem}".hello;
          };
      };

      homeConfigurations = {
        "vagrant-alpine316.localdomain" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "vagrant"; };
        "ubuntu-ubuntu2204-ec2" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "ubuntu"; };
        "alvaro-Maquina-Virtual-de-Alvaro.local" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "ubuntu"; };
        "nixuser-nixos" = f { system = "${suportedSystem}"; arg-pkgs = pkgsAllowUnfree; home = ./home.nix; username = "ubuntu"; };
      };

    });
}
