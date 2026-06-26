{
  description = "NixOS VM test: nix-collect-garbage workaround for stale per-user gcroots (NixOS/nix#4419). Deletes /nix/var/nix/gcroots/per-user/$NAME and /nix/var/nix/profiles/per-user/$NAME before running nix-collect-garbage.";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

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

        testNixOSBare = final.testers.runNixOSTest {
          name = "test-bare-base";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with pkgs; [ nix ];

              users.users.testuser = {
                isNormalUser = true;
              };

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
            };
          };
          testScript = { nodes, ... }: ''
            machineABCZ.start()
            machineABCZ.wait_for_unit("multi-user.target")

            # Phase 1: reproduce the bug — stale gcroot symlink causes nix-collect-garbage to fail
            machineABCZ.succeed("mkdir -p /nix/var/nix/gcroots/per-user/testuser")
            machineABCZ.succeed(
                "ln -s /nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-nonexistent "
                "/nix/var/nix/gcroots/per-user/testuser/stale"
            )
            machineABCZ.succeed("mkdir -p /nix/var/nix/profiles/per-user/testuser")
            machineABCZ.fail("nix-collect-garbage 2>/dev/null")

            # Phase 2: apply workaround — delete per-user entries, then gc must succeed
            machineABCZ.succeed("rm -rf /nix/var/nix/gcroots/per-user/testuser")
            machineABCZ.succeed("rm -rf /nix/var/nix/profiles/per-user/testuser")
            machineABCZ.succeed("nix-collect-garbage")

            # Verify cleanup
            machineABCZ.fail("test -d /nix/var/nix/gcroots/per-user/testuser")
            machineABCZ.fail("test -d /nix/var/nix/profiles/per-user/testuser")
          '';
        };

        testNixOSBareDriverInteractive = final.testNixOSBare.driverInteractive;
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
            meta.description = "Run the interactive driver for the test";
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
