{
  description = "A QEMU virtual machine with XFCE, copy/paste, Docker, and PHP MVC.";

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

        myappSrc = prev.stdenv.mkDerivation {
          name = "myapp-src";
          src = ./app;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/share/myapp
            cp -r . $out/share/myapp/
          '';
        };

        myapp = (prev.writeShellApplication {
          name = "start";
          runtimeInputs = [ prev.php84 ];
          text = ''
            exec php -S 0.0.0.0:8080 -t ${final.myappSrc}/share/myapp/public
          '';
        }) // { meta.mainProgram = "start"; };

        myappOCIImage =
          let
            nonRootShadowSetup = { user, uid, group, gid }: with prev; [
              (writeTextDir "etc/shadow" ''
                ${user}:!:::::::
              '')
              (writeTextDir "etc/passwd" ''
                ${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}
              '')
              (writeTextDir "etc/group" ''
                ${group}:x:${toString gid}:
              '')
              (writeTextDir "etc/gshadow" ''
                ${group}:x::
              '')
            ];
          in
          prev.dockerTools.buildLayeredImage {
            name = "myapp-oci-image";
            tag = "0.0.1";
            contents = [
              final.myapp
              final.myappSrc
              prev.busybox
              prev.php84
            ]
            ++ (nonRootShadowSetup { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; });

            config = {
              Cmd = [ "${prev.lib.getExe final.myapp}" ];
            };
          };

        testMyappOCIImage = prev.testers.runNixOSTest {
          name = "myapp-as-oci-image";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.virtualisation.docker.enable = true;

              # journalctl --unit docker-load.service -b -f
              config.systemd.services.docker-load = {
                description = "Docker load OCI Images";
                wantedBy = [ "multi-user.target" ];
                after = [ "docker.service" ];
                path = with pkgs; [ docker ];
                script = ''
                  echo "Loading OCI Images..."
                  docker load <"${final.myappOCIImage}" \
                  && docker images
                '';
                serviceConfig = {
                  Type = "oneshot";
                };
              };
            };
          globalTimeout = 2 * 60;
          testScript = ''
            start_all()

            machine.wait_until_succeeds("docker images | grep myapp")

            machine.succeed("docker run -d --name=container-app --publish=8080:8080 --rm=true myapp-oci-image:0.0.1")
            machine.wait_for_open_port(8080)
            expected = 'Hello PHP MVC!! UWUlO50F1D'
            result = machine.wait_until_succeeds("curl http://0.0.0.0:8080")
            assert expected == result, f"expected = {expected}, result = {result}"

            machine.succeed("docker stop container-app")
            expected = "curl: (7) Failed to connect to 127.0.0.1 port 8080 after"
            result = machine.fail("curl http://127.0.0.1:8080 2>&1")
            assert expected in result, f"expected = {expected}, result = {result}"
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
                  virtualisation.docker.enable = true;
                  virtualisation.podman.enable = true;

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

                # journalctl --unit docker-custom-bootstrap-1.service -b -f
                systemd.services.docker-custom-bootstrap-1 = {
                  description = "Docker Custom Bootstrap 1";
                  wantedBy = [ "multi-user.target" ];
                  after = [ "docker.service" ];
                  path = with pkgs; [ docker podman ];
                  script = ''
                    echo "Loading OCI Images in docker..."
                    docker load <"${pkgs.myappOCIImage}"
                    podman load <"${pkgs.myappOCIImage}"
                  '';
                  serviceConfig = {
                    Type = "oneshot";
                  };
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
                  extraGroups = [ "docker" "wheel" ];
                  packages = with pkgs; [
                    curl
                    dive
                    direnv
                    file
                    findutils
                    firefox
                    fzf
                    git
                    jq
                    lsof
                    final.myapp
                    starship
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
                    plugins=(
                      colored-man-pages
                      docker
                      git
                    )
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
          let name = "all-tests"; in
          (final.writeShellApplication {
            name = name;
            runtimeInputs = [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --verbose '.#'
            '';
          }) // { meta.mainProgram = name; };

      })
    ];
  } // (
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
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
            myapp
            myappOCIImage
            testMyappOCIImage
            myvm
            automaticVm
            ;
          default = pkgs.myapp;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.myapp}";
            meta.description = "Run the PHP MVC application";
          };
          automaticVm = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automaticVm}";
            meta.description = "Run the NixOS VM";
          };
          testMyappOCIImageDriverInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testMyappOCIImage.driverInteractive}";
            meta.description = "Run the myapp OCI Image test in interactive mode";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            myapp
            myappOCIImage
            testMyappOCIImage
            automaticVm
            ;
          default = pkgs.testMyappOCIImage;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            php84
            pkgs.myapp
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
