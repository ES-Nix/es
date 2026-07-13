{
  description = "QEMU VM + Docker + pure nixpkgs Flask + numpy — buildPythonApplication / withPackages / mkDerivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        myapp-bpa = prev.python3Packages.buildPythonApplication {
          pname = "myapp";
          version = "0.0.1";
          src = ./.;
          format = "pyproject";
          doCheck = false;
          nativeBuildInputs = with prev.python3Packages; [ hatchling ];
          propagatedBuildInputs = with prev.python3Packages; [
            flask
            numpy
          ];
          meta.mainProgram = "start";
        };

        myapp-wp =
          let
            pyEnv = prev.python3.withPackages (ps: with ps; [
              flask
              numpy
            ]);
            appPkg = prev.runCommand "myapp-wp-pkg" { } ''
              mkdir -p $out/app
              cp -r ${./app}/. $out/app/
            '';
          in
          prev.writeShellApplication {
            name = "start";
            runtimeInputs = [ pyEnv ];
            text = ''PYTHONPATH="${appPkg}" python3 "${appPkg}/app/main.py"'';
          };

        myapp-mk =
          let
            pyEnv = prev.python3.withPackages (ps: with ps; [
              flask
              numpy
            ]);
          in
          prev.stdenv.mkDerivation {
            pname = "myapp-mk";
            version = "0.0.1";
            src = ./.;
            nativeBuildInputs = [ prev.makeWrapper ];
            buildPhase = ":";
            installPhase = ''
              mkdir -p $out/bin $out/lib
              cp -r app $out/lib/app
              makeWrapper ${pyEnv}/bin/python3 $out/bin/start \
                --add-flags "$out/lib/app/main.py" \
                --set PYTHONPATH "$out/lib"
            '';
            meta.mainProgram = "start";
          };

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
              final.myapp-bpa
              final.busybox
            ] ++ (nonRootShadowSetup { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; });
            config = {
              Cmd = [ "start" ];
            };
          };

        testMyappAsOCIImage = prev.testers.runNixOSTest {
          name = "myapp-as-oci-image";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.virtualisation.podman.enable = true;
              config.virtualisation.diskSize = 4096;

              config.systemd.services.docker-podman-load = {
                description = "Docker and Podman load OCI Images";
                wantedBy = [ "multi-user.target" ];
                after = [ "docker.service" "podman.service" ];
                path = with pkgs; [ docker podman ];
                script = ''
                  echo "Loading OCI Images..."
                  docker load <"${final.myappOCIImage}"
                  podman load <"${final.myappOCIImage}"
                '';
                serviceConfig = {
                  Type = "oneshot";
                };
              };
            };
          globalTimeout = 20 * 60;
          testScript = ''
            start_all()

            machine.wait_until_succeeds("docker images | grep myapp")
            actual_size = int(machine.succeed("docker image inspect myapp-oci-image:0.0.1 --format '{{.Size}}'").strip())
            expected_size = 393054891
            assert actual_size == expected_size, f"OCI image size: {actual_size} bytes ({actual_size // 1024 // 1024} MiB) — set expected_size = {actual_size}"

            machine.succeed("docker run -d --name=container-app --publish=5000:5000 --rm=true myapp-oci-image:0.0.1")
            machine.wait_for_open_port(5000)
            expected = 'Hello world!!'
            result = machine.wait_until_succeeds("curl http://0.0.0.0:5000")
            assert expected == result, f"expected = {expected}, result = {result}"

            machine.succeed("docker stop container-app")

            machine.wait_until_succeeds("podman images | grep myapp")

            machine.succeed("podman run -d --name=container-app --publish=5000:5000 --rm=true myapp-oci-image:0.0.1")
            machine.wait_for_open_port(5000)
            expected = 'Hello world!!'
            result = machine.wait_until_succeeds("curl http://0.0.0.0:5000")
            assert expected == result, f"expected = {expected}, result = {result}"

            machine.succeed("podman stop container-app")
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
                  serviceConfig = { Type = "oneshot"; };
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
                    file
                    firefox
                    git
                    jq
                    lsof
                    findutils
                    dive
                    fooBar
                    final.myapp-bpa
                    final.myapp-wp
                    final.myapp-mk
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
                    plugins=(colored-man-pages docker git)
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
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
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
            myapp-bpa
            myapp-wp
            myapp-mk
            myappOCIImage
            testMyappAsOCIImage
            myvm
            automaticVm
            ;
          default = pkgs.myapp-bpa;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.myapp-bpa}";
            meta.description = "Run the Flask hello world app (buildPythonApplication)";
          };
          automaticVm = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automaticVm}";
            meta.description = "Run the NixOS VM";
          };
          testMyappAsOCIImageDriverInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testMyappAsOCIImage.driverInteractive}";
            meta.description = "Run the myapp OCI Image test in interactive mode";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            myapp-bpa
            myapp-wp
            myapp-mk
            myappOCIImage
            testMyappAsOCIImage
            automaticVm
            ;
          default = pkgs.testMyappAsOCIImage;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            myapp-bpa
            myapp-wp
            myapp-mk
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
