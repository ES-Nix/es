{
  description = " ";
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/d12251ef6e8e6a46e05689eeccd595bdbd3c9e60 \
    --override-input flake-utils github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, home-manager, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

    in
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        foo-bar = prev.hello;
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
            config.cudaSupport = true;
          };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));

          userName = "vagrant";
          homeDirectory = "/home/${userName}";
        in
        {

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              foo-bar
              # python312

              # bashInteractive
              pleaseKeepMyInputs
            ];

            shellHook = ''
              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build --impure .#devShells."$system".default --out-link .profiles/dev-shell-"$system"-default

              hello
            '';
          };

          homeConfigurations."${userName}" = home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsAllowUnfree;
            modules = [
              ({ pkgs, ... }:
                {
                  home.stateVersion = "24.05";
                  home.username = "${userName}";
                  home.homeDirectory = "${homeDirectory}";

                  programs.home-manager = {
                    enable = true;
                  };

                  home.packages = with pkgs; [
                    git
                    nix
                    zsh
                    foo-bar
                  ];

                  nix = {
                    enable = true;
                    package = pkgs.nix; # pkgs.nixVersions.latest
                    extraOptions = ''
                      experimental-features = nix-command flakes
                    '';
                    registry.nixpkgs.flake = nixpkgs;
                    settings = {
                      bash-prompt-prefix = "(nix:$name)\\040";
                      keep-derivations = true;
                      keep-env-derivations = true;
                      keep-failed = false;
                      keep-going = true;
                      keep-outputs = true;
                      nix-path = "nixpkgs=flake:nixpkgs";
                      tarball-ttl = 2419200; # 60 * 60 * 24 * 7 * 4 = one month
                    };
                  };

                  programs.zsh = {
                    enable = true;
                    enableCompletion = true;
                    dotDir = ".config/zsh";
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
                      # NIX_PATH = "nixpkgs=${pkgs.path}";
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

        }
      )

    // {
      #
    };
}
