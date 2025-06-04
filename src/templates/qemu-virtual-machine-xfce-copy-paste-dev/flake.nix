{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/e2605d0744c2417b09f8bf850dfca42fcf537d34' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    107d5ef05c0b1119749e381451389eded30fb0d5

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/afb2b21ba489196da32cd9f0072e0dce6588a20a' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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

        # docker manifest inspect postgres:16.6-bookworm
        OCIImagePosgres16Amd64 = prev.dockerTools.pullImage {
          # finalImageTag = "16.6-bookworm";
          finalImageTag = "16";
          finalImageName = "postgres";
          imageDigest = "sha256:ecff22ff52f839699525a5b2806a9f83704fabc938e909346db5120c41e5538c";
          imageName = "docker.io/library/postgres";
          name = "docker.io/library/postgres";
          sha256 = "sha256-5gNRHUC3hQaNKOqwW2zbdVnZuWTEQ/+fNllI1Af01CM=";
          os = "linux";
          arch = "amd64";
        };

        # docker manifest inspect postgres:14.2
        OCIImagePosgres14Amd64 = prev.dockerTools.pullImage {
          finalImageTag = "14.2";
          finalImageName = "postgres";
          imageDigest = "sha256:d6809f4833ca6caf11a4969a7f41420d3e5fcf26b8c9ca4253c34d5a5fa377cc";
          imageName = "docker.io/library/postgres";
          name = "docker.io/library/postgres";
          sha256 = "sha256-5H+rLDgxkCCJVTYaMf3gE38K2yM1hNu4IhTnF89kiLE=";
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

        OCIImagePython311Amd64 = prev.dockerTools.pullImage {
          finalImageTag = "3.11-slim";
          finalImageName = "python";
          imageDigest = "sha256:ed31f1a790f88f4c32de74a4bd6a9331c46b9bd70c9943aa92a6a24bff6c8a79";
          imageName = "docker.io/library/python";
          name = "docker.io/library/python";
          sha256 = "sha256-Rphv8SYAuI0W9EwjziN2iOV4SJZI2dhizXZdgl25wO0=";
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

        OCIImageRedisBookwormAmd64 = prev.dockerTools.pullImage {
          # finalImageTag = "7.4.2-bookworm";
          finalImageTag = "latest";
          imageDigest = "sha256:415652fd6fe63c7a6b6775044101aee354b657dfa2546a590b410a7076c3c5c3";
          imageName = "docker.io/library/redis";
          name = "docker.io/library/redis";
          sha256 = "sha256-kyTT0vR0euFmWUBnYh6hO3f5wh6KYxhIJkjgaK+efKI=";
          os = "linux";
          arch = "amd64";
        };

        OCIImageKeycloak2003Amd64 = prev.dockerTools.pullImage {
          finalImageTag = "20.0.3";
          imageDigest = "sha256:c167807890ff63fd10dacef2ab6fd2242487a940ce290a9417a373da66e862e9";
          imageName = "docker.io/keycloak/keycloak";
          name = "docker.io/keycloak/keycloak";
          sha256 = "sha256-3M9VpD3RIQLs8s3+9wBkAcU+eoboalB2p0SOMB1dUrc=";
          os = "linux";
          arch = "amd64";
        };

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = prev.system;
          modules = [

            # Allows for not have to download nixpkgs and syncs source code of nixpkgs.
            # TODO: explain it better
            ({ ... }: {
              nix.registry.nixpkgs.flake = nixpkgs;
              # nix.registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
            })

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

                    virtualisation.memorySize = 1024 * 14; # Use MiB memory.
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

                    docker load <"${pkgs.OCIImageRedisBookwormAmd64}"
                    docker load <"${pkgs.OCIImagePosgres16Amd64}"
                    docker load <"${pkgs.OCIImagePosgres14Amd64}"
                    docker load <"${pkgs.OCIImagePython311Amd64}"
                    docker load <"${pkgs.OCIImageKeycloak2003Amd64}"

                    docker load <"${pkgs.OCIImageAlpine320Amd64}"
                    # docker load <"${pkgs.OCIImageUbuntu2404Amd64}"
                    # docker load <"${pkgs.OCIImagePosgresAmd64}"
                    # docker load <"${pkgs.OCIImageRedisAmd64}"
                    # docker load <"${pkgs.OCIImagePythonAmd64}"                    
                  '';
                  serviceConfig = {
                    Type = "oneshot";
                  };
                };

                # ollama run deepseek-r1:1.5b
                # ollama run deepseek-r1:14b <<<'Faça uma receita de lasanha vegetariana.'
                # ollama run deepseek-r1:14b <<<'Need an MINLP global solver solution written in Julia to the TSP problem.'
                services.ollama.enable = true;

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
                    qbittorrent
                    graphviz

                    nettools
                    iproute2

                    ffmpeg
                    kdePackages.okular # okular
                    gnome-font-viewer

                    # julia
                    # julia-bin
                    /*
                      (julia.withPackages.override {
                        precompile = false; # Turn off precompilation
                      }) ["Plots"]
                    */
                    # (julia.withPackages [
                    ((julia.withPackages.override {
                      precompile = false; # Turn off precompilation
                    }) [
                      /*
                          # Begin (MI)NLP Solvers
                          "Alpine"
                          "Couenne_jll"
                          "GLPK"
                          "HiGHS"
                          "Ipopt"
                          "JuMP"
                          "Juniper"
                          "Pajarito"
                          "Pavito"
                          "SCIP"
                          # "EAGO"
                          # "Minotaur"
                          # "Octeract"
                          # "SHOT"
                          # End (MI)NLP Solvers

                          # MIT 
                          # "Juniper" # (MI)SOCP, (MI)NLP
                          # "SCS" # LP, QP, SOCP, SDP
                          # "DAQP" # (Mixed-binary) QP
                          */

                      # "KNITRO"
                      # "AmplNLWriter"
                      # "PolyJuMP"
                      # "SCS"
                      # "CDDLib"
                      # "MosekTools"
                      # "EAGO_jll"
                      # "PATHSolver.jl"
                      "DAQP"

                      /*
                          # Other tools
                          "ArgParse" 
                          # "Arpack"          
                          "BenchmarkProfiles"
                          "BenchmarkTools"
                          "Catalyst"
                          "CategoricalArrays"
                          "Chain"
                          "Clustering"      
                          "Colors"
                          "ComponentArrays"
                          "Crayons" # Needed for OhMyREPL color scheme
                          "CSV"          
                          "Dagitty"
                          "DataFrames"   
                          "DataStructures"  
                          "Dates"
                          "DiffEqFlux"
                          "DifferentialEquations"
                          "Distances"       
                          "Distributions"
                          "FFTW"
                          "FileIO"
                          "FourierTools"
                          "Graphs"
                          "Gurobi"          
                          "HDF5"            
                          "IJulia"
                          "ImageShow"
                          "IndexFunArrays"
                          "InteractiveUtils"
                          "IterativeSolvers"
                          "JuliaFormatter"
                          "Juno"            
                          "LanguageServer"
                          "LaTeXStrings"    
                          "LazySets"
                          "LightGraphs"     
                          "LinearAlgebra" 
                          "LinearMaps"      
                          "Markdown"
                          "Measures"
                          "Metaheuristics"
                          "MethodOfLines"
                          "ModelingToolkit"
                          "NDTools"
                          "NonlinearSolve"
                          "OhMyREPL"
                          "Optim"
                          "Optimization"
                          "OptimizationPolyalgorithms"
                          "OrdinaryDiffEq"
                          "Parameters"
                          "Plots"         
                          "PlotThemes"
                          "Pluto"
                          "PlutoUI"
                          "PrettyTables"
                          "Printf"
                          "PyCall"
                          "PyPlot"          
                          "Random"                                          
                          "Roots"
                          "ScikitLearn"
                          "SpecialFunctions"
                          "SQLite"
                          "StatsPlots"
                          "TestImages"
                          "TimeZones"
                          "TypedPolynomials" 
                          "UrlDownload"
                          "VegaLite"  # to make some nice plots
                          "XLSX"
                          "ZipFile"
                          */
                      # "Atom"            
                      # "Flux.Losses"
                      # "Flux"
                      # "GraphViz"
                      # "ImageMagick"
                      # "IntervalArithmetic"
                      # "JLD"             
                      # "JLD2"
                      # "MathOptInterface"
                      # "UnicodePlots"
                    ])
                    # # 
                    # bonmin
                    # cbc
                    # clp
                    # CoinMP
                    # csdp
                    # ecos
                    # glpk
                    # ipopt
                    # nlopt
                    # opensmt
                    # picosat
                    # scip
                    # z3

                    yarn
                    nodejs
                    # nodejs_23
                    vscode
                    bun
                    nest-cli
                    nodePackages.typescript
                    nodePackages."@angular/cli" # https://discourse.nixos.org/t/how-do-i-install-scoped-packages-via-nix/47343/4

                    glib

                    jetbrains.pycharm-community
                    # python39
                    # cbc
                    # z3
                    # (python311.withPackages (pyPkgs: with pyPkgs; [
                    #     numpy
                    #     deep-translator
                    #     docplex
                    #     # cbc
                    #     z3-solver
                    #   ]
                    # ))
                    jupyter
                    gfortran

                    nixpkgs-review

                    # ollama
                    pciutils

                    azure-cli
                    openjdk17

                    python311
                    # (python311.withPackages (pyPkgs: with pyPkgs; [
                    #     fastapi
                    #     pydantic
                    #     pytest
                    #     httpx
                    #   ]
                    # ))                    
                    uv
                    #(python311.withPackages (pyPkgs: with pyPkgs; [
                    #  pip
                    #  # django
                    #  djangorestframework
                    #  # djangorestframework-simplejwt
                    #  psycopg2
                    #  weasyprint

                    # django-redis
                    # django-debug-toolbar
                    # ]))
                    gtk4
                    gobject-introspection
                    pango

                    starship
                    sudo
                    which

                    # beekeeper-studio
                    dbeaver-bin
                    pgcli

                    foo-bar

                    xclip
                    xsel
                    xorg.xev

                    (writeShellApplication {
                      name = "get-rsa-keys"; # TODO: bad name?
                      runtimeInputs = with final; [ bash openssh xclip ];
                      text = ''
                        test -d ~/.ssh || mkdir -v -m 0700 ~/.ssh
                        test "$(stat -c %a ~/.ssh)" -eq 0700 || chmod -v 0700 ~/.ssh

                        echo 'Press enter when you copied the public key: ' \
                        && read -r \
                        && xclip -selection clipboard -out > ~/.ssh/id_rsa.pub \
                        && echo 'Press enter when you copied the private key: ' \
                        && read -r \
                        && xclip -selection clipboard -out > ~/.ssh/id_rsa \
                        && chmod -v 0600 ~/.ssh/id_rsa

                        ssh-keygen -F ssh.dev.azure.com > /dev/null 2>&1 \
                        || ssh-keyscan -H ssh.dev.azure.com >> ~/.ssh/known_hosts
                        ssh -T git@ssh.dev.azure.com > /dev/null 2>&1 || true
                      '';
                    })
                  ];
                  shell = pkgs.zsh;
                  # uid = 1234;
                  uid = 1000;
                  autoSubUidGidRange = true;
                };

                services.xserver.enable = true;
                services.xserver.xkb.layout = "br";
                services.displayManager.autoLogin.user = "nixuser";
                services.xserver.displayManager.sessionCommands = ''
                  exo-open \
                    --launch TerminalEmulator \
                    --zoom=-1 \
                    --geometry 100x20
                '';

                # https://nixos.org/manual/nixos/stable/#sec-xfce
                services.xserver.desktopManager.xfce.enable = true;
                services.xserver.desktopManager.xfce.enableScreensaver = false;
                services.xserver.videoDrivers = [ "qxl" ];
                services.spice-vdagentd.enable = true; # For copy/paste to work

                /*
                  To test it:
                  curl http://localhost:5000/nix-cache-info
                  nix store info --store http://localhost:5000
                */
                services.nix-serve.enable = true;

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

                    # https://github.com/360ied/my-dotfiles/blob/45c7c15dbd525a589b0eddcda3cc4dcb3215ece9/fonts-configuration.nix#L5-L301
                    # 
                    # emacsPackages.unicode-fonts
                    # (pkgs.nerdfonts.override { fonts = [ "0xproto" "DroidSansMono" ]; }) # nerdfonts
                    # assyrian
                    # iosevka-term-curly-slab
                    # maple-mono
                    # whatsapp-emoji-font
                    agave
                    aileron
                    anonymousPro
                    ark-pixel-font
                    arkpandora_ttf # Font, metrically identical to Arial and Times New Roman
                    atkinson-hyperlegible
                    aurulent-sans
                    awesome
                    bakoma_ttf
                    bqn386
                    camingo-code
                    cantarell-fonts
                    cascadia-code
                    clearlyU
                    cm_unicode
                    comfortaa
                    comic-relief
                    corefonts
                    cozette
                    dejavu_fonts
                    dina-font 
                    dosemu_fonts
                    efont-unicode
                    emacs-all-the-icons-fonts
                    emacsPackages.unicode-fonts
                    emojione
                    envypn-font
                    fantasque-sans-mono
                    fira
                    fira-code
                    fira-code-symbols
                    fira-mono
                    font-awesome
                    font-awesome_4
                    font-awesome_4
                    font-awesome_5
                    freefont_ttf
                    gentium
                    go-font
                    gohufont
                    google-fonts
                    gyre-fonts
                    hack-font
                    hackgen-font
                    hackgen-nf-font
                    hannom
                    hasklig
                    helvetica-neue-lt-std
                    hermit
                    ibm-plex
                    icu76
                    inter
                    iosevka
                    iosevka-comfy.comfy
                    iosevka-comfy.comfy-motion
                    iosevka-comfy.comfy-wide
                    iosevka-comfy.comfy-wide-motion
                    ipaexfont
                    ipafont
                    jetbrains-mono
                    joypixels
                    julia-mono
                    last-resort
                    lato
                    liberation_ttf
                    libertine
                    libre-caslon
                    lmmath
                    lmodern
                    maple-mono.NF
                    maple-mono.NF-CN # Old named as: maple-mono-SC-NF
                    maple-mono.NormalNL-TTF-AutoHint # This maple-mono font package have 44 fonts
                    material-design-icons
                    material-icons
                    meslo-lg
                    meslo-lgs-nf
                    monaspace
                    monoid
                    mononoki
                    montserrat
                    mplus-outline-fonts.githubRelease
                    mro-unicode
                    nerd-fonts.fira-code # Old named as fira-code-nerdfont
                    nerd-fonts.inconsolata # Old named as inconsolata
                    nerd-fonts.terminess-ttf # Old named as terminus-nerdfont
                    noto-fonts
                    noto-fonts-cjk-sans
                    noto-fonts-cjk-serif
                    noto-fonts-color-emoji
                    noto-fonts-emoji
                    noto-fonts-extra
                    noto-fonts-lgc-plus
                    noto-fonts-monochrome-emoji
                    oldstandard
                    open-fonts
                    openmoji-color
                    openttd-ttf
                    oxygenfonts
                    paratype-pt-sans
                    powerline
                    powerline-fonts
                    profont
                    proggyfonts
                    recursive
                    redhat-official-fonts
                    roboto
                    roboto-mono
                    roboto-slab
                    rounded-mgenplus
                    sarasa-gothic
                    scientifica
                    shabnam-fonts
                    siji
                    sketchybar-app-font
                    source-code-pro
                    source-han-mono
                    source-han-sans
                    source-han-sans-japanese
                    source-han-sans-korean
                    source-han-sans-simplified-chinese
                    source-han-sans-traditional-chinese
                    source-han-sans-vf-ttf
                    source-han-serif
                    source-han-serif-vf-ttf
                    source-sans
                    spleen
                    stix-otf
                    stix-two
                    sudo-font
                    symbola
                    tamsyn
                    tamzen
                    terminus_font
                    terminus_font_ttf
                    textfonts
                    ttf_bitstream_vera
                    ttf-indic
                    twemoji-color-font
                    twitter-color-emoji
                    ubuntu_font_family
                    ucs-fonts
                    udev-gothic
                    udev-gothic-nf
                    uiua386
                    ultimate-oldschool-pc-font-pack
                    undefined-medium
                    unicode-emoji
                    unidings
                    unifont_upper
                    unscii
                    uw-ttyp0
                    vazir-code-font
                    vazir-fonts
                    victor-mono
                    vistafonts
                    vistafonts-chs
                    wqy_microhei
                    wqy_zenhei
                    xkcd-font
                    xmoji
                    xorg.fontbitstream100dpi
                    xorg.fontbitstream75dpi
                    xorg.fontbitstreamtype1
                    xorg.xbitmaps
                    zpix-pixel-font
                  ];
                  # enableDefaultPackages = true;
                  # enableGhostscriptFonts = true;
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

                nix.extraOptions = ''
                  bash-prompt-prefix = (nix-develop:$name)\040
                  experimental-features = nix-command flakes
                  keep-build-log = true
                  keep-derivations = true
                  keep-env-derivations = true
                  keep-failed = true
                  keep-going = true
                  keep-outputs = true
                '';

                # nix.channel.enable = false;
                # nix.settings.nix-path = "nixpkgs=flake:nixpkgs";
                # nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

                # TODO: It does not work! I must be the module
                # nix.registry.nixpkgs.flake = nixpkgs;
                nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

                # but NIX_PATH is still used by many useful tools, so we set it to the same value as the one used by this flake.
                # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
                environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";
                # https://github.com/NixOS/nix/issues/9574
                nix.settings.nix-path = lib.mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";

                # nixpkgs.hostPlatform = { system = "x86_64-linux";  config = "x86_64-unknown-linux-gnu"; qemuArch = "aarch64"; };
                nixpkgs.config.allowUnfree = true;
                nixpkgs.config.allowUnfreePredicate = pkg:
                  builtins.elem (lib.getName pkg) [
                    "vscode"
                    "vagrant"

                    "assyrian"
                    "corefonts"
                    "hannom"
                    "helvetica-neue-lt-std"
                    "joypixels"
                    "symbola"
                    "textfonts"
                    "unidings"
                    "vista-fonts"
                    "xkcd-font"
                    # "whatsapp-emoji-linux"
                  ];
                nixpkgs.config.joypixels.acceptLicense = true;

                # environment.variables.STATIC_NIX = "${pkgs.lib.getExe pkgs.pkgsStatic.nixVersions.nix_2_23}";

                environment.systemPackages = with pkgs; [
                  # pipenv
                  gcc
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
              # export LD_LIBRARY_PATH="''${prev.libcanberra-gtk3}"/lib/gtk-3.0/modules

              ${final.lib.getExe final.myvm} & PID_QEMU="$!"

              export VNC_PORT=3001

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
          # nix eval --json nixpkgs#mkShell.__functionArgs
          buildInputs = [
            foo-bar
            automatic-vm
          ];

          shellHook = ''
            export TMPDIR=/tmp

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
