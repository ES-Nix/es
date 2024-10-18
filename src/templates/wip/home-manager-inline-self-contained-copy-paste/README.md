
##


```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

curl -L https://hydra.nixos.org/build/272142581/download-by-type/file/binary-dist -o nix

chmod -v +x nix \
&& ./nix flake --version

./nix \
shell \
--ignore-environment \
--keep HOME \
--keep PATH \
--keep USER \
--extra-experimental-features auto-allocate-uids \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--max-jobs 0 \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#nix \
nixpkgs#git \
--command \
bash \
<<'COMMANDS'

./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
profile \
install \
--max-jobs 0 \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a \
nixpkgs#git \
nixpkgs#path \
nixpkgs#nix

echo \
&& echo 'export PATH="$HOME"/.nix-profile/bin:"$PATH"' >> "$HOME"/.profile \
&& echo 'export PATH="$HOME"/.nix-profile/bin:"$PATH"' >> "$HOME"/.bashrc \
&& test -d "$HOME"/.config/nix || mkdir -pv "$HOME"/.config/nix \
&& echo 'experimental-features = nix-command flakes' >> "$HOME"/.config/nix/nix.conf \
&& echo 

nix \
store \
gc \
--option keep-build-log false \
--option keep-derivations false \
--option keep-env-derivations false \
--option keep-failed false \
--option keep-going false \
--option keep-outputs true \
&& nix-collect-garbage --delete-old --verbose \
&& nix \
store \
optimise

rm -v ./nix
COMMANDS

. "$HOME"/.profile
nix flake --version
nix flake metadata nixpkgs
```



TODO: it is not pinning nixpkgs
nix flake metadata nixpkgs is trying to download unstable
```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

curl -L https://hydra.nixos.org/build/272142581/download-by-type/file/binary-dist -o nix

chmod -v +x nix \
&& ./nix flake --version

./nix \
shell \
--ignore-environment \
--keep HOME \
--keep PATH \
--keep USER \
--extra-experimental-features auto-allocate-uids \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--max-jobs 0 \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#nix \
nixpkgs#git \
--command \
bash \
<<'COMMANDS'
export NIX_CONFIG="extra-experimental-features = nix-command flakes"
nix \
--refresh \
run \
github:ES-nix/es#installStartConfigTemplate
COMMANDS

"$HOME"/.nix-profile/bin/zsh --login
```






## Bootstrap nix (the nixStatic one) instalation using nixStatic

The point in using:
- nixStatic
- pkgsStatic.busybox
- gitMinimal

all those are to be able to use the official binary cache, enforced here by `--max-jobs 0`.

```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
&& $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/252422687/download-by-type/file/binary-dist > nix \
&& chmod -v +x nix

./nix \
shell \
--ignore-environment \
--keep HOME \
--keep USER \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--max-jobs 0 \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a \
nixpkgs#pkgsStatic.busybox \
nixpkgs#nixStatic \
--command \
sh <<'COMMANDS'

export NIX_CONFIG="extra-experimental-features = nix-command flakes auto-allocate-uids"

nix \
registry \
pin \
nixpkgs github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a \
--verbose

nix \
profile \
install \
nixpkgs#gitMinimal \
nixpkgs#nixStatic \
nixpkgs#path \
--verbose

echo \
&& echo 'export PATH="$HOME"/.nix-profile/bin:"$PATH"' >> "$HOME"/.profile \
&& echo 'export PATH="$HOME"/.nix-profile/bin:"$PATH"' >> "$HOME"/.bashrc \
&& test -d "$HOME"/.config/nix || mkdir -pv "$HOME"/.config/nix \
&& echo 'experimental-features = nix-command flakes' >> "$HOME"/.config/nix/nix.conf \
&& echo 

nix \
store \
gc \
--option keep-build-log false \
--option keep-derivations false \
--option keep-env-derivations false \
--option keep-failed false \
--option keep-going false \
--option keep-outputs true \
&& nix-collect-garbage --delete-old --verbose \
&& nix \
store \
optimise

rm -v ./nix
COMMANDS

. "$HOME"/.profile
nix flake --version

export NIX_CONFIG="extra-experimental-features = nix-command flakes auto-allocate-uids"
export PATH="$HOME"/.nix-profile/bin:"$PATH"
export NIX_PATH=nixpkgs=$(nix eval --raw nixpkgs#path)
```
Refs.:
- ?


Note that this way NIX_PATH is missing.

