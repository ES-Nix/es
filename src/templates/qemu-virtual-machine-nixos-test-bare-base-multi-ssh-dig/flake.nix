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
              services.openssh.enable = true;
              environment.systemPackages = [ pkgs.bind ];
            };
            machineB = { config, pkgs, ... }: {
              services.openssh.enable = true;
              environment.systemPackages = [ pkgs.bind ];
              networking.firewall.allowedUDPPorts = [ 53 ];
              networking.firewall.allowedTCPPorts = [ 53 ];
              services.bind = {
                enable = true;
                listenOn = [ "any" ];
                listenOnIpv6 = [ "any" ];
                extraConfig = ''
                  allow-query { any; };
                  allow-recursion { any; };
                '';
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
            machineA.wait_for_unit("sshd")
            machineB.wait_for_unit("sshd")

            machineA.succeed("type ssh-keyscan 2>&1")
            machineB.succeed("type ssh-keyscan 2>&1")

            machineA.succeed("ssh-keyscan machineB 2>&1")
            machineB.succeed("ssh-keyscan machineA 2>&1")

            machineB.wait_for_unit("bind.service")

            machineA.succeed("dig -v 2>&1 | grep -i DiG")

            machineA.succeed("dig @machineB example.test A | grep -q 'status: NOERROR'")

            result = machineA.succeed("dig @machineB host1.example.test A +short").strip()
            assert result == "10.0.0.1", f"Expected 10.0.0.1, got {result!r}"

            machineA.succeed("dig @machineB ghost.example.test A | grep -q 'status: NXDOMAIN'")

            machineA.succeed("dig @machineB example.test A | grep -q 'flags:.*aa'")

            machineA.succeed("dig @machineB example.test A | grep -qP 'ANSWER: [1-9]'")

            machineA.succeed("dig @machineB ghost.example.test A | grep -q 'ANSWER: 0'")

            machineA.succeed("dig @machineB example.test MX | grep -q '10 mail.example.test'")

            machineA.succeed("dig @machineB example.test TXT | grep -q 'v=spf1'")

            machineA.succeed("dig @machineB example.test NS | grep -q 'ns1.example.test'")

            machineA.succeed("dig @machineB example.test SOA | grep -q '2024010101'")

            machineA.succeed("dig @machineB www.example.test A | grep -q 'CNAME'")
            machineA.succeed("dig @machineB www.example.test A | grep -q 'status: NOERROR'")

            machineA.succeed("dig @machineB host1.example.test A | grep -q '300.*IN.*A'")

            machineA.succeed("dig @machineB example.test AAAA | grep -q 'ANSWER: 0'")

            machineA.succeed("dig @machineB host1.example.test A +noall +answer | grep -q '10.0.0.1'")

            machineB.succeed("dig @localhost example.test A | grep -q 'status: NOERROR'")
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
