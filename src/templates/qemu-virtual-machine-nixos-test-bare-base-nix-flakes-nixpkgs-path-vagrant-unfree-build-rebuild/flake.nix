{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-registry 'github:NixOS/flake-registry/02fe640c9e117dd9d6a34efc7bcb8bd09c08111d' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
              environment.systemPackages = (with pkgs; [ vagrant nix ]);
              environment.variables.NIXPKGS_ALLOW_UNFREE = "1";

              system.extraDependencies = with pkgs; [ vagrant.inputDerivation ];

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
              boot.readOnlyNixStore = false;
              # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.lib.getName pkg) [
              #   "vagrant"
              # ];
            };
          };
          testScript = { nodes, ... }: ''
            expected = 'nix (Nix) 2.28.3'
            result = machine.succeed("nix --version").strip()
            assert expected == result, f"expected = {expected}, result = {result}"

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

            # machineABCZ.succeed("nix --option pure-eval false run nixpkgs#vagrant --version")
            # machineABCZ.succeed("nix --option pure-eval false shell nixpkgs#vagrant --command vagrant --version")

            # machineABCZ.succeed("""
            #   [ "$(nix-shell -p vagrant which --run "which vagrant")" = "$(nix shell nixpkgs#vagrant nixpkgs#which -c which vagrant)" ]
            # """)

            machineABCZ.succeed("nix --option pure-eval false build --no-link --print-build-logs --print-out-paths nixpkgs#vagrant >&2")
            machineABCZ.succeed("nix --option pure-eval false build --no-link --print-build-logs --print-out-paths --rebuild nixpkgs#vagrant >&2")
          '';
        };

        testNixOSBareDriverInteractive = final.testNixOSBare.driverInteractive // { boot.readOnlyNixStore = false; };
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
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSBareDriverInteractive}";
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