```bash
nix run nixpkgs#nix-info
```

```bash
export NIX_PATH=nixpkgs=$(nix eval --raw nixpkgs#path)
```

```bash
nix run nixpkgs#nix-info
```

```bash
nix --option nix-path nixpkgs=flake:nixpkgs eval --impure --expr 'builtins.nixPath'
nix eval --impure --expr 'builtins.findFile builtins.nixPath "nixpkgs"'
```

TODO: is it time to change/adapt nix-info to use, somehow, nix-path?
It is just ignored. 
```bash
nix --option nix-path nixpkgs=flake:nixpkgs run nixpkgs#nix-info
```

```bash
nix-shell -p hello
```

```bash
diff \
<(nix run nixpkgs#nix-info -- --markdown) \
<(nix-shell -p nix-info --run "nix-info --markdown")
```

```bash
ls -al $(dirname $(readlink -f $(which nix)))
```

### Extras


```bash
type echo \
&& type export \
&& type mkdir \
&& type rm \
&& type tee \
&& type test \
&& type type
```


#### Comparing and investigating nix versions

```bash
nix \
eval \
--json \
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659#nixStatic.version
```

This is the "latest now" nixos-23.11:
```bash
nix \
eval \
--json \
github:NixOS/nixpkgs/90055d5e616bd943795d38808c94dbf0dd35abe8#nixStatic.version
```

```bash
nix \
eval \
--json \
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659#pkgsStatic.nixVersions.nix_2_21.version
```

```bash
nix \
eval \
--json \
github:NixOS/nixpkgs/90055d5e616bd943795d38808c94dbf0dd35abe8#pkgsStatic.nixVersions.nix_2_21.version
```

```bash
nix \
eval \
--json \
github:NixOS/nix/60824fa97c588a0faf68ea61260a47e388b0a4e5#nix-static.version
```

```bash
nix run github:NixOS/nixpkgs/90055d5e616bd943795d38808c94dbf0dd35abe8#nixStatic -- --version
nix eval --json github:NixOS/nixpkgs/90055d5e616bd943795d38808c94dbf0dd35abe8#nixStatic.version

nix \
eval \
--json \
github:NixOS/nixpkgs/90055d5e616bd943795d38808c94dbf0dd35abe8#pkgsStatic.nix.version
```

```bash
nix \
build \
github:NixOS/nix/17a598e644bd936b69c4b50358b62e73a4711d31#hydraJobs.buildStatic.x86_64-linux
```



```bash
nix \
eval \
--json \
--apply builtins.attrNames \
github:NixOS/nixpkgs/90055d5e616bd943795d38808c94dbf0dd35abe8#pkgsStatic.nixVersions
```




```bash
export NIX_CONFIG="extra-experimental-features = nix-command flakes auto-allocate-uids"
export PATH="$HOME"/.nix-profile/bin:"$PATH"
export NIX_PATH=nixpkgs=$(nix eval --raw nixpkgs#path)
```


```bash
# EXPECTED_SHA512SUM=d035655c1c91f34e81a2248b4da60e4d28204fbc9b592dba2713409fc518be45d40a7b775d5dff707a2e1f19903c8ee41a256b488c8f10f0b6ef3edee06a96c6
EXPECTED_SHA512SUM=2668fbcc755aaac21a3b2810623bba10785ed57dd3876be3639383e8464b8d8cb22441214f68df70a8f66afa2de8ea34d2f5644ac6cb3af0901814cbcaa23a50

echo "$EXPECTED_SHA512SUM"'  './nix | sha512sum -c
```

```bash
FULL_PATH_1=$(
./nix \
build \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--print-out-paths \
github:NixOS/nix/60824fa97c588a0faf68ea61260a47e388b0a4e5#nix-static
)/bin/nix

FULL_PATH_2=$(
./nix \
build \
--rebuild \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--print-out-paths \
github:NixOS/nix/60824fa97c588a0faf68ea61260a47e388b0a4e5#nix-static
)/bin/nix


EXPECTED_SHA512SUM=2668fbcc755aaac21a3b2810623bba10785ed57dd3876be3639383e8464b8d8cb22441214f68df70a8f66afa2de8ea34d2f5644ac6cb3af0901814cbcaa23a50

echo "$EXPECTED_SHA512SUM"'  '"$FULL_PATH_1" | sha512sum -c
echo "$EXPECTED_SHA512SUM"'  '"$FULL_PATH_2" | sha512sum -c
```




