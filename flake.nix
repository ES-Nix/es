{
  description = "This is an 'nix flake' :)";

  inputs = {

    nixpkgs-darwin-stable.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    nixpkgs-linux-stable.url = "github:nixos/nixpkgs/nixos-22.11";

    nixpkgs-linux-unstable.url = "nixpkgs/nixos-unstable";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs-linux-stable";
    };

    flake-utils.url = "github:numtide/flake-utils";
    # flake-utils.inputs.nixpkgs.follows = "nixpkgs-linux-stable";

  };

  outputs =
    allAttrs@{
    self
    , nixpkgs-linux-stable
    , nixpkgs-linux-unstable
    , nixpkgs-darwin-stable
    , flake-utils
    , nixos-generators
    ,
    }:
    let
      name = "es";

      suportedSystems = [
        "x86_64-linux"
        # "aarch64-linux"
        "aarch64-darwin"
      ];
    in
      flake-utils.lib.eachSystem suportedSystems (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs-linux-stable { system = suportedSystem; config = { allowUnfree = true; }; };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in {

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              bashInteractive
              coreutils
              curl
              gnumake
              patchelf
              poetry
              python3Full
              tmate

              pleaseKeepMyInputs
            ];

            shellHook = ''
              echo -e 'Education' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat
              echo -e '       and' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat
              echo -e 'Science' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat

              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop .# --profile .profiles/dev --command id

              test -L .profiles/dev-shell-default \
              || nix build $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default
            '';
          };
          # TODO: put nixosConfigurations here later

          checks."${suportedSystem}" = self.packages."${suportedSystem}".hello;


          # packages_ = (import ./src/pkgs { pkgs = pkgsAllowUnfree; nixos-lib = nixos-lib; });
          packages.default = self.packages."${suportedSystem}".hello;

          packages.hello = pkgsAllowUnfree.hello;
          packages.hello-unfree = pkgsAllowUnfree.hello-unfree;
          packages.python3WithPandas = pkgsAllowUnfree.python3Packages.pandas;

          packages.installStartConfigTemplate = (import ./src/pkgs/install-start-config-template { pkgs = pkgsAllowUnfree;});
          packages.sendToCacheInstallStartConfigTemplate = (import ./src/pkgs/send-to-cache-install-start-config-template { pkgs = pkgsAllowUnfree;});

#          templates."${suportedSystem}" = {
#            startConfig = ({
#              description = "Base configuration";
#              path = ./src/templates/start-config;
#            });
#          };

#          templates."${suportedSystem}".startConfig = ({
#              description = "Base configuration";
#              path = ./src/templates/start-config;
#            });

#          templates."${suportedSystem}".startConfig = {
#              description = "Base configuration";
#              path = ./src/templates/start-config;
#            };

          templates = import ./src/templates;

          apps = {
            # Após longa briga pra fazer
            # nix flake show .#
            # nix flake check .#
            # funcionarem
            installStartConfigTemplate = flake-utils.lib.mkApp {
              name = "install-start-config-template";
              drv = self.packages."${suportedSystem}".installStartConfigTemplate;
            };
          };
        }
    );
}

