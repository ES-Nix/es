{
  description = "It is an nix flake example of a devShell and uses flake-utils support multiple architectures";
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a7' \
    --override-input flake-utils 'github:numtide/flake-utils/c1dfcf08411b08f6b8615f7d8971a2bfa81d5e8a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/1546c45c538633ae40b93e2d14e0bb6fd8f13347' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input home-manager 'github:nix-community/home-manager/f63d0fe9d81d36e5fc95497217a72e02b8b7bcab' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'    
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, home-manager, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        f00Bar = prev.hello;

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

        hm =
          let
            userName = "vagrant";
            homeDirectory = "/home/${userName}";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = final;
            modules = [
              ({ config, pkgs, ... }:
                {
                  home.stateVersion = "25.11";
                  home.username = "${userName}";
                  home.homeDirectory = "${homeDirectory}";

                  programs.home-manager.enable = true;

                  home.packages = with pkgs; [
                    git
                    nix
                    # path # TODO: Why it breaks??
                    zsh
                    direnv
                    starship

                    f00Bar
                    nano
                    file
                    which
                    (writeScriptBin "hms" ''
                      #! ${pkgs.runtimeShell} -e
                        nix \
                        build \
                        --no-link \
                        --print-build-logs \
                        --print-out-paths \
                        "$HOME"'/.config/home-manager#homeConfigurations.'"$(id -un)".activationPackage

                        home-manager switch --flake "$HOME/.config/home-manager"#"$(id -un)"
                    '')
                  ];

                  nix = {
                    enable = true;
                    package = pkgs.nix;
                    # package = pkgs.nixVersions.nix_2_29;
                    extraOptions = ''
                      experimental-features = nix-command flakes
                    '';
                    settings = {
                      bash-prompt-prefix = "(nix:$name)\\040";
                      keep-build-log = true;
                      keep-derivations = true;
                      keep-env-derivations = true;
                      keep-failed = true;
                      keep-going = true;
                      keep-outputs = true;
                      nix-path = "nixpkgs=flake:nixpkgs";
                      tarball-ttl = 2419200; # 60 * 60 * 24 * 7 * 4 = one month
                    };
                    registry.nixpkgs.flake = nixpkgs;
                  };

                  programs.zsh = {
                    enable = true;
                    enableCompletion = true;
                    dotDir = "${config.home.homeDirectory}";
                    autosuggestion.enable = true;
                    syntaxHighlighting.enable = true;
                    envExtra = ''
                      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
                        . ~/.nix-profile/etc/profile.d/nix.sh
                      fi
                    '';
                    shellAliases = {
                      l = "ls -alh";
                    };
                    sessionVariables = {
                      # https://discourse.nixos.org/t/what-is-the-correct-way-to-set-nix-path-with-home-manager-on-ubuntu/29736
                      NIX_PATH = "nixpkgs=${pkgs.path}";
                      LANG = "en_US.utf8";
                    };
                    oh-my-zsh = {
                      enable = true;
                      plugins = [
                        "colored-man-pages"
                        "colorize"
                        "direnv"
                        "zsh-navigation-tools"
                      ];
                      theme = "robbyrussell";
                    };
                  };
                }
              )
            ];
            extraSpecialArgs = { nixpkgs = nixpkgs; };
          };

        hmActivationPackage = final.hm.activationPackage;
      };
    } //
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs {
            overlays = [ self.overlays.default ];
            system = suportedSystem;
            config.allowUnfreePredicate = (_: true);
            config.android_sdk.accept_license = true;
            config.allowUnfree = true;
            config.cudaSupport = false;
          };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          apps = {
            allTests = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.allTests}";
              meta.description = "Run all tests";
            };
          };

          packages = {
            inherit (pkgsAllowUnfree)
              f00Bar
              hm
              hmActivationPackage
              ;
            default = pkgsAllowUnfree.hmActivationPackage;
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            packages = with pkgsAllowUnfree; [
              f00Bar
              python313
              uv
              bashInteractive
              pleaseKeepMyInputs
            ];

            shellHook = ''
              test -d .profiles || mkdir -v .profiles
              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build --impure .#devShells."$system".default --out-link .profiles/dev-shell-"$system"-default

              hello
              echo
            '';
          };

          checks = {
            inherit (pkgsAllowUnfree)
              f00Bar
              hmActivationPackage
              ;
            default = pkgsAllowUnfree.hmActivationPackage;
          };
        }
      )

    // {
      # home-manager build --flake '.#vagrant' --no-out-link --dry-run
      homeConfigurations.vagrant = self.outputs.packages.x86_64-linux.hm;
    };
}