### How to find nix statically compilled

https://hydra.nixos.org/
=> nix
=> maintenance-2.21
=> Jobs
=> buildStatic.x86_64-linux
=> Links
=> Status


https://hydra.nixos.org/build/252422687#tabs-summary

```bash
nix \
build \
github:NixOS/nix/93e8660bba42c8c90fcc1455ebb6e8631b66d4cb#hydraJobs.buildStatic.x86_64-linux
```


#### Single user official installer + home-manager


```bash
sudo sh -c 'mkdir -pv -m 0777 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

NIX_RELEASE_VERSION=2.21.2 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh \
&& export NIX_CONFIG='extra-experimental-features = nix-command flakes' \
&& nix -vv registry pin nixpkgs github:NixOS/nixpkgs/cfd6b5fc90b15709b780a5a1619695a88505a176

nix \
run \
--no-write-lock-file \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/cfd6b5fc90b15709b780a5a1619695a88505a176 \
github:nix-community/home-manager \
-- \
init \
--switch

home-manager generations
```
Refs.:
- https://github.com/nix-community/home-manager/pull/2892


TODO: help there https://github.com/NixOS/nix/issues/10109


In the "latest form" but from nixos-24.05: 
```bash
sudo sh -c 'mkdir -pv -m 0777 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

sh <(curl -L https://nixos.org/nix/install) --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh \
&& export NIX_CONFIG='extra-experimental-features = nix-command flakes' \
&& REV="$(nix eval --impure --raw --expr '(builtins.getFlake "github:NixOS/nixpkgs/nixos-24.05").rev')" \
&& nix -vv registry pin nixpkgs github:NixOS/nixpkgs/"$REV"

nix \
run \
--no-write-lock-file \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/"$REV" \
github:nix-community/home-manager \
-- \
init \
--switch

home-manager generations
```





Only home-manager, nix, git, zsh:
```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
&& $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/237228729/download-by-type/file/binary-dist > nix \
&& chmod -v +x nix

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

./nix \
shell \
--ignore-environment \
--keep HOME \
--keep PATH \
--keep USER \
--keep NIX_CONFIG \
--extra-experimental-features auto-allocate-uids \
--max-jobs 0 \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#nix \
nixpkgs#git \
nixpkgs#home-manager \
--command \
bash \
<<'COMMANDS'

mkdir -pv ~/.config/nixpkgs && cd $_

cat > flake.nix << 'EOF'
{
  description = "Home Manager configuration of nixuser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      userName = "nixuser";
      homeDirectory = "${if pkgs.stdenv.isLinux then "/home/" else "${if pkgs.stdenv.isDarwin then "/User/" else builtins.throw "Unsuported system!"}"}" + "${userName}";

      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."${userName}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          (
            { pkgs, ... }:
            {
              home.stateVersion = "22.11";
              home.username = "${userName}";
              home.homeDirectory = "${homeDirectory}";

              home.packages = with pkgs; [
                git
                nix
                zsh
              ];

              nix = {
                enable = true;
                extraOptions = ''
                  experimental-features = nix-command flakes
                '';
              };

              programs.home-manager.enable = true;
              programs.zsh.enable = true;
            }
          )
        ];
        extraSpecialArgs = { nixpkgs = nixpkgs; };
      };
    };
}
EOF


sed -i 's/.*userName = ".*";/userName = "'"$USER"'";/' \
/home/"$USER"/.config/nixpkgs/flake.nix

git config init.defaultBranch \
|| git config --global init.defaultBranch main
git init && git add .

nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
--override-input home-manager github:nix-community/home-manager/b372d7f8d5518aaba8a4058a453957460481afbc


home-manager switch --flake .#$USER --verbose
COMMANDS

rm -v nix

export PATH="$HOME"/.nix-profile/bin:"$PATH"

home-manager generations
```



### 

home-manager, nix, git, zsh, neovim, vscodium, direnv, fonts and more

