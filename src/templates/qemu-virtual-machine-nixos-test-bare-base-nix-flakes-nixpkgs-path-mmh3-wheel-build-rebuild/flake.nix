{
  description = "A Nix flake that defines a NixOS test with a single machine that has the hello package installed, and a test script that runs some basic commands to verify that the hello package is working correctly. The flake also defines a shell application that runs all tests, and a development shell that includes the test packages.";

  /*
    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-registry 'github:NixOS/flake-registry/02fe640c9e117dd9d6a34efc7bcb8bd09c08111d' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    flake-registry.url = "github:NixOS/flake-registry";
    flake-registry.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, flake-registry }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        flake-registry = flake-registry;

        testNixOSBare = final.testers.runNixOSTest {
          name = "test-bare-base";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              virtualisation = {
                memorySize = 1024 * 6; # RAM memory in MiB.
                diskSize = 1024 * 32; # RAM memory in MiB.
                cores = 6; # Number of CPU cores. # TODO: it may cause race conditions vs an single core?
              };

              environment.systemPackages = (with pkgs; [
                nix

                auditwheel
                binutils.out
                glibc.bin
                git
                patchelf
                pax-utils
                poetry
                python3
                python3Packages.wheel
                python3Packages.wheel-filename
                python3Packages.wheel-inspect
                twine
              ]);

              system.extraDependencies = with pkgs; [ python3Packages.mmh3.inputDerivation ];

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
              # boot.readOnlyNixStore = false;
              boot.nixStoreMountOpts = [ "rw" ]; # TODO: What may be missing?
            };
          };
          testScript = { nodes, ... }: ''
            machineABCZ.succeed("free -h >&2")
            machineABCZ.succeed("df -h >&2")

            machineABCZ.succeed("""
              nix build --no-link --print-build-logs --print-out-paths nixpkgs#python3Packages.mmh3.dist >&2
            """)
            machineABCZ.succeed("""
              nix build --no-link --print-build-logs --print-out-paths --rebuild nixpkgs#python3Packages.mmh3.dist >&2
            """)
          '';
        };

        testNixOSBareDriverInteractive = final.testNixOSBare.driverInteractive // { boot.readOnlyNixStore = false; };
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
              && nix flake check --all-systems --verbose '.#'
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
          # config.allowUnfreePredicate = (_: true);
          # config.android_sdk.accept_license = true;
          config.allowUnfree = true;
          # config.cudaSupport = true;          
        };
      in
      {
        packages = {
          inherit (pkgs)
            fooBar
            testNixOSBare
            testNixOSBareDriverInteractive
            ;
          default = pkgs.testNixOSBare;
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
            meta.description = "Run the interactive test";
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
