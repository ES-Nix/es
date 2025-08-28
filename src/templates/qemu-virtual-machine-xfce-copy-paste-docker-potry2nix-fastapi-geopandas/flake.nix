{
  description = "A QEMU virtual machine with XFCE, copy/paste, Docker, poetry2nix, FastAPI, and GeoPandas.";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/3c92540611f42d3fb2d0d084a6c694cd6544b609'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/f554d27c1544d9c56e5f1f8e2b8aff399803674e'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/11415c7ae8539d6292f2928317ee7a8410b28bb9' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/f554d27c1544d9c56e5f1f8e2b8aff399803674e'
      
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/b9a98080beff0903a5e5fe431f42cde1e3e50d6b'  

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/b9a98080beff0903a5e5fe431f42cde1e3e50d6b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        p2n = poetry2nix.lib.mkPoetry2Nix { pkgs = prev; };
        myapp = final.p2n.mkPoetryApplication
          {
            projectDir = final.p2n.cleanPythonSources { src = ./.; };
            preferWheels = true;

            overrides = final.p2n.defaultPoetryOverrides.extend
              (final: prev: {
                # 
              });
          } // { meta.mainProgram = builtins.head (builtins.attrNames (builtins.fromTOML (builtins.readFile ./pyproject.toml)).tool.poetry.scripts); };

        myappOCIImage =
          let

            nonRootShadowSetup = { user, uid, group, gid }: with prev; [
              (
                writeTextDir "etc/shadow" ''
                  ${user}:!:::::::
                ''
              )
              (
                writeTextDir "etc/passwd" ''
                  ${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}
                ''
              )
              (
                writeTextDir "etc/group" ''
                  ${group}:x:${toString gid}:
                ''
              )
              (
                writeTextDir "etc/gshadow" ''
                  ${group}:x::
                ''
              )
            ];
          in
          prev.dockerTools.buildLayeredImage {
            name = "myapp-oci-image";
            tag = "0.0.1";
            contents = [
              final.myapp
              # final.bashInteractive
              # final.coreutils
              final.busybox
            ]
            ++
            (nonRootShadowSetup { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; })
            ;

            config = {
              Cmd = [ "${final.myapp.meta.mainProgram or final.myapp.pname}" ];
            };
          };


        testMyappOCIImage = prev.testers.runNixOSTest {
          name = "myapp-as-oci-image";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.virtualisation.memorySize = 1024 * 4;
              config.virtualisation.diskSize = 1024 * 9;

              # journalctl --unit docker-podman-load.service -b -f
              config.systemd.services.docker-podman-load = {
                description = "Docker and Podman load OCI Images";
                wantedBy = [ "multi-user.target" ];
                after = [ "docker.service" ];
                path = with pkgs; [ docker ];
                script = ''
                  echo "Loading OCI Images..."

                  docker load <"${final.myappOCIImage}"
                '';
                serviceConfig = {
                  Type = "oneshot";
                };
              };
            };
          globalTimeout = 2 * 60;
          testScript = ''
            start_all()

            # machine.wait_for_unit("docker-podman-load") # TODO
            machine.wait_until_succeeds("docker images | grep myapp")

            machine.succeed("docker run -d --name=container-app --publish=5000:5000 --rm=true myapp-oci-image:0.0.1")
            machine.wait_for_open_port(5000)
            expected = '{"message":"Hello world 1.0.1"}'
            result = machine.wait_until_succeeds("curl http://0.0.0.0:5000")
            assert expected == result, f"expected = {expected}, result = {result}"

            machine.succeed("docker stop container-app")
            expected = "curl: (7) Failed to connect to 127.0.0.1 port 5000 after"
            result = machine.fail("curl http://127.0.0.1:5000 2>&1")
            assert expected in result, f"expected = {expected}, result = {result}"
          '';
          # hostPkgs = pkgs; # the Nixpkgs package set used outside the VMs
        };

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

                # journalctl --unit docker-custom-bootstrap-1.service -b -f
                systemd.services.docker-custom-bootstrap-1 = {
                  description = "Docker Custom Bootstrap 1";
                  wantedBy = [ "multi-user.target" ];
                  after = [ "docker.service" ];
                  path = with pkgs; [ docker ];
                  script = ''
                    echo "Loading OCI Images in docker..."

                    docker load <"${pkgs.myappOCIImage}"
                    podman load <"${pkgs.myappOCIImage}"
                  '';
                  serviceConfig = {
                    Type = "oneshot";
                  };
                };

                security.sudo.wheelNeedsPassword = false; # TODO: hardening
                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;
                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1"; # TODO: hardening
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    file
                    firefox
                    git
                    jq
                    lsof
                    findutils
                    dive
                    foo-bar
                    final.myapp
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

                # https://github.com/NixOS/nixpkgs/blob/3a44e0112836b777b176870bb44155a2c1dbc226/nixos/modules/programs/zsh/oh-my-zsh.nix#L119
                # https://discourse.nixos.org/t/nix-completions-for-zsh/5532
                # https://github.com/NixOS/nixpkgs/blob/09aa1b23bb5f04dfc0ac306a379a464584fc8de7/nixos/modules/programs/zsh/zsh.nix#L230-L231
                programs.zsh = {
                  enable = true;
                  shellAliases = {
                    vim = "nvim";
                  };

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
                              #zsh-autosuggestions # Why this causes an warn?
                              #zsh-syntax-highlighting
                            )

                    # https://nixos.wiki/wiki/Fzf
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
                  packages = with pkgs; [
                    powerline
                    powerline-fonts
                  ];
                  enableDefaultPackages = true;
                  enableGhostscriptFonts = true;
                };

                # Hack to fix annoying zsh warning, too overkill probably
                # https://www.reddit.com/r/NixOS/comments/cg102t/how_to_run_a_shell_command_upon_startup/eudvtz1/?utm_source=reddit&utm_medium=web2x&context=3
                # https://stackoverflow.com/questions/638975/how-wdo-i-tell-if-a-regular-file-does-not-exist-in-bash#comment25226870_638985
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

            ${final.lib.getExe final.myvm} & PID_QEMU="$!"

            for _ in {0..50}; do
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
            myapp
            myappOCIImage
            testMyappOCIImage
            myvm
            automatic-vm
            ;

          default = pkgs.myapp;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.myapp}";
        };

        apps.automatic-vm = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
          meta.description = "Run the NixOS VM";
        };

        apps.testMyappAsOCIImageDriverInteractive = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.testMyappOCIImage.driverInteractive}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            myapp
            myappOCIImage
            testMyappOCIImage
            automatic-vm
            ;
          default = pkgs.testMyappOCIImage;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            poetry
            foo-bar
            myapp
            # myappOCIImage
            # testMyappOCIImage
            # automatic-vm            
          ];

          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true             
          '';
        };

        # Shell for poetry.
        #     nix develop .#poetry
        # Use this shell for changes to pyproject.toml and poetry.lock.
        devShells.poetry = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };
      }
    )
  );
}
