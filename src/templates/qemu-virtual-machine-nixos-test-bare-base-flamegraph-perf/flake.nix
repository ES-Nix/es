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
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
                linuxPackages_latest.perf # https://discourse.nixos.org/t/which-perf-package/22399/5
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

                linuxPackages_latest.perf # https://discourse.nixos.org/t/which-perf-package/22399/5
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
            ;
          default = pkgs.testNixOSPerfFlameGraphs;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSPerfFlameGraphsDriverInteractive}";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSPerfFlameGraphsDriverInteractive
            ;
          default = pkgs.testNixOSPerfFlameGraphs;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
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
