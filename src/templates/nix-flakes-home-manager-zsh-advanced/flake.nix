{
  description = "Your new nix config";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'      
  */
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;

      overlays = import ./overlays { inherit inputs; };
      forAllSystems2 = function:
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
              ];
            }));
    in
    {
      # Your custom packages and modifications, exported as overlays
      # overlays = import ./overlays { inherit inputs; };
      inherit overlays;

      # formatter = forAllSystems (system: {
      #   # A simple formatter that formats the code in this flake
      #   default = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      # });
      formatter = forAllSystems2 (pkgs: pkgs.nixpkgs-fmt);

      packages = forAllSystems (system: {
        # default = nixpkgs.legacyPackages.${system}.hello;
        default = self.homeConfigurations.vagrant.activationPackage;
      });

      checks = forAllSystems (system: {
        # A simple check that runs 'hello' and checks the output
        default = self.homeConfigurations.vagrant.activationPackage;
      });

      # A shell that can be used to test your configuration
      # and run commands in the context of your system
      devShells = forAllSystems (system: {
        # A shell that can be used to test your configuration
        # and run commands in the context of your system
        default = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with nixpkgs.legacyPackages.${system}; [
            git
            hello
          ];
          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true             
          '';
        };
      });

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # FIXME replace with your username@hostname
        "vagrant" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/home.nix
          ];
        };
      };
    };
}
