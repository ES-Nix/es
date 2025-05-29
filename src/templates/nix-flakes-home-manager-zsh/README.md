# This is a nix (with flakes) template


You need:
- the `/nix` and its subfolders with custom permissions;
- a way to download the nix statically compiled;
- sudo
- sh
- chmod
- the `$USER` environment variable set


Goal: bootstrap a development environment and configuring 
a nix instalation declarativelly using home-manager with only 
nix statically compilled. 


```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
&& $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/237228729/download-by-type/file/binary-dist > nix \
&& chmod -v +x nix

export NIX_CONFIG="extra-experimental-features = auto-allocate-uids"

./nix \
run \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--refresh \
--override-input \
nixpkgs \
github:NixOS/nixpkgs/7848cd8c982f7740edf76ddb3b43d234cb80fc4d \
--no-update-lock-file \
--no-write-lock-file \
github:ES-Nix/es#installTemplateNixFlakesHomeManagerZsh
```
Refs.:
- https://nix-community.github.io/home-manager/#sec-install-standalone
- https://nixos.wiki/wiki/VSCodium
- https://discourse.nixos.org/t/bootstrapping-stand-alone-home-manager-config-with-flakes/17087/3
- [Manage Your Dotfiles with Home Manager!](https://www.youtube.com/embed/IiyBeR-Guqw?start=422&end=452&version=3), start=422&end=452


Reflection: even nix is a program so, it has many 
flavored ways to be configured and of course tunned for 
probably multiple different and probably conflicting goals. 
Two cases/examples/flavors:
a remote builder, a developer machine.

```bash
nix show-config | grep keep
```

```bash
man nix.conf
```

```bash
man home-manager
man home-configuration.nix
```

```bash
man nix3
```

For the developer it may set it like:
```bash
keep-env-derivations = true
```

This way, unless overriden in the CLI, calling it would not
garbage colect store files that are necessary to `nix develop`. 


For the remote builder it may set it like:
```bash
keep-env-derivations = false
```

In a builder keep too much may add up really fast, so 
probably delete as much as possible is a good thing.

Related:
- https://discourse.nixos.org/t/collect-garbage-but-keep-build-inputs/11713/3
- https://github.com/NixOS/nix/issues/2208#issuecomment-1173751469
- https://github.com/NixOS/nix/issues/2208#issuecomment-1357969473
- https://discourse.nixos.org/t/nix-collect-garbage-during-builds/33863/3
- https://github.com/NixOS/nix/issues/3995#issuecomment-1376342823
- https://www.reddit.com/r/NixOS/comments/17c0r68/how_to_keep_develop_shell_from_gc_nonnixos/

For investigating:
```bash
nix eval --impure '.#homeConfigurations.vagrant.activationPackage'
nix eval --impure '.#homeConfigurations.vagrant.activation-script'
```


```bash
nix \
--option keep-failed false \
develop \
nixpkgs#hello \
--command \
sh \
-c \
'cd "$TMPDIR" && touch foo-bar.txt && pwd && exit 1'
```



TODO: 
Why the warning still printed? Is it broken/ignoring the flag?
https://github.com/NixOS/nix/issues/8911#issuecomment-1902054692
```bash
nix \
run \
--override-input \
nixpkgs \
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
--no-update-lock-file \
--no-write-lock-file \
home-manager \
-- \
--version
```

TODO: it is broken! 
https://github.com/nix-community/nixd/blob/main/nixd/docs/editors/editors.md#vscodium

```bash
error: Trying to retrieve system-dependent attributes for input nixpkgs, but this input is not a flake. Perhaps flake = false was added to the input declarations by mistake, or you meant to use a different input, or you meant to use plain old inputs, not inputs'.
(use '--show-trace' to show detailed location information)
```

```bash
rm -frv \
~/.config/home-manager \
~/.cache \
~/.nix-profile \
~/.zshenv \
~/.nix-defexpr

sudo rm -frv /nix
```

```nix
config = {
  allowUnfree = true;
  allowUnfreePredicate = (_: true);
};
```

TODO:
https://github.com/nix-community/nix-index-database?tab=readme-ov-file#usage-in-home-manager
https://ipetkov.dev/blog/tips-and-tricks-for-nix-flakes/
https://github.com/nix-community/NUR/issues/485#issuecomment-1858815728

It is an joke, April 1. [Top 6 Best NixOS Tips & Tricks](https://www.youtube.com/embed/cH9HGs2AxuA?start=120&end=164&version=3), start=120&end=164


```nix
      homeDirectory = "${if pkgsConfigured.stdenvNoCC.isLinux then
                           "/home/"
                         else "${if pkgsConfigured.stdenvNoCC.isDarwin then
                           "/User/"
                         else
                           builtins.throw "Unsuported system!"}"}" + "${userName
                       }";

            #  programs.direnv = {
            #    enable = true;
            #    nix-direnv = {
            #      enable = true;
            #    };
            #    enableZshIntegration = true;
            #  };
            #
            #  programs.fzf = {
            #    enable = true;
            #    enableZshIntegration = true;
            #  };
            #
            #  programs.nix-index = {
            #    enable = true;
            #    enableZshIntegration = true;
            #  };
            #
            #  programs.vscode = {
            #    enable = true;
            #    package = pkgs.vscodium;
            #    extensions = (with pkgs.vscode-extensions; [
            #      arrterian.nix-env-selector
            #      bbenoist.nix
            #      brettm12345.nixfmt-vscode
            #      catppuccin.catppuccin-vsc
            #      jnoortheen.nix-ide
            #      mkhl.direnv
            #      streetsidesoftware.code-spell-checker
            #    ]);
            #    userSettings = {
            #      "editor.formatOnSave" = false;
            #      "workbench.colorTheme" = "Catppuccin Mocha";
            #    };
            #    enableExtensionUpdateCheck = false;
            #    enableUpdateCheck = false;
            #  };
            #
            #  programs.neovim = {
            #    enable = true;
            #    viAlias = true;
            #    vimAlias = true;
            #    vimdiffAlias = true;
            #  };
```

```bash
nix eval "$HOME"/.config/home-manager#homeConfigurations.vagrant.config.nixpkgs.config.allowUnfree
export NIXPKGS_ALLOW_UNFREE=1; nix run --impure nixpkgs#unrar
```

```nix
{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    homeConfigurations = {
      "vagrant" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};

        modules = [
          (
          # This is your home-manager configuration file
          # Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
          {
            inputs,
            lib,
            config,
            pkgs,
            ...
          }: {
            # You can import other home-manager modules here
            imports = [
              # If you want to use home-manager modules from other flakes (such as nix-colors):
              # inputs.nix-colors.homeManagerModule
          
              # You can also split up your configuration and import pieces of it here:
              # ./nvim.nix
            ];
          
            nixpkgs = {
              overlays = [ ];
              config = {
                allowUnfree = true;
                allowUnfreePredicate = _: true;
              };
            };
          
            nix = {
              enable = true;
              package = pkgs.nixStatic;
              extraOptions = ''
                experimental-features = nix-command flakes
              '';
              registry.nixpkgs.flake = inputs.nixpkgs;
            };

            home = {
              username = "vagrant";
              homeDirectory = "/home/vagrant";
            };

            programs.home-manager.enable = true;

            home.packages = with pkgs; [
              git
              nix
              zsh
            ];

            programs.zsh = {
              enable = true;
              enableCompletion = true;
              dotDir = ".config/zsh";
              enableAutosuggestions = true;
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
                NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
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
          
            # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
            home.stateVersion = "23.11";
          })
        ];
      };
    };
  };
}

nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
--override-input home-manager github:nix-community/home-manager/f33900124c23c4eca5831b9b5eb32ea5894375ce
```