```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
&& $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/237228729/download-by-type/file/binary-dist > nix \
&& chmod -v +x nix

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
shell \
--ignore-environment \
--keep HOME \
--keep SHELL \
--keep USER \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#gnused \
nixpkgs#nix \
nixpkgs#git \
nixpkgs#home-manager \
--command \
bash \
<<'COMMANDS'

mkdir -pv ~/.config/home-manager && cd $_

cat > flake.nix << 'EOF'
{
  description = "Home Manager configuration of nixuser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      userName = "vagrant";
      homeDirectory = "${if pkgs.stdenv.isLinux then "/home/" else "${if pkgs.stdenv.isDarwin then "/User/" else builtins.throw "Unsuported system!"}"}" + "${userName}";

      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."${userName}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          (
            { pkgs, ... }:
            {
              home.stateVersion = "23.11";
              home.username = "${userName}";
              home.homeDirectory = "${homeDirectory}";

              programs.home-manager = {
                enable = true;
              };

              programs.direnv = {
                enable = true;
                nix-direnv = {
                  enable = true;
                };
                enableZshIntegration = true;
              };
            
              programs.fzf = {
                enable = true;
                enableZshIntegration = true;
              };
            
              programs.nix-index = {
                enable = true;
                enableZshIntegration = true;
              };

              programs.vscode = {
                enable = true;
                package = pkgs.vscodium;
                extensions = (with pkgs.vscode-extensions; [
                  arrterian.nix-env-selector
                  bbenoist.nix
                  brettm12345.nixfmt-vscode
                  catppuccin.catppuccin-vsc
                  jnoortheen.nix-ide
                  mkhl.direnv
                  streetsidesoftware.code-spell-checker
                ]);
                userSettings = {
                  "editor.formatOnSave" = false;
                  "workbench.colorTheme" = "Catppuccin Mocha";              
                };
                enableExtensionUpdateCheck = false;
                enableUpdateCheck = false;
              };

              programs.neovim = {
                enable = true;
                viAlias = true;
                vimAlias = true;
                vimdiffAlias = true;
              };

              home.packages = with pkgs; [
                git
                nix
                openssh # ?
                zsh
              ];

              nix = {
                enable = true;
                package = pkgs.nix;
                extraOptions = ''
                  experimental-features = nix-command flakes
                '';
                registry.nixpkgs.flake = nixpkgs;
              };

              nixpkgs = {
                config = {
                  allowUnfree = true;
                  allowUnfreePredicate = (_: true); # TODO
                };
              };

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
                  code = "codium";
                };

                sessionVariables = {
                  # https://discourse.nixos.org/t/what-is-the-correct-way-to-set-nix-path-with-home-manager-on-ubuntu/29736 
                  NIX_PATH = "nixpkgs=${pkgs.path}";                
                  EDITOR = "nvim";
                  LANG = "en_US.utf8"; # TODO: test it glibcLocalesUtf8
                  # fc-match list
                  FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
                  FONTCONFIG_PATH = "${pkgs.fontconfig.out}/etc/fonts/";
                };
                
                oh-my-zsh = {
                  enable = true;
                  plugins = [
                    "colored-man-pages"
                    "colorize"
                    "command-not-found"
                    "common-aliases"
                    "direnv"
                    "docker"
                    "docker-compose"
                    "git"
                    "git-extras"  
                    "ssh-agent"
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
EOF

sed -i 's/.*userName = ".*";/userName = "'"$USER"'";/' flake.nix

git config init.defaultBranch \
|| git config --global init.defaultBranch main
git init && git add .

#export NIX_CONFIG="extra-experimental-features = nix-command flakes"

nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
--override-input home-manager github:nix-community/home-manager/f33900124c23c4eca5831b9b5eb32ea5894375ce

git add .

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

home-manager \
switch \
-b backup \
--print-build-logs \
--verbose
COMMANDS

/home/"$USER"/.nix-profile/bin/zsh --login
```
Refs.:
- https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone
- https://discourse.nixos.org/t/bootstrapping-stand-alone-home-manager-config-with-flakes/17087/3
- https://notes.tiredofit.ca/books/linux/page/home-manager-setup
- [Nix home-manager tutorial: Declare your entire home directory](https://www.youtube.com/watch?v=FcC2dzecovw)


Permanentilly change to zsh shell.
Note: it requires sudo.
```bash
TARGET_SHELL='zsh' \
&& FULL_TARGET_SHELL=/home/"$USER"/.nix-profile/bin/"$TARGET_SHELL" \
&& echo \
&& ls -al "$FULL_TARGET_SHELL" \
&& echo \
&& echo "$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
&& echo \
&& sudo \
      usermod \
      -s \
      /home/"$USER"/.nix-profile/bin/"$TARGET_SHELL" \
      "$USER" \
&& exec /home/"$USER"/.nix-profile/bin/"$TARGET_SHELL" --login
```
