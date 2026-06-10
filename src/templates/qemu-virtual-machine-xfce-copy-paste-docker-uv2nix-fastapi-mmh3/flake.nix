{
  description = "A QEMU virtual machine with XFCE, copy/paste, Docker, uv2nix, FastAPI, mmh3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix/ad83f1ead0e78e57b188f35cb57298affb06fc5f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix/0497ccef038da091002be7c05263a7f27820974f";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs/7bff980f37fc24e09dbc986643719900c139bf12";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, pyproject-nix, uv2nix, pyproject-build-systems }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        myapp =
          let
            python = prev.python311;
            workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
            overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
            pythonSet = (prev.callPackage pyproject-nix.build.packages {
              inherit python;
            }).overrideScope (
              nixpkgs.lib.composeManyExtensions [
                pyproject-build-systems.overlays.wheel
                overlay
              ]
            );
          in
          (pythonSet.mkVirtualEnv "myapp-env" workspace.deps.default)
          // { meta.mainProgram = "start-app"; };

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
            expected = '{"message":"Hello world 126000048256919600573431412872524959502"}'
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
          system = prev.stdenv.hostPlatform.system;
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
                    fooBar
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
              # date +'%d/%m/%Y %H:%M:%S:%3N'
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
            myapp
            myappOCIImage
            testMyappOCIImage
            myvm
            automaticVm
            ;
          default = pkgs.myapp;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.myapp}";
            meta.description = "";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "";
          };
          automaticVm = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automaticVm}";
            meta.description = "";
          };
          testmMappAsOCIImageDriverInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testMyappOCIImage.driverInteractive}";
            meta.description = "";
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
            python311
            uv
            fooBar
          ];

          env = {
            UV_PYTHON = python311.interpreter;
            UV_PYTHON_DOWNLOADS = "never";
          };

          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true
            unset PYTHONPATH
          '';
        };
      }
    )
  );
}
