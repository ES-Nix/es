{
  description = "Home Manager configuration of nixuser";
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/d12251ef6e8e6a46e05689eeccd595bdbd3c9e60 \
    --override-input home-manager github:nix-community/home-manager/a631666f5ec18271e86a5cde998cba68c33d9ac6

    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
    --override-input home-manager github:nix-community/home-manager/f33900124c23c4eca5831b9b5eb32ea5894375ce

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input home-manager 'github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9'
  */
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      userName = "vagrant";
      homeDirectory = "/home/${userName}";

      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter."${system}" = pkgs.nixpkgs-fmt;
      devShells."${system}".default = pkgs.mkShell {
        buildInputs = [
        ];
        shellHook = ''
          test -d .profiles || mkdir -v .profiles
          test -L .profiles/dev \
          || nix develop .# --impure --profile .profiles/dev --command true        
        '';
      };

      packages."${system}".default = self.homeConfigurations."${userName}".activationPackage;

      homeConfigurations."${userName}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ pkgs, ... }:
            {
              home.stateVersion = "25.05";
              home.username = "${userName}";
              home.homeDirectory = "${homeDirectory}";

              programs.home-manager = {
                enable = true;
              };

              home.packages = with pkgs; [
                direnv
                git
                nix
                zsh
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
                  keep-failed = true;
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
    };
}
