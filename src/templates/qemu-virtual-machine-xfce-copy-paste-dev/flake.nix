{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        OCIImagePosgresAmd64 = prev.dockerTools.pullImage {
          finalImageTag = "17.0-alpine3.20";
          finalImageName = "postgres";
          imageDigest = "sha256:14195b0729fce792f47ae3c3704d6fd04305826d57af3b01d5b4d004667df174";
          imageName = "docker.io/library/postgres";
          name = "docker.io/library/postgres";
          sha256 = "sha256-jUmnIMmbfxQB8hJtxpz1U3wwrHCwAaCs2lPo5VuaDQU=";
          os = "linux";
          arch = "amd64";
        };

        OCIImageRedisAmd64 = prev.dockerTools.pullImage {
          finalImageTag = "7.4.1-alpine3.20";
          finalImageName = "redis";
          imageDigest = "sha256:de13e74e14b98eb96bdf886791ae47686c3c5d29f9d5f85ea55206843e3fce26";
          imageName = "docker.io/library/redis";
          name = "docker.io/library/redis";
          sha256 = "sha256-aG8v4pm9hmDlmADxYv6NaegkcsI6k44il+GT5fNnU5s=";
          os = "linux";
          arch = "amd64";
        };

        OCIImagePythonAmd64 = prev.dockerTools.pullImage {
          finalImageTag = "3.13.0-slim-bookworm";
          finalImageName = "python";
          imageDigest = "sha256:751d8bece269ba9e672b3f2226050e7e6fb3f3da3408b5dcb5d415a054fcb061";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-ANHf16QObaOVQujHOqqpaqmNzR9kGFBbqj0OzKH7els=";
          os = "linux";
          arch = "amd64";
        };

        OCIImageUbuntu2404Amd64 = prev.dockerTools.pullImage {
          finalImageTag = "24.04";
          imageDigest = "sha256:36fa0c7153804946e17ee951fdeffa6a1c67e5088438e5b90de077de5c600d4c";
          imageName = "docker.io/library/ubuntu";
          name = "docker.io/library/ubuntu";
          sha256 = "sha256-saru9GIEIw1ZtwvyHKfRTOOc9BHD65MxVB1L3l/xEtA=";
        };

        OCIImageAlpine320Amd64 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3";
          imageDigest = "sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-jGOIwPKVsjIbmLCS3w0AiAuex3YSey43n/+CtTeG+Ds=";
          os = "linux";
          arch = "amd64";
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

                    docker load <"${pkgs.OCIImageAlpine320Amd64}"
                    docker load <"${pkgs.OCIImageUbuntu2404Amd64}"
                    docker load <"${pkgs.OCIImagePosgresAmd64}"
                    docker load <"${pkgs.OCIImageRedisAmd64}"
                    docker load <"${pkgs.OCIImagePythonAmd64}"
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
                    "kubernetes"
                    "kvm"
                    "libvirtd"
                    "nixgroup"
                    "podman"
                    "qemu-libvirtd"
                    "root"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    awscli
                    bashInteractive
                    btop
                    coreutils
                    direnv
                    dive
                    docker
                    docker-compose
                    file
                    findutils
                    firefox
                    fzf
                    gh
                    git
                    gnumake
                    jq
                    lsof
                    nix-info
                    openssh
                    openssl
                    tree
                    xorg.xhost

                    yarn
                    nodejs
                    bun
                    nest-cli
                    nodePackages.typescript


                    jetbrains.pycharm-community
                    (python3.withPackages (pyPkgs: with pyPkgs; [
                      # pip
                      # django
                      djangorestframework
                      # djangorestframework-simplejwt
                      psycopg2

                      # django-redis
                      # django-debug-toolbar
                    ]))
                    starship
                    sudo
                    which

                    foo-bar
                  ];
                  shell = pkgs.zsh;
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

                /*
              https://github.com/vimjoyer/sops-nix-video/tree/25e5698044e60841a14dcd64955da0b1b66957a2
              https://github.com/Mic92/sops-nix/issues/65#issuecomment-929082304
              https://discourse.nixos.org/t/qmenu-secrets-sops-and-nixos/13621/8
              https://www.youtube.com/watch?v=1BquzE3Yb4I
              https://github.com/FiloSottile/age#encrypting-to-a-github-user
              https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html

              sudo cat /run/secrets/example-key
                */
                /*
              sops.defaultSopsFile = ./secrets/secrets.yaml.encrypted;
              sops.defaultSopsFormat = "yaml";
              sops.gnupg.sshKeyPaths = [];
              sops.age.sshKeyPaths = [];
              sops.age.keyFile = ./secrets/keys.txt;
              sops.secrets.example-key = { };
                */

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

                nix.extraOptions = "experimental-features = nix-command flakes";

                # environment.variables.STATIC_NIX = "${pkgs.lib.getExe pkgs.pkgsStatic.nixVersions.nix_2_23}";

                environment.systemPackages = with pkgs; [

                ];

                system.stateVersion = "24.05";
              })

            { nixpkgs.overlays = [ self.overlays.default ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvm = final.nixos-vm.config.system.build.vm;

        automatic-vm = prev.writeShellApplication {
          name = "run-nixos-vm";
          runtimeInputs = with final; [ curl virt-viewer ];
          /*
              Pode ocorrer uma condição de corrida de seguinte forma:
              a VM inicializa (o processo não é bloqueante, executa em background)
              o spice/VNC interno a VM inicializa
              o remote-viewer tenta conectar, mas o spice não está pronto ainda

              TODO: idealmente não deveria ser preciso ter mais uma dependência (o curl)
                    para poder sincronizar o cliente e o server. Será que no caso de
                    ambos estarem na mesma máquina seria melhor usar virt-viewer -fw?
              https://unix.stackexchange.com/a/698488
            */
          text = ''

              # https://unix.stackexchange.com/a/230442
              # export NO_AT_BRIDGE=1
              # https://gist.github.com/eoli3n/93111f23dbb1233f2f00f460663f99e2#file-rootless-podman-wayland-sh-L25
              export LD_LIBRARY_PATH="${prev.libcanberra-gtk3}"/lib/gtk-3.0/modules

              ${final.myvm}/bin/run-nixos-vm & PID_QEMU="$!"

              export VNC_PORT=3001

              for _ in web{0..50}; do
                if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
                then
                  break
                fi
                # date +'%d/%m/%Y %H:%M:%S:%3N'
                sleep 0.2
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
            myvm
            automatic-vm
            ;

          default = pkgs.automatic-vm;
        };

        # packages.myvm = pkgs.myvm;
        # packages.automatic-vm = pkgs.automatic-vm;

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            automatic-vm
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
          ];

          shellHook = ''
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
