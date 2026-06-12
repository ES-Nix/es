{
  description = "NixOS test for perf flamegraphs. This is a minimal example of how to use perf and inferno to generate flamegraphs in a NixOS test. It includes a test that runs perf with stress-ng and generates a flamegraph, which is then copied from the VM to the host. The test also checks that the flamegraph file was created and is a valid SVG file.";

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
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

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

        testNixOSPerfFlameGraphsMinimal = final.testers.runNixOSTest {
          name = "test-flamegraph-perf";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                perf # linuxPackages_latest.perf # https://discourse.nixos.org/t/which-perf-package/22399/5
                file

                librsvg
                inferno
                stress-ng
              ];

              # TODO: none of these seem to be needed?
              # boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
              # boot.kernel.sysctl."kernel.kptr_restrict" = final.lib.mkForce 0;
              # so perf can find kernel modules
              # systemd.tmpfiles.rules = [ "L /lib - - - - /run/current/system/lib" ];
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machineABCZ.execute("""
              perf record -F 99 -a -g -- stress-ng --cpu 4 --timeout 10s \
              | perf script \
              | inferno-collapse-perf \
              | inferno-flamegraph > flamegraph.svg
            """)
            
            machineABCZ.succeed("test -f flamegraph.svg")
            machineABCZ.succeed("file flamegraph.svg 1>&2")
            machineABCZ.copy_from_vm("flamegraph.svg", "")
          '';
        };

        testNixOSPerfFlameGraphs = final.testers.runNixOSTest {
          name = "test-flamegraph-perf";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                firefox
                # libsForQt5.okular
                # nodejs
                # perf-tools
                # (final.texlive.combine {
                #   inherit (final.texlive) scheme-medium latex-bin latexmk;
                # })
                # pandoc

                perf # linuxPackages_latest.perf # https://discourse.nixos.org/t/which-perf-package/22399/5
                file

                librsvg
                inferno
                stress-ng
              ];

              boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
              boot.kernel.sysctl."kernel.kptr_restrict" = final.lib.mkForce 0;
              # so perf can find kernel modules
              systemd.tmpfiles.rules = [ "L /lib - - - - /run/current/system/lib" ];

              services.xserver.enable = true;
              services.xserver.displayManager.startx.enable = true;
              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;
              services.displayManager.autoLogin.user = "root";
              services.xserver.xkb.layout = "br";
              # Internationalisation options
              i18n.defaultLocale = "en_US.UTF-8";
              console.keyMap = "br-abnt2";
              # Set your time zone.
              time.timeZone = "America/Recife";
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machine.wait_for_unit('graphical.target')              

            machineABCZ.succeed("hostname")
            machineABCZ.succeed("id 1>&2")
            machineABCZ.succeed("cat /proc/sys/kernel/perf_event_paranoid 1>&2")

            # machineABCZ.succeed("perf script flamegraph -a -F 99 sleep 1 1>&2")
            # machineABCZ.execute("""
            #   perf record -F 99 -a -g -- stress-ng --cpu 4 --timeout 10s \
            #   | perf script \
            #   | inferno-collapse-perf \
            #   | inferno-flamegraph > flamegraph.html
            # """)
            machineABCZ.execute("""
              set -euo pipefail

              perf record -F 99 -a -g -- stress-ng --cpu 4 --timeout 10s \
              && perf script \
              | inferno-collapse-perf \
              | inferno-flamegraph > flamegraph.svg
            """)
            
            machineABCZ.succeed("test -f flamegraph.svg")
            # machineABCZ.succeed("pandoc flamegraph.html -o flamegraph.pdf --verbose 1>&2")
            # machineABCZ.succeed("test -f flamegraph.pdf")
            # machineABCZ.succeed("file flamegraph.pdf 1>&2")
            # machineABCZ.succeed("file -i flamegraph.pdf 1>&2")
            # machineABCZ.succeed("cp -v flamegraph.pdf $HOME/flamegraph.pdf 1>&2")
            # machineABCZ.succeed("stat $HOME/flamegraph.pdf 1>&2")
            machineABCZ.copy_from_vm("flamegraph.svg", "")

            # machineABCZ.execute("""
            #   perf record --call-graph dwarf sleep 1 \
            #   | perf script \
            #   | inferno-collapse-perf \
            #   | inferno-flamegraph > profile.svg
            # """)
            # machineABCZ.succeed("test -f profile.svg 1>&2")
            #
            # MY_OUT = "profile.pdf"
            # machineABCZ.execute(f"rsvg-convert --format=pdf profile.svg > {MY_OUT}")
            # machineABCZ.succeed(f"test -f {MY_OUT} 1>&2")
            # machineABCZ.succeed(f"file {MY_OUT} 1>&2")
            # machineABCZ.succeed(f"file -i {MY_OUT} 1>&2")
            # machineABCZ.succeed(f"cp -v {MY_OUT} $HOME/{MY_OUT} 1>&2")
            # machineABCZ.succeed(f"stat $HOME/{MY_OUT} 1>&2")
            # machine.copy_from_vm(f"/root/{MY_OUT}", "")
          '';
        };
        testNixOSPerfFlameGraphsDriverInteractive = final.testNixOSPerfFlameGraphs.driverInteractive;
        testNixOSPerfFlameGraphsMinimalDriverInteractive = final.testNixOSPerfFlameGraphsMinimal.driverInteractive;

        testNixOSPerfFlameGraphsSvgToPdfRsvg = final.testers.runNixOSTest {
          name = "test-flamegraph-perf-svg-to-pdf-rsvg";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                perf
                file
                librsvg
                inferno
                stress-ng
              ];
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machineABCZ.execute("""
              perf record -F 99 -a -g -- stress-ng --cpu 4 --timeout 10s \
              | perf script \
              | inferno-collapse-perf \
              | inferno-flamegraph > flamegraph.svg
            """)

            machineABCZ.succeed("test -f flamegraph.svg")
            machineABCZ.succeed("rsvg-convert --format=pdf flamegraph.svg -o flamegraph.pdf")
            machineABCZ.succeed("test -f flamegraph.pdf")
            machineABCZ.succeed("file flamegraph.pdf 1>&2")
            machineABCZ.copy_from_vm("flamegraph.svg", "")
            machineABCZ.copy_from_vm("flamegraph.pdf", "")
          '';
        };
        testNixOSPerfFlameGraphsSvgToPdfRsvgDriverInteractive = final.testNixOSPerfFlameGraphsSvgToPdfRsvg.driverInteractive;

        # Uses perf's built-in flamegraph subcommand (generates self-contained HTML)
        testNixOSPerfFlameGraphsPerfSubcommand = final.testers.runNixOSTest {
          name = "test-flamegraph-perf-subcommand";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                perf
                file
                stress-ng
              ];
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machineABCZ.succeed("perf script flamegraph -a -F 99 -- stress-ng --cpu 4 --timeout 10s 1>&2")
            machineABCZ.succeed("test -f flamegraph.html")
            machineABCZ.succeed("file flamegraph.html 1>&2")
            machineABCZ.copy_from_vm("flamegraph.html", "")
          '';
        };
        testNixOSPerfFlameGraphsPerfSubcommandDriverInteractive = final.testNixOSPerfFlameGraphsPerfSubcommand.driverInteractive;

        # cargo-flamegraph ships a standalone `flamegraph` binary that works on any executable
        testNixOSPerfFlameGraphsCargoFlamegraph = final.testers.runNixOSTest {
          name = "test-flamegraph-cargo-flamegraph";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                perf
                file
                cargo-flamegraph
                stress-ng
              ];
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machineABCZ.succeed("flamegraph -o flamegraph.svg -- stress-ng --cpu 4 --timeout 10s 1>&2")
            machineABCZ.succeed("test -f flamegraph.svg")
            machineABCZ.succeed("file flamegraph.svg 1>&2")
            machineABCZ.copy_from_vm("flamegraph.svg", "")
          '';
        };
        testNixOSPerfFlameGraphsCargoFlamegraphDriverInteractive = final.testNixOSPerfFlameGraphsCargoFlamegraph.driverInteractive;

        # Node.js flamegraph via --prof + node --prof-process + inferno
        # Ref: https://nodejs.org/en/learn/diagnostics/flame-graphs
        testNixOSPerfFlameGraphsNode = final.testers.runNixOSTest {
          name = "test-flamegraph-node";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                nodejs
                perf
                file
                inferno
              ];
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machineABCZ.succeed("""
              node --prof -e "
                let s = 0;
                for (let i = 0; i < 1e8; i++) s += i;
                console.log(s);
              " 1>&2
            """)

            machineABCZ.succeed("""
              node --prof-process --preprocess -j isolate-*.log \
              | inferno-collapse-node \
              | inferno-flamegraph > flamegraph.svg
            """)

            machineABCZ.succeed("test -f flamegraph.svg")
            machineABCZ.succeed("file flamegraph.svg 1>&2")
            machineABCZ.copy_from_vm("flamegraph.svg", "")
          '';
        };
        testNixOSPerfFlameGraphsNodeDriverInteractive = final.testNixOSPerfFlameGraphsNode.driverInteractive;

        testNixOSPerfFlameGraphsSvgToPdfInkscape = final.testers.runNixOSTest {
          name = "test-flamegraph-perf-svg-to-pdf-inkscape";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                perf
                file
                librsvg
                inferno
                inkscape
                stress-ng
              ];
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machineABCZ.execute("""
              perf record -F 99 -a -g -- stress-ng --cpu 4 --timeout 10s \
              | perf script \
              | inferno-collapse-perf \
              | inferno-flamegraph > flamegraph.svg
            """)

            machineABCZ.succeed("test -f flamegraph.svg")
            machineABCZ.succeed("inkscape --export-type=pdf flamegraph.svg 1>&2")
            machineABCZ.succeed("test -f flamegraph.pdf")
            machineABCZ.succeed("file flamegraph.pdf 1>&2")
            machineABCZ.copy_from_vm("flamegraph.svg", "")
            machineABCZ.copy_from_vm("flamegraph.pdf", "")
          '';
        };
        testNixOSPerfFlameGraphsSvgToPdfInkscapeDriverInteractive = final.testNixOSPerfFlameGraphsSvgToPdfInkscape.driverInteractive;

        # Differential flamegraph: compare two perf runs to highlight regressions
        # Ref: https://docs.rs/inferno/latest/inferno/#differential-flame-graphs
        testNixOSPerfFlameGraphsDifferential = final.testers.runNixOSTest {
          name = "test-flamegraph-perf-differential";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with final; [
                perf
                file
                inferno
                stress-ng
              ];
            };
          };
          testScript = { nodes, ... }: ''
            start_all()

            machineABCZ.execute("""
              perf record -F 99 -a -g -o perf.before.data -- stress-ng --cpu 2 --timeout 5s \
              && perf script -i perf.before.data | inferno-collapse-perf > before.folded
            """)

            machineABCZ.execute("""
              perf record -F 99 -a -g -o perf.after.data -- stress-ng --cpu 4 --timeout 5s \
              && perf script -i perf.after.data | inferno-collapse-perf > after.folded
            """)

            machineABCZ.succeed("test -f before.folded")
            machineABCZ.succeed("test -f after.folded")
            machineABCZ.succeed("inferno-diff-folded before.folded after.folded | inferno-flamegraph --negate > diff.svg")
            machineABCZ.succeed("test -f diff.svg")
            machineABCZ.succeed("file diff.svg 1>&2")
            machineABCZ.copy_from_vm("diff.svg", "")
          '';
        };
        testNixOSPerfFlameGraphsDifferentialDriverInteractive = final.testNixOSPerfFlameGraphsDifferential.driverInteractive;

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
        };
      in
      {
        packages = {
          inherit (pkgs)
            fooBar
            testNixOSPerfFlameGraphs
            testNixOSPerfFlameGraphsMinimal
            testNixOSPerfFlameGraphsDriverInteractive
            testNixOSPerfFlameGraphsMinimalDriverInteractive
            testNixOSPerfFlameGraphsSvgToPdfRsvg
            testNixOSPerfFlameGraphsSvgToPdfRsvgDriverInteractive
            testNixOSPerfFlameGraphsPerfSubcommand
            testNixOSPerfFlameGraphsPerfSubcommandDriverInteractive
            testNixOSPerfFlameGraphsCargoFlamegraph
            testNixOSPerfFlameGraphsCargoFlamegraphDriverInteractive
            testNixOSPerfFlameGraphsNode
            testNixOSPerfFlameGraphsNodeDriverInteractive
            testNixOSPerfFlameGraphsSvgToPdfInkscape
            testNixOSPerfFlameGraphsSvgToPdfInkscapeDriverInteractive
            testNixOSPerfFlameGraphsDifferential
            testNixOSPerfFlameGraphsDifferentialDriverInteractive
            ;
          default = pkgs.testNixOSPerfFlameGraphs;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSPerfFlameGraphsDriverInteractive}";
            meta.description = "Run the NixOS perf flamegraph test in interactive mode";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSPerfFlameGraphsDriverInteractive
            testNixOSPerfFlameGraphsMinimalDriverInteractive
            testNixOSPerfFlameGraphsSvgToPdfRsvg
            testNixOSPerfFlameGraphsSvgToPdfRsvgDriverInteractive
            testNixOSPerfFlameGraphsPerfSubcommand
            testNixOSPerfFlameGraphsPerfSubcommandDriverInteractive
            testNixOSPerfFlameGraphsCargoFlamegraph
            testNixOSPerfFlameGraphsCargoFlamegraphDriverInteractive
            testNixOSPerfFlameGraphsNode
            testNixOSPerfFlameGraphsNodeDriverInteractive
            testNixOSPerfFlameGraphsSvgToPdfInkscape
            testNixOSPerfFlameGraphsSvgToPdfInkscapeDriverInteractive
            testNixOSPerfFlameGraphsDifferential
            testNixOSPerfFlameGraphsDifferentialDriverInteractive
            ;
          default = pkgs.testNixOSPerfFlameGraphs;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            testNixOSPerfFlameGraphs
            testNixOSPerfFlameGraphsDriverInteractive
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
