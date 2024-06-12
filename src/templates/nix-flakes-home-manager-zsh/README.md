# This is a nix (with flakes) template


You need:
- the `/nix` and its subfolders with custom permissions;
- a way to download the nix statically compiled;
- sudo
- sh
- chmod
- the `$USER` environment variable set



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
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
--no-update-lock-file \
--no-write-lock-file \
github:ES-Nix/es#installTemplateNixFlakesHomeManagerZsh
```
Refs.:
- https://nix-community.github.io/home-manager/#sec-install-standalone
- https://nixos.wiki/wiki/VSCodium
- https://discourse.nixos.org/t/bootstrapping-stand-alone-home-manager-config-with-flakes/17087/3
- [Manage Your Dotfiles with Home Manager!](https://www.youtube.com/embed/IiyBeR-Guqw?start=422&end=452&version=3), start=422&end=452


Reflection: even nix is a program so, it have many 
flavored ways to be configured and ofcourse tunned for 
 probably multiple different and probably conflicting goals. Two cases/examples/flavors:
a remote builder, a developer machine.

```bash
nix show-config | grep keep
```

```bash
man nix.conf
```


For the developer it may set it like:
```bash
keep-env-derivations = true
```

This way, unless overriden in the CLI call it would not 
garbage colect store files that would be necessary to develop 


For the remote builder it may set it like:
```bash
keep-env-derivations = false
```

In a builder keep too much may add up really fast, so 
probably delete as much as possible is a good thing.




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

```bash
nix eval "$HOME"/.config/home-manager#homeConfigurations.vagrant.config.nixpkgs.config.allowUnfree
export NIXPKGS_ALLOW_UNFREE=1; nix run --impure nixpkgs#unrar
```

```bash
{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # Home manager
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
              gitMinimal
              nixStatic
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



Used to test it:
```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/alpine:3.19.1 as alpine-with-ca-certificates-tzdata

# https://stackoverflow.com/a/69918107
# https://serverfault.com/a/1133538
# https://wiki.alpinelinux.org/wiki/Setting_the_timezone
# https://bobcares.com/blog/change-time-in-docker-container/
# https://github.com/containers/podman/issues/9450#issuecomment-783597549
# https://www.redhat.com/sysadmin/tick-tock-container-time
ENV TZ=America/Recife

RUN apk update \
 && apk \
        add \
        --no-cache \
        ca-certificates \
        tzdata \
        shadow \
 && mkdir -pv /home/nixuser \
 && addgroup nixgroup --gid 4455 \
 && adduser \
        -g '"An unprivileged user with an group"' \
        -D \
        -h /home/nixuser \
        -G nixgroup \
        -u 3322 \
        nixuser \
 && echo \
 && echo 'Start kvm stuff...' \
 && getent group kvm || groupadd kvm \
 && usermod --append --groups kvm nixuser \
 && echo 'End kvm stuff!' \
 && echo 'Start tzdata stuff' \
 && (test -d /etc || mkdir -pv /etc) \
 && cp -v /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && apk del tzdata shadow \
 && echo 'End tzdata stuff!' 

# sudo sh -c 'mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'
RUN mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv nixuser:nixgroup /nix

USER nixuser
WORKDIR /home/nixuser
ENV USER="nixuser"

RUN CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
 && $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/237228729/download/2/nix > nix \
 && chmod -v +x nix \
 && echo \
 && export NO_EXEC=1 \
 && ./nix \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    --extra-experimental-features auto-allocate-uids \
    --option auto-allocate-uids false \    
    run \
    --override-flake \
    nixpkgs \
    github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
    --refresh \
    github:ES-Nix/es#installTemplateNixFlakesHomeManagerZsh \
 && echo
 
ENTRYPOINT [ "/home/nixuser/.nix-profile/bin/zsh" ]
CMD [ "--login" ]

EOF


podman \
build \
--cap-add=SYS_ADMIN \
--tag alpine-with-ca-certificates-tzdata \
--target alpine-with-ca-certificates-tzdata \
. \
&& podman kill container-alpine-with-ca-certificates-tzdata &> /dev/null || true \
&& podman rm --force container-alpine-with-ca-certificates-tzdata || true \
&& echo

xhost + || nix run nixpkgs#xorg.xhost -- +
podman \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--device /dev/dri:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--security-opt seccomp=unconfined \
--shm-size=2G \
--tty=true \
--rm=true \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume=/etc/localtime:/etc/localtime:ro \
localhost/alpine-with-ca-certificates-tzdata:latest
```
Refs.:
- 
