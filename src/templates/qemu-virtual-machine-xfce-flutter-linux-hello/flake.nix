{
  description = "Flutter Linux desktop hello world — buildFlutterApplication (linux) → QEMU VM with XFCE";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {

        flutterLinuxApp = prev.flutter.buildFlutterApplication {
          pname = "flutter-linux-hello";
          version = "1.0.0";
          src = ./.;
          targetFlutterPlatform = "linux";
          autoPubspecLock = ./pubspec.lock;
        };

        testFlutterLinuxHello = prev.testers.runNixOSTest {
          name = "flutter-linux-hello";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.virtualisation.memorySize = 2048;
              config.environment.systemPackages = with pkgs; [
                xorg.xvfb
                procps
                final.flutterLinuxApp
              ];
            };
          globalTimeout = 5 * 60;
          testScript = ''
            start_all()
            machine.wait_for_unit("multi-user.target")
            machine.execute("xvfb-run --auto-display flutter-linux-hello 2>/dev/null &")
            machine.wait_until_succeeds("pgrep -f flutter-linux-hello", timeout=30)
          '';
        };

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
                    file
                    git
                    jq
                    final.flutterLinuxApp
                    starship
                    direnv
                    fzf
                    sudo
                    which
                  ];
                  shell = pkgs.zsh;
                  uid = 1234;
                  autoSubUidGidRange = true;
                };

                programs.zsh = {
                  enable = true;
                  shellAliases = { vim = "nvim"; };
                  enableCompletion = true;
                  autosuggestions.enable = true;
                  syntaxHighlighting.enable = true;
                  interactiveShellInit = ''
                    export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
                    export ZSH_THEME="agnoster"
                    export ZSH_CUSTOM=${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions
                    plugins=(colored-man-pages git)
                    source $ZSH/oh-my-zsh.sh
                    export DIRENV_LOG_FORMAT=""
                    eval "$(direnv hook zsh)"
                    eval "$(starship init zsh)"
                    export FZF_BASE=$(fzf-share)
                    source "$(fzf-share)/completion.zsh"
                    source "$(fzf-share)/key-bindings.zsh"
                  '';
                  ohMyZsh.custom = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
                  promptInit = "";
                };

                fonts = {
                  fontDir.enable = true;
                  packages = with pkgs; [ powerline powerline-fonts ];
                  enableDefaultPackages = true;
                  enableGhostscriptFonts = true;
                };

                systemd.user.services.fix-zsh-warning = {
                  script = ''
                    test -f /home/nixuser/.zshrc || touch /home/nixuser/.zshrc && chown nixuser: -Rv /home/nixuser
                  '';
                  wantedBy = [ "default.target" ];
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
            export VNC_PORT=3001

            ${final.lib.getExe final.myvm} & PID_QEMU="$!"

            for _ in {0..50}; do
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

        allTests =
          let name = "all-tests";
          in final.writeShellApplication
            {
              name = name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show --all-systems '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#' \
                && nix develop '.#' --command sh -c 'true' \
                && nix flake check --verbose '.#'
              '';
            } // { meta.mainProgram = name; };

      })
    ];
  } // (
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            flutterLinuxApp
            testFlutterLinuxHello
            myvm
            automaticVm
            allTests
            ;
          default = pkgs.flutterLinuxApp;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.flutterLinuxApp}";
            meta.description = "Run the Flutter Linux desktop app";
          };
          automaticVm = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automaticVm}";
            meta.description = "Launch QEMU VM with XFCE via SPICE";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          testInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testFlutterLinuxHello.driverInteractive}";
            meta.description = "Run NixOS test in interactive mode";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            flutterLinuxApp
            testFlutterLinuxHello
            automaticVm
            ;
          default = pkgs.testFlutterLinuxHello;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            flutter
            dart
            gtk3
            pkg-config
            libepoxy
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
