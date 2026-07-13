{
  description = "NixOS VM test: nix-collect-garbage workaround for stale per-user gcroots (NixOS/nix#4419). Deletes /nix/var/nix/gcroots/per-user/$NAME and /nix/var/nix/profiles/per-user/$NAME before running nix-collect-garbage.";

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
          name = "test-bare-base";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with pkgs; [ nix python3 ];

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

            machineABCZ.succeed("echo '=== M0: initial state ===' >&2")
            machineABCZ.succeed("du -cksh /nix >&2")
            machineABCZ.succeed(
                "nix path-info --json --all"
                " | python3 -c 'import json,sys; d=json.load(sys.stdin);"
                " print(sum(v[\"narSize\"] for v in d.values() if \"narSize\" in v))' >&2"
            )
            machineABCZ.succeed(
                "nix path-info --closure-size /run/current-system"
                " | awk '{printf \"closure: %.2f GiB\\n\", $2/1024/1024/1024}' >&2"
            )
            machineABCZ.succeed(
                "echo 'dead paths (sobrando):' >&2"
                " && nix-store --gc --print-dead 2>/dev/null | wc -l >&2"
            )

            # Phase 1: broken gcroot symlink — modern Nix (nixos-25.11+) exits 0 and removes it
            machineABCZ.succeed("mkdir -p /nix/var/nix/gcroots/per-user/testuser")
            machineABCZ.succeed(
                "ln -s /nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-nonexistent "
                "/nix/var/nix/gcroots/per-user/testuser/stale"
            )
            machineABCZ.succeed("mkdir -p /nix/var/nix/profiles/per-user/testuser")
            # find broken gcroots: symlinks in /nix/var/nix/gcroots whose target does not exist
            machineABCZ.succeed(
                "find /nix/var/nix/gcroots -type l ! -exec test -e {} \\; -print"
                " | grep -qF /nix/var/nix/gcroots/per-user/testuser/stale"
            )
            # nix-collect-garbage must exit 0 with broken gcroot symlinks (NixOS/nix#4419 fixed in modern Nix)
            machineABCZ.succeed("nix-collect-garbage")
            # broken symlink persists — gc does not remove dead gcroot links, workaround still needed
            machineABCZ.succeed("test -L /nix/var/nix/gcroots/per-user/testuser/stale")

            machineABCZ.succeed("echo '=== M1: after phase-1 gc ===' >&2")
            machineABCZ.succeed("du -cksh /nix >&2")
            machineABCZ.succeed(
                "nix path-info --json --all"
                " | python3 -c 'import json,sys; d=json.load(sys.stdin);"
                " print(sum(v[\"narSize\"] for v in d.values() if \"narSize\" in v))' >&2"
            )
            machineABCZ.succeed(
                "nix path-info --closure-size /run/current-system"
                " | awk '{printf \"closure: %.2f GiB\\n\", $2/1024/1024/1024}' >&2"
            )
            machineABCZ.succeed(
                "echo 'dead paths (sobrando):' >&2"
                " && nix-store --gc --print-dead 2>/dev/null | wc -l >&2"
            )

            # Phase 2: apply workaround — delete per-user entries, then gc must succeed
            machineABCZ.succeed("rm -rf /nix/var/nix/gcroots/per-user/testuser")
            machineABCZ.succeed("rm -rf /nix/var/nix/profiles/per-user/testuser")
            # after cleanup, no broken gcroots remain under per-user
            machineABCZ.fail(
                "find /nix/var/nix/gcroots/per-user -type l ! -exec test -e {} \\; -print"
                " | grep -q ."
            )
            machineABCZ.succeed("nix-collect-garbage")

            # Verify cleanup
            machineABCZ.fail("test -d /nix/var/nix/gcroots/per-user/testuser")
            machineABCZ.fail("test -d /nix/var/nix/profiles/per-user/testuser")

            machineABCZ.succeed("echo '=== M2: after phase-2 gc (workaround) ===' >&2")
            machineABCZ.succeed("du -cksh /nix >&2")
            machineABCZ.succeed(
                "nix path-info --json --all"
                " | python3 -c 'import json,sys; d=json.load(sys.stdin);"
                " print(sum(v[\"narSize\"] for v in d.values() if \"narSize\" in v))' >&2"
            )
            machineABCZ.succeed(
                "nix path-info --closure-size /run/current-system"
                " | awk '{printf \"closure: %.2f GiB\\n\", $2/1024/1024/1024}' >&2"
            )
            machineABCZ.succeed(
                "echo 'dead paths (sobrando):' >&2"
                " && nix-store --gc --print-dead 2>/dev/null | wc -l >&2"
            )
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
