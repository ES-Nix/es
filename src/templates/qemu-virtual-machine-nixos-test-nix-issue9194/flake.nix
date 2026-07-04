{
  description = "Test the nix auto-chroot store for non-root users";

  /*
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
        testNixAutoChrootStore = final.testers.runNixOSTest {
          name = "auto-chroot-store";
          nodes.machine = { config, lib, pkgs, ... }: {
            virtualisation.writableStore = true;
            environment.systemPackages = [ pkgs.nix ];
            users.users.alice = {
              isNormalUser = true;
              home = "/home/alice";
            };
            virtualisation.additionalPaths = [ pkgs.hello ];
            nix.settings.substituters = lib.mkForce [ ];
            nix.extraOptions = "experimental-features = nix-command flakes";
          };
          testScript =
            let
              pkgHello = final.hello;
            in
            ''
              start_all()
              machine.wait_for_unit("multi-user.target")

              # Pre-populate alice's chroot store while the daemon is still running
              machine.succeed("mkdir -p /home/alice/.local/share/nix/root")
              machine.succeed("nix copy --no-check-sigs --to /home/alice/.local/share/nix/root ${pkgHello}")
              machine.succeed("chown -R alice:users /home/alice/.local")

              # Simulate "nix without /nix" — stop daemon, remove stateDir
              machine.succeed("systemctl stop nix-daemon.socket nix-daemon.service")
              machine.succeed("rm -rf /nix/var/nix")

              # alice: nix should auto-detect ~/.local/share/nix/root as chroot store
              out = machine.succeed("su - alice -c 'nix store info --debug 2>&1'")
              print(out)

              assert ".local/share/nix/root" in out, \
                f"Expected chroot store path in debug output, got: {out}"

              machine.succeed("test -d /home/alice/.local/share/nix/root")

              hello_out = machine.succeed(
                "su - alice -c 'nix shell ${pkgHello} --command hello'"
              )
              assert "Hello, world!" in hello_out, \
                f"Expected 'Hello, world!' from hello, got: {hello_out}"
            '';
        };

        testNixAutoChrootStoreDriverInteractive =
          final.testNixAutoChrootStore.driverInteractive;

        # Minimal channel tarball for local use in VM tests — avoids internet.
        # default.nix returns {} so nix-env -q lists nothing but must not error.
        minimalChannelDir = final.writeTextDir "default.nix" ''
          { system ? builtins.currentSystem, config ? { }, pkgs ? { } }:
          { }
        '';

        channelTarball = final.runCommand "channel-nixexprs" { } ''
          mkdir -p staging/nixpkgs
          cp ${final.minimalChannelDir}/default.nix staging/nixpkgs/
          tar cJf $out -C staging .
        '';

        testNixIssue9194 = final.testers.runNixOSTest {
          name = "nix-issue-9194";
          nodes.machine = { config, lib, pkgs, ... }: {
            virtualisation.writableStore = true;
            environment.systemPackages = [ pkgs.nix ];
            users.users.alice = {
              isNormalUser = true;
              home = "/home/alice";
            };
            # Pre-populate VM store with the channel tarball (no substituters / internet)
            virtualisation.additionalPaths = [ final.channelTarball ];
            nix.settings.substituters = lib.mkForce [ ];
            nix.extraOptions = "experimental-features = nix-command flakes";
          };
          testScript = ''
            start_all()
            machine.wait_for_unit("multi-user.target")

            # Reproduce issue #9194: non-root user + explicit custom store in nix.conf
            machine.succeed("mkdir -p /home/alice/.config/nix")
            machine.succeed(
                "echo 'store = /home/alice/my-nix' > /home/alice/.config/nix/nix.conf"
            )
            machine.succeed("chown -R alice:users /home/alice")

            # Create the custom store directory so Nix can write to it
            machine.succeed("mkdir -p /home/alice/my-nix && chown alice:users /home/alice/my-nix")

            # Stop nix daemon — alice uses her custom local store directly
            # (mimics nixStatic on a non-NixOS machine, the exact issue #9194 scenario)
            machine.succeed("systemctl stop nix-daemon.socket nix-daemon.service")

            # Copy tarball to /tmp so it's accessible from alice's custom-store context
            machine.succeed("cp ${final.channelTarball} /tmp/nixpkgs.tar.xz")
            machine.succeed("chmod 644 /tmp/nixpkgs.tar.xz")

            # Register the local channel tarball (file:// avoids internet)
            machine.succeed(
                "su - alice -c 'nix-channel --add file:///tmp/nixpkgs.tar.xz nixpkgs'"
            )

            # Issue #9194: nix-channel --update is expected to FAIL with
            # "path '...' is not in the Nix store" because Nix validates paths
            # against /nix/store instead of the configured custom store.
            # This test PASSES while the bug is present and will FAIL when fixed
            # (update: remove machine.fail and assert success instead).
            rc, out = machine.execute("su - alice -c 'nix-channel --update 2>&1'")
            print(f"nix-channel --update (rc={rc}): {out}")
            assert rc != 0, (
                "nix-channel --update unexpectedly succeeded — "
                "issue #9194 may be fixed! Update this test to assert success."
            )
            assert "is not in the Nix store" in out, (
                f"nix-channel --update failed but NOT with the issue #9194 "
                f"path validation error. Unexpected output: {out}"
            )
            print("Issue #9194 confirmed present: custom store path rejected by nix-channel")
          '';
        };

        testNixIssue9194DriverInteractive =
          final.testNixIssue9194.driverInteractive;

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = prev.stdenv.hostPlatform.system;
          modules = [
            ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
              {
                i18n.defaultLocale = "en_US.UTF-8";
                console.keyMap = "br-abnt2";

                time.timeZone = "America/Recife";

                boot.loader.systemd-boot.enable = true;
                fileSystems."/" = { device = "/dev/hda1"; };

                virtualisation.vmVariant = {
                  virtualisation.memorySize = 1024 * 9;
                  virtualisation.diskSize = 1024 * 50;
                  virtualisation.cores = 7;
                  virtualisation.graphics = true;

                  virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                  virtualisation.qemu.options = [
                    # remote-viewer spice://localhost:3001
                    "-machine vmport=off"
                    "-vga qxl"
                    "-spice port=3001,disable-ticketing=on"
                    "-device virtio-serial"
                    "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                    "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                  ];

                  virtualisation.useNixStoreImage = false;
                  virtualisation.writableStore = true;
                };

                security.sudo.wheelNeedsPassword = false;
                users.extraGroups.nixgroup.gid = 999;
                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1";
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [ "wheel" ];
                  packages = with pkgs; [
                    nix
                    file
                    git
                    jq
                  ];
                  shell = pkgs.bash;
                  uid = 1234;
                  autoSubUidGidRange = true;
                };

                services.xserver.enable = true;
                services.xserver.xkb.layout = "br";
                services.displayManager.autoLogin.user = "nixuser";

                services.xserver.desktopManager.xfce.enable = true;
                services.xserver.desktopManager.xfce.enableScreensaver = false;
                services.xserver.videoDrivers = [ "qxl" ];
                services.spice-vdagentd.enable = true;

                nix.extraOptions = "experimental-features = nix-command flakes";

                environment.systemPackages = with pkgs; [ ];

                system.stateVersion = "25.11";
              })

            { nixpkgs.overlays = [ self.overlays.default ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvm = final.nixos-vm.config.system.build.vm;

        automaticVm = prev.writeShellApplication {
          name = "run-nixos-vm";
          runtimeInputs = with final; [ curl virt-viewer ];
          text = ''
            ${final.lib.getExe final.myvm} & PID_QEMU="$!"

            export VNC_PORT=3001

            for _ in {0..100}; do
              if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
              then
                break
              fi
              sleep 0.1
            done;

            remote-viewer spice://localhost:"$VNC_PORT"

            kill $PID_QEMU
          '';
        };

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
            myvm
            testNixAutoChrootStore
            testNixAutoChrootStoreDriverInteractive
            testNixIssue9194
            testNixIssue9194DriverInteractive
            ;
          default = pkgs.automaticVm;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automaticVm}";
            meta.description = "Run the NixOS VM with SPICE/VNC";
          };
          testNixAutoChrootStoreDriverInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixAutoChrootStoreDriverInteractive}";
            meta.description = "Run the auto-chroot-store test in interactive mode";
          };
          testNixIssue9194DriverInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixIssue9194DriverInteractive}";
            meta.description = "Run the nix-issue-9194 test in interactive mode";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          testNixAutoChrootStore = pkgs.testNixAutoChrootStore;
          testNixIssue9194 = pkgs.testNixIssue9194;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            testNixAutoChrootStore
            testNixAutoChrootStoreDriverInteractive
            testNixIssue9194
            testNixIssue9194DriverInteractive
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
