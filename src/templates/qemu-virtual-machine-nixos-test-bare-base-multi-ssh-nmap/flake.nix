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
          name = "test-bare-base-ssh-keyscan";
          nodes = {
            machineA = { config, pkgs, ... }: {
              virtualisation.vlans = [ 1 ];
              services.openssh.enable = true;
              environment.systemPackages = [ pkgs.bind pkgs.traceroute pkgs.nmap ];
              networking.firewall.enable = false;
              boot.kernel.sysctl."net.ipv4.icmp_ratelimit" = 0;
            };
            machineRouter = { config, pkgs, ... }: {
              virtualisation.vlans = [ 1 2 ];
              boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
              boot.kernel.sysctl."net.ipv4.icmp_ratelimit" = 0;
              networking.firewall.enable = false;
              environment.systemPackages = [ pkgs.traceroute pkgs.nmap ];
            };
            machineB = { config, pkgs, ... }: {
              virtualisation.vlans = [ 2 ];
              services.openssh.enable = true;
              environment.systemPackages = [ pkgs.bind pkgs.traceroute pkgs.nmap ];
              networking.firewall.enable = false;
              boot.kernel.sysctl."net.ipv4.icmp_ratelimit" = 0;
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

            with subtest("Wait for network"):
                machineA.wait_for_unit("network.target")
                machineB.wait_for_unit("network.target")
                machineRouter.wait_for_unit("network.target")

            with subtest("Discover IPs"):
                def get_ip(machine, prefix):
                    return machine.succeed(
                        f"ip -4 addr show | awk '/inet /{{print $2}}' | cut -d/ -f1 | grep '^{prefix}\\.'"
                    ).strip()

                MACHINEA_IP     = get_ip(machineA,      "192.168.1")
                ROUTER_VLAN1_IP = get_ip(machineRouter, "192.168.1")
                ROUTER_VLAN2_IP = get_ip(machineRouter, "192.168.2")
                MACHINEB_IP     = get_ip(machineB,      "192.168.2")

            with subtest("Setup cross-VLAN routes"):
                machineA.succeed(f"ip route add 192.168.2.0/24 via {ROUTER_VLAN1_IP}")
                machineB.succeed(f"ip route add 192.168.1.0/24 via {ROUTER_VLAN2_IP}")

            with subtest("Verify routing with ping"):
                machineA.succeed(f"ping -c 1 -W 2 {MACHINEB_IP}")
                machineB.succeed(f"ping -c 1 -W 2 {MACHINEA_IP}")

            with subtest("SSH keyscan"):
                machineA.wait_for_unit("sshd")
                machineB.wait_for_unit("sshd")
                machineA.succeed("type ssh-keyscan 2>&1")
                machineB.succeed("type ssh-keyscan 2>&1")
                machineA.succeed(f"ssh-keyscan {MACHINEB_IP} 2>&1")
                machineB.succeed(f"ssh-keyscan {MACHINEA_IP} 2>&1")

            with subtest("DNS (dig)"):
                machineB.wait_for_unit("bind.service")
                machineA.succeed("dig -v 2>&1 | grep -i DiG")
                machineA.succeed("dig -4 @machineB example.test A | grep -q 'status: NOERROR'")
                result = machineA.succeed("dig -4 @machineB host1.example.test A +short").strip()
                assert result == "10.0.0.1", f"Expected 10.0.0.1, got {result!r}"
                machineA.succeed("dig -4 @machineB ghost.example.test A | grep -q 'status: NXDOMAIN'")
                machineA.succeed("dig -4 @machineB example.test A | grep -q 'flags:.*aa'")
                machineA.succeed("dig -4 @machineB example.test A | grep -qP 'ANSWER: [1-9]'")
                machineA.succeed("dig -4 @machineB ghost.example.test A | grep -q 'ANSWER: 0'")
                machineA.succeed("dig -4 @machineB example.test MX | grep -q '10 mail.example.test'")
                machineA.succeed("dig -4 @machineB example.test TXT | grep -q 'v=spf1'")
                machineA.succeed("dig -4 @machineB example.test NS | grep -q 'ns1.example.test'")
                machineA.succeed("dig -4 @machineB example.test SOA | grep -q '2024010101'")
                machineA.succeed("dig -4 @machineB www.example.test A | grep -q 'CNAME'")
                machineA.succeed("dig -4 @machineB www.example.test A | grep -q 'status: NOERROR'")
                machineA.succeed("dig -4 @machineB host1.example.test A | grep -q '300.*IN.*A'")
                machineA.succeed("dig -4 @machineB example.test AAAA | grep -q 'ANSWER: 0'")
                machineA.succeed("dig -4 @machineB host1.example.test A +noall +answer | grep -q '10.0.0.1'")
                machineB.succeed("dig -4 @localhost example.test A | grep -q 'status: NOERROR'")

            with subtest("Traceroute 1: tool available"):
                machineA.succeed("traceroute --version 2>&1 | grep -qi traceroute")

            with subtest("Traceroute 2: localhost is 1 hop"):
                out = machineA.succeed("traceroute -n -q 1 127.0.0.1 2>&1")
                hops = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                assert len(hops) == 1, f"Expected 1 hop to localhost, got {len(hops)}: {out!r}"
                assert "127.0.0.1" in hops[0], f"Expected 127.0.0.1 in hop 1, got: {hops[0]!r}"

            with subtest("Traceroute 3: 2-hop path to machineB (line count)"):
                out = machineA.succeed(f"traceroute -n -q 1 {MACHINEB_IP} 2>&1")
                hops = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                assert len(hops) == 2, f"Expected 2 hops to machineB, got {len(hops)}: {out!r}"

            with subtest("Traceroute 4: hop 1 is machineRouter VLAN-1 IP"):
                out = machineA.succeed(f"traceroute -n -q 1 {MACHINEB_IP} 2>&1")
                hops = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                assert ROUTER_VLAN1_IP in hops[0], \
                    f"Expected hop 1 = {ROUTER_VLAN1_IP}, got: {hops[0]!r}"

            with subtest("Traceroute 5: hop 2 is machineB IP"):
                out = machineA.succeed(f"traceroute -n -q 1 {MACHINEB_IP} 2>&1")
                hops = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                assert MACHINEB_IP in hops[1], \
                    f"Expected hop 2 = {MACHINEB_IP}, got: {hops[1]!r}"

            with subtest("Traceroute 6: no timeouts on live 2-hop path"):
                out = machineA.succeed(f"traceroute -n -q 1 {MACHINEB_IP} 2>&1")
                assert "*" not in out, f"Unexpected timeout in traceroute to machineB: {out!r}"

            with subtest("Traceroute 7: RTT values present"):
                out = machineA.succeed(f"traceroute -n -q 1 {MACHINEB_IP} 2>&1")
                rtts = re.findall(r"\d+\.\d+ ms", out)
                assert len(rtts) >= 2, f"Expected >=2 RTT values in 2-hop output, got {len(rtts)}: {out!r}"

            with subtest("Traceroute 8: TTL=1 reaches router but NOT machineB"):
                out = machineA.succeed(f"traceroute -n -m 1 -q 1 {MACHINEB_IP} 2>&1")
                data_lines = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                assert len(data_lines) == 1, \
                    f"TTL=1: expected 1 data line, got {len(data_lines)}: {out!r}"
                assert ROUTER_VLAN1_IP in data_lines[0], \
                    f"Router IP {ROUTER_VLAN1_IP} missing from TTL=1 hop, got: {data_lines[0]!r}"
                assert MACHINEB_IP not in data_lines[0], \
                    f"machineB IP should not appear in TTL=1 hop: {data_lines[0]!r}"

            with subtest("Traceroute 9: ICMP mode (-I) same 2-hop result"):
                out = machineA.succeed(f"traceroute -n -q 1 -I {MACHINEB_IP} 2>&1")
                hops = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                assert len(hops) == 2, f"ICMP mode: expected 2 hops, got {len(hops)}: {out!r}"
                assert ROUTER_VLAN1_IP in hops[0], \
                    f"ICMP mode: hop 1 should be {ROUTER_VLAN1_IP}, got: {hops[0]!r}"
                assert MACHINEB_IP in hops[1], \
                    f"ICMP mode: hop 2 should be {MACHINEB_IP}, got: {hops[1]!r}"

            with subtest("Traceroute 10: reverse path machineB to machineA (2 hops)"):
                out = machineB.succeed(f"traceroute -n -q 1 {MACHINEA_IP} 2>&1")
                hops = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                assert len(hops) == 2, f"Reverse: expected 2 hops, got {len(hops)}: {out!r}"
                assert ROUTER_VLAN2_IP in hops[0], \
                    f"Reverse: hop 1 should be router VLAN-2 IP {ROUTER_VLAN2_IP}, got: {hops[0]!r}"
                assert MACHINEA_IP in hops[1], \
                    f"Reverse: hop 2 should be {MACHINEA_IP}, got: {hops[1]!r}"

            with subtest("Traceroute 11: unreachable host shows network error"):
                rc, out = machineA.execute("traceroute -n -m 3 -q 1 -w 1 10.99.99.99 2>&1")
                data_lines = [l for l in out.splitlines() if l.strip() and not l.startswith("traceroute")]
                # Either timeout (*) or ICMP error flags (!N=net-unreachable, !H=host-unreachable, etc.)
                assert any("*" in l or "!" in l for l in data_lines), \
                    f"Expected timeout (*) or ICMP error (!) for unreachable host, got: {out!r}"

            with subtest("Nmap 1: tool available"):
                machineA.succeed("nmap --version 2>&1 | grep -i Nmap")

            with subtest("Nmap 2: machineA discovers machineB is up (cross-VLAN)"):
                machineA.succeed(f"nmap -sn -n {MACHINEB_IP} | grep -q 'Host is up'")

            with subtest("Nmap 3: machineA discovers machineRouter VLAN1 IP is up"):
                machineA.succeed(f"nmap -sn -n {ROUTER_VLAN1_IP} | grep -q 'Host is up'")

            with subtest("Nmap 4: machineA subnet sweep finds >=2 hosts on VLAN1"):
                out = machineA.succeed("nmap -sn -n 192.168.1.0/24")
                count = out.count("Host is up")
                assert count >= 2, f"Expected >=2 hosts up on 192.168.1.0/24, got {count}: {out!r}"

            with subtest("Nmap 5: machineRouter discovers machineA via VLAN1"):
                machineRouter.succeed(f"nmap -sn -n {MACHINEA_IP} | grep -q 'Host is up'")

            with subtest("Nmap 6: machineA localhost port 22 open"):
                machineA.succeed("nmap -sT -n -p 22 127.0.0.1 | grep -q '22/tcp open'")

            with subtest("Nmap 7: machineA localhost port 53 not open (no DNS on machineA)"):
                out = machineA.succeed("nmap -sT -n -p 53 127.0.0.1")
                assert "53/tcp open" not in out, \
                    f"Port 53 should not be open on machineA: {out!r}"

            with subtest("Nmap 8: machineA to machineB port 22 open (cross-VLAN)"):
                machineA.succeed(f"nmap -sT -n -p 22 {MACHINEB_IP} | grep -q '22/tcp open'")

            with subtest("Nmap 9: machineA to machineB port 53 open (DNS cross-VLAN)"):
                machineA.succeed(f"nmap -sT -n -p 53 {MACHINEB_IP} | grep -q '53/tcp open'")

            with subtest("Nmap 10: machineA to machineRouter port 22 not open (no SSH on router)"):
                out = machineA.succeed(f"nmap -sT -n -p 22 {ROUTER_VLAN1_IP}")
                assert "22/tcp open" not in out, \
                    f"Port 22 should not be open on machineRouter: {out!r}"

            with subtest("Nmap 11: machineB localhost ports 22 and 53 both open"):
                out = machineB.succeed("nmap -sT -n -p 22,53 127.0.0.1")
                count = out.count("/tcp open")
                assert count == 2, \
                    f"Expected exactly 2 open ports (22, 53) on machineB localhost, got {count}: {out!r}"

            with subtest("Nmap 12: machineRouter to machineA port 22 open (cross-VLAN from router)"):
                machineRouter.succeed(f"nmap -sT -n -p 22 {MACHINEA_IP} | grep -q '22/tcp open'")

            with subtest("Nmap 13: machineA to machineB port 22 service is OpenSSH"):
                machineA.succeed(f"nmap -sT -sV -n -p 22 {MACHINEB_IP} | grep -qi OpenSSH")

            with subtest("Nmap 14: machineA to machineB port 53 service is domain"):
                machineA.succeed(f"nmap -sT -sV -n -p 53 {MACHINEB_IP} | grep -q 'domain'")

            with subtest("Nmap 15: machineB to machineA port 22 service is OpenSSH (reverse cross-VLAN)"):
                machineB.succeed(f"nmap -sT -sV -n -p 22 {MACHINEA_IP} | grep -qi OpenSSH")

            with subtest("Nmap 16: machineA to machineB port 80 not open (no HTTP)"):
                out = machineA.succeed(f"nmap -sT -n -p 80 {MACHINEB_IP}")
                assert "80/tcp open" not in out, \
                    f"Port 80 should not be open on machineB: {out!r}"

            with subtest("Nmap 17: machineA to non-routed IP 10.99.99.99 shows no open ports"):
                out = machineA.succeed("nmap -sT -n -p 22,53,80 10.99.99.99 2>&1 || true")
                assert "/tcp open" not in out, \
                    f"Expected no open TCP ports on non-routed IP 10.99.99.99, got: {out!r}"
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
