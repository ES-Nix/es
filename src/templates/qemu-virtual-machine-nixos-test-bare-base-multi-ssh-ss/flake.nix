{
  description = "Test NixOS in a QEMU virtual machine with a bare base configuration, using Nix CLI with flakes. This is the most basic test configuration, which can be used as a starting point for more complex tests. It tests the basic functionality of Nix CLI and flakes in a minimal NixOS environment.";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        testNixOSBare = final.testers.runNixOSTest {
          name = "test-bare-base-ssh-ss";
          nodes = {
            machineA = { config, pkgs, ... }: {
              services.openssh.enable = true;
              environment.systemPackages = [ pkgs.bind pkgs.netcat-gnu ];
            };
            machineB = { config, pkgs, ... }: {
              services.openssh.enable = true;
              environment.systemPackages = [ pkgs.bind pkgs.netcat-gnu ];
              networking.firewall.allowedUDPPorts = [ 53 ];
              networking.firewall.allowedTCPPorts = [ 53 ];
              services.bind = {
                enable = true;
                listenOn = [ "any" ];
                listenOnIpv6 = [ "any" ];
                zones."example.test" = {
                  master = true;
                  file = pkgs.writeText "example.test.zone" ''
                    $ORIGIN example.test.
                    $TTL 300
                    @ IN SOA ns1 admin (
                      2024010101 ; serial
                      3600       ; refresh
                      900        ; retry
                      604800     ; expire
                      300        ; minimum TTL
                    )
                    @ IN NS ns1
                    ns1 IN A 10.0.0.2
                    @ IN A 10.0.0.1
                    host1 IN A 10.0.0.1
                    @ IN MX 10 mail
                    mail IN A 10.0.0.10
                    @ IN TXT "v=spf1 include:example.test ~all"
                    www IN CNAME @
                  '';
                };
              };
            };
          };
          testScript = { nodes, ... }: ''
            import re

            start_all()

            with subtest("SS 1: ss tool available on both machines"):
                machineA.wait_for_unit("sshd")
                machineB.wait_for_unit("sshd")
                machineB.wait_for_unit("bind.service")
                machineA.succeed("command -v ss")
                machineB.succeed("command -v ss")

            with subtest("SS 2: machineB sshd listening on TCP:22"):
                machineB.succeed("ss -tlnp | grep -q ':22'")

            with subtest("SS 3: machineB BIND listening on TCP:53"):
                machineB.succeed("ss -tlnp | grep -q ':53'")

            with subtest("SS 4: machineB BIND listening on UDP:53"):
                machineB.succeed("ss -ulnp | grep -q ':53'")

            with subtest("SS 5: machineA sshd listening on TCP:22"):
                machineA.succeed("ss -tlnp | grep -q ':22'")

            with subtest("SS 6: machineA has no TCP:53 (no DNS server on machineA)"):
                out = machineA.succeed("ss -tlnp")
                assert ":53" not in out, f"machineA should not listen on TCP:53, got: {out!r}"

            with subtest("SS 7: machineB has no TCP:80 (no HTTP server)"):
                out = machineB.succeed("ss -tlnp")
                assert ":80" not in out, f"machineB should not listen on TCP:80, got: {out!r}"

            with subtest("SS 8: ss -tlnp on machineB shows sshd process"):
                machineB.succeed("ss -tlnp | grep -q 'sshd'")

            with subtest("SS 9: ss -tlnp on machineB shows named process (BIND)"):
                machineB.succeed("ss -tlnp | grep -q 'named'")

            with subtest("SS 10: ss -s summary has TCP line with total >= 1"):
                out = machineB.succeed("ss -s")
                assert "TCP:" in out, f"Expected 'TCP:' in ss -s output, got: {out!r}"
                match = re.search(r"TCP:\s*(\d+)\s*\(", out)
                assert match, f"Expected 'TCP: N (' pattern in ss -s, got: {out!r}"
                total = int(match.group(1))
                assert total >= 1, f"Expected TCP total >= 1 in ss -s, got {total}"

            with subtest("SS 11: sport filter returns only :22 LISTEN entries on machineB"):
                out = machineB.succeed("ss -tlnp 'sport = :22'")
                listen_lines = [l for l in out.splitlines() if "LISTEN" in l]
                assert len(listen_lines) >= 1, f"Expected >=1 LISTEN on :22, got: {out!r}"
                for line in listen_lines:
                    assert ":22" in line, f"sport=:22 filter returned non-22 port: {line!r}"

            with subtest("SS 12: nc listener on machineA:9999 visible in ss -tlnp"):
                machineA.execute("nc -l -p 9999 > /dev/null 2>&1 &")
                machineA.wait_until_succeeds("ss -tlnp | grep -q ':9999'")

            with subtest("SS 13: UDP sockets show UNCONN state — not LISTEN like TCP"):
                out = machineB.succeed("ss -ulnp | grep ':53'")
                assert "UNCONN" in out, f"Expected UNCONN state for UDP:53, got: {out!r}"
                assert "LISTEN" not in out, f"UDP:53 should show UNCONN not LISTEN, got: {out!r}"

            with subtest("SS 14: machineB IPv4 TCP listeners include ports 22 and 53"):
                out = machineB.succeed("ss -4 -t -l -n")
                ports_found = set(re.findall(r":(\d+)\s", out))
                assert "22" in ports_found, f"Port 22 missing from IPv4 TCP listeners: {out!r}"
                assert "53" in ports_found, f"Port 53 missing from IPv4 TCP listeners: {out!r}"
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
