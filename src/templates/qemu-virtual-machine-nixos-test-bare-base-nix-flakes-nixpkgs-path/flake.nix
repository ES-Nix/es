{
  description = "";

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
              environment.systemPackages = (with pkgs; [ nix ]);

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
              # boot.readOnlyNixStore = false;
              # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.lib.getName pkg) [
              #   "vagrant"
              # ];
            };
          };
          extraPythonPackages = p: [ p.pytest ];
          testScript = { nodes, ... }: ''

            def test_machine_cmd_equal_expected(
                machine_arg,
                cmd: str,
                expected: str,
            ):
              result = machine_arg.succeed(cmd).strip()
              assert expected == result, f"expected = {expected}, result = {result}"


            def run_all_version_tests(test_cases):
                for machine, cmd, expected in test_cases:
                    test_machine_cmd_equal_expected(machine, cmd, expected)

            test_cases = [
                (machineABCZ, "nix --version", "nix (Nix) 2.28.3"),
                (machineABCZ, "nix flake --version", "nix (Nix) 2.28.3"),
                (machineABCZ, "nix eval --raw nixpkgs#lib.version", "25.05.20250612.fd48718"),
            ]
            run_all_version_tests(test_cases)

            # test_cmds_equal_expected()
            # test_cmds_equal_expected("nix --version", "nix (Nix) 2.28.3")
            machineABCZ.succeed("nix profile list")
            machineABCZ.succeed("nix registry list >&2")
            machineABCZ.succeed("nix flake metadata nixpkgs")
            machineABCZ.succeed("nix eval --raw nixpkgs#lib.version >&2")
            machineABCZ.succeed("nix eval nixpkgs#hostPlatform.qemuArch >&2")

            machineABCZ.succeed("nix repl --file '<nixpkgs>' <<<'1 + 2'")
            machineABCZ.succeed("nix eval --impure --expr '<nixpkgs>' <<<'1 + 2'")

            machineABCZ.succeed("nix eval nixpkgs#path >&2")
            machineABCZ.succeed("echo $NIX_PATH >&2")
            machineABCZ.succeed("echo \"$NIX_PATH\" >&2")

            machineABCZ.succeed("nix eval nixpkgs#config.allowUnfree >&2")

            # machineABCZ.succeed("nix eval --impure --expr '(import <nixpkgs/nixos> {}).config.system.build.toplevel.inputDerivation'")
            # machineABCZ.succeed("nix eval --expr '(builtins.getFlake "github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd").shortRev'")
            # machineABCZ.succeed("nix eval --expr '(builtins.getFlake "github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd").rev'")
          '';
        };

        testNixOSBareDriverInteractive = final.testNixOSBare.driverInteractive;

        testNixOSBareNixpkgsPath = final.testers.runNixOSTest {
          name = "test-bare-base-nixpkgs-path";
          nodes = {
            machineNixpkgsPath = { config, pkgs, ... }: {
              environment.systemPackages = (with pkgs; [ nix ]);
              nix.extraOptions = ''
                bash-prompt-prefix = (nix-develop:$name)\040
                experimental-features = nix-command flakes
                keep-build-log = true
                keep-derivations = true
                keep-env-derivations = true
                keep-failed = true
                keep-going = true
                keep-outputs = true
              '';
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
            };
          };
          testScript = { nodes, ... }: ''

            machineNixpkgsPath.succeed("""
              nix eval --impure --expr '(builtins.attrNames (builtins.getFlake (toString <nixpkgs>)).sourceInfo'
            """)

            result1 = machineNixpkgsPath.succeed("nix eval nixpkgs#path")
            result2 = machineNixpkgsPath.succeed("nix path-info nixpkgs#path")
            
            result3 = machineNixpkgsPath.succeed("nix eval --impure --expr '<nixpkgs>'")
            result4 = machineNixpkgsPath.succeed("nix eval --impure --expr 'with import <nixpkgs>{}; path'")
            
            result5 = machineNixpkgsPath.succeed("""
              nix-instantiate --eval --expr 'builtins.findFile builtins.nixPath "nixpkgs"'
            """)
            result6 = machineNixpkgsPath.succeed("""
              nix eval --impure --expr 'builtins.findFile builtins.nixPath "nixpkgs"'
            """)

            result7 = machineWithHello.succeed("nix eval --impure --raw --expr ' (builtins.getFlake (toString <nixpkgs>)).sourceInfo.outPath'")
            result8 = machineWithHello.succeed("nix eval --impure --raw --expr ' (builtins.getFlake flake:nixpkgs).sourceInfo.outPath'")
            result9 = machineWithHello.succeed("nix repl --expr 'import <nixpkgs> {}'")
            
            result = machineNixpkgsPath.succeed("nix eval --file '<nixpkgs>'")

            # 
            assert result1 == result2, f"result1 = {result1}, result2 = {result2}"
            assert result1 == result3, f"result1 = {result1}, result3 = {result3}"
            assert result1 == result4, f"result1 = {result1}, result4 = {result4}"
            assert result1 == result5, f"result1 = {result1}, result5 = {result5}"
            assert result1 == result6, f"result1 = {result1}, result6 = {result6}"
            assert result1 == result7, f"result1 = {result1}, result7 = {result7}"
            assert result1 == result8, f"result1 = {result1}, result8 = {result8}"
            assert result1 == result9, f"result1 = {result1}, result9 = {result9}"

            assert result1 in result, f"result1 = {result1}, result = {result}"
          '';
        };

        testNixOSBareNixShellHelloPaths = final.testers.runNixOSTest {
          name = "test-bare-base-nix-shell-hello-paths";
          nodes = {
            machineWithHello = { config, pkgs, ... }: {
              environment.systemPackages = (with pkgs; [ hello nix which ]);

              system.extraDependencies = with pkgs; [ hello.inputDerivation ];

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
            };
          };
          testScript = { nodes, ... }: ''

            machineWithHello.succeed("""
              [ "$(nix-shell -p hello which --run "which hello")" = "$(nix shell nixpkgs#hello nixpkgs#which -c which hello)" ]
            """)
            # result1 = machineWithHello.succeed("nix-shell -p hello --run hello")
            # result1 = machineWithHello.succeed("nix-shell -p hello --run 'hello'")
            # result1 = machineWithHello.succeed("nix-shell -p hello --run \"hello\"")
            result1 = machineWithHello.succeed("nix-shell -p hello which --run 'which hello'")
            result2 = machineWithHello.succeed("nix shell nixpkgs#hello nixpkgs#which -c which hello")
            assert result1 == result2, f"result1 = {result1}, result1 = {result1}"
          '';
        };

        testNixOSBareHelloUnfree = final.testers.runNixOSTest {
          name = "test-bare-base-hello-unfree";
          nodes = {
            machineWithHelloUnfree = { config, pkgs, ... }: {
              environment.systemPackages = (with pkgs; [ hello-unfree nix ]);

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
            };
          };
          testScript = { nodes, ... }: ''
            expected = 'aaaaaa'
            result = machineWithHelloUnfree.succeed("hello-unfree").strip()
            assert expected == result, f"expected = {expected}, result = {result}"
          '';
        };

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
            testNixOSBareNixpkgsPath
            testNixOSBareNixShellHelloPaths
            testNixOSBareHelloUnfree
            ;
          default = pkgs.testNixOSBareDriverInteractive;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSBareDriverInteractive}";
            meta.description = "";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSBareDriverInteractive
            testNixOSBareNixShellHelloPaths
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
