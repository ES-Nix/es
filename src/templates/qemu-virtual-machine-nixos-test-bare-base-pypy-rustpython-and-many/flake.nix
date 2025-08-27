{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        pkgsMusl_pypy = final.pkgsMusl.pypy;
        pkgsMusl_rustpython = final.pkgsMusl.rustpython;
        pkgsMusl_python3Minimal = final.pkgsMusl.python3Minimal;
        pkgsMusl_python3 = final.pkgsMusl.python3;
        pkgsMusl_python3Full = final.pkgsMusl.python3Full;

        pkgsStatic_pypy = final.pkgsStatic.pypy;
        pkgsStatic_rustpython = final.pkgsStatic.rustpython;
        pkgsStatic_python3Minimal = final.pkgsStatic.python3Minimal;
        pkgsStatic_python3 = final.pkgsStatic.python3;
        pkgsStatic_python3Full = final.pkgsStatic.python3Full;

        testNixOSBarePythons = final.testers.runNixOSTest {
          name = "test-bare-base";
          nodes = {
            machine_pypy = { config, pkgs, ... }: { environment.systemPackages = with final; [ pypy ]; };
            machine_rustpython = { config, pkgs, ... }: { environment.systemPackages = with final; [ rustpython ]; };
            machine_python3Minimal = { config, pkgs, ... }: { environment.systemPackages = with final; [ python3Minimal ]; };
            machine_python3 = { config, pkgs, ... }: { environment.systemPackages = with final; [ python3 ]; };
            machine_python3Full = { config, pkgs, ... }: { environment.systemPackages = with final; [ python3Full ]; };

            # machine_pkgsMusl_pypy = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsMusl_pypy ]; };
            # machine_pkgsMusl_rustpython = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsMusl_rustpython ]; };
            # machine_pkgsMusl_python3Minimal = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsMusl_python3Minimal ]; };
            # machine_pkgsMusl_python3 = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsMusl_python3 ]; };
            # machine_pkgsMusl_python3Full = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsMusl_python3Full ]; };

            # machine_pkgsStatic_pypy = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsStatic_pypy ]; };
            # machine_pkgsStatic_rustpython = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsStatic_rustpython ]; };
            # machine_pkgsStatic_python3Minimal = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsStatic_python3Minimal ]; };
            # machine_pkgsStatic_python3 = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsStatic_python3 ]; };
            # machine_pkgsStatic_python3Full = { config, pkgs, ... }: { environment.systemPackages = with final; [ pkgsStatic_python3Full ]; };
          };
          testScript = { nodes, ... }: ''
            machine_pypy.succeed("""
            ${final.pypy.meta.mainProgram} \
            -c \
            "import timeit; print(timeit.Timer('for i in range(50): oct(i)', 'gc.enable()').repeat(5))"
            """)

            # machine_rustpython.succeed("""
            # ${final.rustpython.meta.mainProgram} \
            # -c \
            # "import timeit; print(timeit.Timer('for i in range(50): oct(i)', 'gc.enable()').repeat(5))"
            # """)

            machine_python3Minimal.succeed("""
            ${final.python3Minimal.meta.mainProgram} \
            -c \
            "import timeit; print(timeit.Timer('for i in range(50): oct(i)', 'gc.enable()').repeat(5))"
            """)

            machine_python3.succeed("""
            ${final.python3.meta.mainProgram} \
            -c \
            "import timeit; print(timeit.Timer('for i in range(50): oct(i)', 'gc.enable()').repeat(5))"
            """)

            machine_python3Full.succeed("""
            ${final.python3Full.meta.mainProgram} \
            -c \
            "import timeit; print(timeit.Timer('for i in range(50): oct(i)', 'gc.enable()').repeat(5))"
            """)

          '';
        };
        testNixOSBarePythonsDriverInteractive = final.testNixOSBarePythons.driverInteractive;

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
            testNixOSBarePythons
            ;
          default = pkgs.testNixOSBarePythonsDriverInteractive;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSBarePythonsDriverInteractive}";
            meta.description = "Run the interactive test driver for the NixOS bare-metal virtual machine with various Python interpreters installed";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSBarePythonsDriverInteractive
            ;
          default = pkgs.testNixOSBarePythons;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            testNixOSBarePythons
            testNixOSBarePythonsDriverInteractive
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
