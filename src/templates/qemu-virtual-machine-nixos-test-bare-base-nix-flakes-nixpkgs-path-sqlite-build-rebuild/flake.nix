{
  description = "A flake for testing nix in a NixOS virtual machine using QEMU. It includes a test that starts a NixOS VM and checks if it can run the nix command and access the nix store. It also provides an interactive driver for manual testing and a shell with the necessary tools to run the tests.";

  /*
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
          name = "test-bare-base-sqlite";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = (with pkgs; [ pkgsStatic.sqlite nix ]);

              system.extraDependencies = with pkgs; [ pkgsStatic.sqlite.inputDerivation ];

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
            };
          };
          testScript = { nodes, ... }: ''

            machineABCZ.succeed("nix flake --version")
            machineABCZ.succeed("nix profile list")
            machineABCZ.succeed("nix registry list >&2")
            machineABCZ.succeed("nix flake metadata nixpkgs")
            machineABCZ.succeed("nix eval nixpkgs#hostPlatform.qemuArch >&2")

            machineABCZ.succeed("nix repl --file '<nixpkgs>' <<<'1 + 2'")
            machineABCZ.succeed("nix eval --impure --expr '<nixpkgs>' <<<'1 + 2'")
            machineABCZ.succeed("nix-instantiate --eval --expr '<nixpkgs>' >&2")

            machineABCZ.succeed("nix eval nixpkgs#path >&2")
            machineABCZ.succeed("echo \"$NIX_PATH\" >&2")

            machineABCZ.succeed("nix eval nixpkgs#config.allowUnfree >&2")

            # machineABCZ.succeed("nix run nixpkgs#pkgsStatic.sqlite --command sqlite3 --version")
            # machineABCZ.succeed("nix shell nixpkgs#pkgsStatic.sqlite --command sqlite3 --version")

            machineABCZ.succeed("""
              [ "$(nix-shell -p pkgsStatic.sqlite which --run "which sqlite")" = "$(nix shell nixpkgs#pkgsStatic.sqlite nixpkgs#which -c which sqlite)" ]
            """)

            machineABCZ.succeed("nix build --no-link --print-build-logs --print-out-paths nixpkgs#pkgsStatic.sqlite >&2")
            machineABCZ.succeed("nix build --no-link --print-build-logs --print-out-paths --rebuild nixpkgs#pkgsStatic.sqlite >&2")
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
            meta.description = "Run the interactive driver for the NixOS bare test";
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
