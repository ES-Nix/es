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
        f00Bar = prev.hello;

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = prev.system;
          modules = [
            ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
              {
                # Internationalisation options
                i18n.defaultLocale = "en_US.UTF-8";
                console.keyMap = "br-abnt2";

                # Set your time zone.
                time.timeZone = "America/Recife";

                # Why
                # nix flake show --impure .#
                # break if it does not exists?
                # Use systemd boot (EFI only)
                boot.loader.systemd-boot.enable = true;
                fileSystems."/" = { device = "/dev/hda1"; };

                virtualisation.vmVariant =
                  {
                    virtualisation.docker.enable = true;
                    virtualisation.podman.enable = true;

                    virtualisation.memorySize = 1024 * 9; # Use MiB memory.
                    virtualisation.diskSize = 1024 * 50; # Use MiB memory.
                    virtualisation.cores = 7; # Number of cores.
                    virtualisation.graphics = true;

                    virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                    virtualisation.qemu.options = [
                      # https://www.spice-space.org/spice-user-manual.html#Running_qemu_manually
                      # remote-viewer spice://localhost:3001

                      # "-daemonize" # How to save the QEMU PID?
                      "-machine vmport=off"
                      "-vga qxl"
                      "-spice port=3001,disable-ticketing=on"
                      "-device virtio-serial"
                      "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                      "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                    ];

                    virtualisation.useNixStoreImage = false; # TODO: hardening
                    virtualisation.writableStore = true; # TODO: hardening
                  };

                # security.pam.services.sshd.allowNullPassword = true;
                virtualisation.vmVariant.virtualisation.forwardPorts = [
                  { from = "host"; host.port = 2222; guest.port = 2222; }
                ];
                networking.firewall.enable = false; # TODO: hardening
                # networking.firewall.allowedTCPPorts = [ (builtins.head config.virtualisation.vmVariant.virtualisation.forwardPorts).guest.port ];

                security.sudo.wheelNeedsPassword = false; # TODO: hardening
                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;
                users.users.nixuser = {
                  isSystemUser = true;
                  #  password = "1"; # TODO: hardening
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "wheel"
                    "sshd"
                  ];
                  packages = with pkgs; [
                    socat
                    file
                    git
                    jq
                    lsof
                    findutils
                    f00Bar
                    sudo
                    which
                    zsh
                  ];
                  shell = pkgs.bashInteractive;
                  uid = 1234;
                  autoSubUidGidRange = true;
                };

                services.xserver.enable = true;
                services.xserver.xkb.layout = "br";
                services.displayManager.autoLogin.user = "nixuser";
                services.xserver.displayManager.sessionCommands = ''
                  exo-open \
                    --launch TerminalEmulator \
                    --zoom=-3 \
                    --geometry 154x40
                '';

                # https://nixos.org/manual/nixos/stable/#sec-xfce
                services.xserver.desktopManager.xfce.enable = true;
                services.xserver.desktopManager.xfce.enableScreensaver = false;
                services.xserver.videoDrivers = [ "qxl" ];
                services.spice-vdagentd.enable = true; # For copy/paste to work

                nix.extraOptions = "experimental-features = nix-command flakes";

                environment.systemPackages = with pkgs; [
                ];

                system.stateVersion = "25.05";
              })

            { nixpkgs.overlays = [ self.overlays.default ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvm = final.nixos-vm.config.system.build.vm;

        automatic-vm = prev.writeShellApplication {
          name = "run-nixos-vm";
          runtimeInputs = with final; [ curl virt-viewer ];
          text = ''
            export VNC_PORT=3001

            ${final.myvm}/bin/run-nixos-vm & PID_QEMU="$!"

            for _ in {0..100}; do
              if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
              then
                break
              fi
              # date +'%d/%m/%Y %H:%M:%S:%3N'
              sleep 0.1
            done;

            remote-viewer spice://localhost:"$VNC_PORT"

            kill $PID_QEMU
          '';
        };

        testNixOSSocat = final.testers.runNixOSTest {
          name = "test-socat";
          nodes = {
            machineServerWithSocat = { config, pkgs, ... }: {
              environment.systemPackages = with pkgs; [ socat ];
              networking.firewall.allowedTCPPorts = [ 2222 ];
            };
            machineClient = { config, pkgs, ... }: { };
          };
          testScript = { nodes, ... }: ''
            # machineServerWithSocat.start()
            # machineClient.start()
            # Race condition if not exists!
            machineServerWithSocat.wait_for_unit("default.target")
            machineClient.wait_for_unit("default.target")

            machineServerWithSocat.succeed("echo 111222333 > ~/l0g.txt")
            machineServerWithSocat.execute("socat TCP-LISTEN:2222,reuseaddr,fork EXEC:/bin/sh >&2 &")
            
            machineClient.succeed("nc -w 1 machineServerWithSocat 2222 <<<'ls -alh' >&2")
            machineClient.fail("socat >&2")

            result = machineClient.succeed("nc -w 1 machineServerWithSocat 2222 <<<'id'").strip()
            expected = "uid=0(root) gid=0(root) groups=0(root)".strip()
            assert expected == result, f"Expected result to be {expected}, but got {result}"

            result = machineClient.succeed("nc -w 1 machineServerWithSocat 2222 <<<'cat ~/l0g.txt'")
            expected = "111222333"
            assert expected in result, f"Expected result to be {expected}, but got {result}"
          '';
        };
        testNixOSSocatDriverInteractive = final.testNixOSSocat.driverInteractive;

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
            f00Bar
            myvm
            automatic-vm
            ;

          # default = pkgs.f00Bar;
          default = pkgs.testNixOSSocat;

        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            f00Bar
            automatic-vm
            testNixOSSocat
            testNixOSSocatDriverInteractive
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            f00Bar
            automatic-vm
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
