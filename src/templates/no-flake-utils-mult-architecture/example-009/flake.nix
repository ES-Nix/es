{
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334 \
    --override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, home-manager, ... }:
    let
      overlays.default = final: prev: {
        f00Bar = prev.hello;
        homeManagerVagrant = (home-manager.lib.homeManagerConfiguration {
          # inherit pkgs;
          pkgs = final;
          modules = [
            ({ pkgs, ... }:
              {
                home.stateVersion = "25.05";
                home.username = "vagrant";
                home.homeDirectory = "/home/vagrant";

                programs.home-manager = {
                  enable = true;
                };

                home.packages = with pkgs; [
                  git
                  nix
                  zsh

                  hello
                  nano
                  file
                  which
                  f00Bar
                  (writeScriptBin "hms" ''
                    #! ${final.runtimeShell} -e
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
                  registry.nixpkgs.flake = nixpkgs;
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
                    NIX_PATH = "nixpkgs=${final.path}";
                    LANG = "en_US.utf8";
                  };
                  oh-my-zsh = {
                    enable = true;
                    plugins = [
                      "colored-man-pages"
                      "colorize"
                      # "direnv"
                      "zsh-navigation-tools"
                    ];
                    theme = "robbyrussell";
                  };
                };
              }
            )
          ];
          extraSpecialArgs = { nixpkgs = nixpkgs; };

        }).activationPackage;
      };

      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ]
          (system:
            function (import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [
                # inputs.something.overlays.default
                overlays.default
              ];
            }));

    in
    {
      packages = forAllSystems (pkgs: {
        inherit (pkgs)
          f00Bar
          ;
        default = pkgs.homeManagerVagrant;
      });

      checks = forAllSystems (pkgs: {
        inherit (pkgs)
          f00Bar
          homeManagerVagrant
          ;
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);

      homeConfigurations = forAllSystems (pkgs: pkgs.homeManagerVagrant);
    };
}
