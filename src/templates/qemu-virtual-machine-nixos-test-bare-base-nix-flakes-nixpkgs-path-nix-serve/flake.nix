{
  description = "A flake for testing nix-serve in a NixOS virtual machine using QEMU. It includes a test that starts a NixOS VM with nix-serve enabled and checks if it serves the expected cache info. It also provides an interactive driver for manual testing and a shell with the necessary tools to run the tests.";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-registry 'github:NixOS/flake-registry/02fe640c9e117dd9d6a34efc7bcb8bd09c08111d' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

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

        testNixOSNixServe = final.testers.runNixOSTest {
          name = "test-nix-serve";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = (with pkgs; [ nix ]);

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
              /*
                  To test it:
                  curl http://localhost:5000/nix-cache-info
                  nix store info --store http://localhost:5000
              */
              services.nix-serve.enable = true;
            };
          };
          testScript = { nodes, ... }: ''
            # machineABCZ.wait_for_unit("nix-serve.target")
            machineABCZ.wait_for_open_port(5000)

            result = machineABCZ.succeed("curl http://localhost:5000/nix-cache-info")

            assert 'StoreDir: /nix/store' in result, f"expected = , result = {result}"
            assert 'WantMassQuery: 1' in result, f"expected = , result = {result}"
            assert 'Priority: 30' in result, f"expected = , result = {result}"
          '';
        };

        testNixOSNixServeDriverInteractive = final.testNixOSNixServe.driverInteractive;

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
            testNixOSNixServe
            testNixOSNixServeDriverInteractive;
          default = pkgs.testNixOSNixServe;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSNixServeDriverInteractive}";
            meta.description = "Run the interactive test";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSNixServe
            testNixOSNixServeDriverInteractive
            ;
          default = pkgs.testNixOSNixServe;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            testNixOSNixServe
            testNixOSNixServeDriverInteractive
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
