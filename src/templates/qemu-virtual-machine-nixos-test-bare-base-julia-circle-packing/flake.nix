{
  description = "";

  /*
    # github:NixOS/nixpkgs/nixos-25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'  
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        juliaCustom = ((prev.julia.withPackages.override {
          precompile = false; # Turn off precompilation. TODO Why?
        }) [
          "JuMP" # ?
          "Juniper" # (MI)SOCP, (MI)NLP
          "SCS" # LP, QP, SOCP, SDP
          "DAQP" # (Mixed-binary) QP
        ]);

        juliaCustomBloated =
          let
            minplSolvers = [
              "GLPK"
              "JuMP"
            ];

            manyTools = [
            ];
          in
          ((prev.julia.withPackages.override {
            precompile = false; # Turn off precompilation
          }) (
            minplSolvers
              ++
              manyTools
          ));

        testNixOSBare = final.testers.runNixOSTest {
          name = "test-bare-base";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with pkgs; [
                # juliaCustom
                juliaCustomBloated
              ];
            };
          };
          testScript = { nodes, ... }: ''
            # machineABCZ.succeed("julia --version")
            machineABCZ.succeed("""
              julia --version
              julia -e "using Pkg"
              # julia -e "import Pkg; using JuMP" 1>&2
            """)
          '';
        };

        testNixOSBareDriverInteractive = final.testNixOSBare.driverInteractive
          // {
          virtualisation.vmVariant.virtualisation.graphics = false;
          # meta.mainProgram = "${final.testNixOSBare.driverInteractive.name}";
        };
        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

      })
    ];
  } // (
    let
      # nix flake show --allow-import-from-derivation --impure --refresh .#
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

    in
    flake-utils.lib.eachSystem suportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            fooBar
            juliaCustom
            testNixOSBare
            ;
          default = pkgs.testNixOSBareDriverInteractive;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSBareDriverInteractive}";
            meta.mainProgram = "${pkgs.testNixOSBare.driverInteractive.name}";
            meta.description = "Test NixOS Bare Base with Julia";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSBareDriverInteractive
            ;
          default = pkgs.testNixOSBare;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            testNixOSBare
            testNixOSBareDriverInteractive
          ];

          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true             
          '';
        };
      }
    )
  );
}
