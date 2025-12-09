# Bootstraping with nix statically compiled


## Are you able to either: login as root or use sudo/doas?

```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'
```

##

For x86_64-linux:
```bash
# BUILD_ID="$(
# hydra-check \
# --arch x86_64-linux \
# --channel nix maintenance-2.32/buildStatic.nix-cli \
# --json \
# | jq -r '."maintenance-2.32/buildStatic.nix-cli.x86_64-linux".[0].build_id'
# )"
# echo $BUILD_ID

BUILD_ID=313290523
curl -L https://hydra.nixos.org/build/$BUILD_ID/download-by-type/file/binary-dist > nix \
&& echo e95f16f84987096586abe959c80bb910d26a7fa7707c42802400be999b6ad5ab'  'nix \
| sha256sum -c \
&& chmod +x nix \
&& ./nix --version
```
Refs.:
- https://hydra.nixos.org/build/311316992
- https://hydra.nixos.org/build/313290523


For aarch64-linux:
```bash
# BUILD_ID="$(
# hydra-check \
# --arch aarch64-linux \
# --channel nix maintenance-2.32/buildStatic.nix-cli \
# --json \
# | jq -r '."maintenance-2.32/buildStatic.nix-cli.aarch64-linux".[0].build_id'
# )"
# echo $BUILD_ID

BUILD_ID=312837149
curl -L https://hydra.nixos.org/build/$BUILD_ID/download-by-type/file/binary-dist > nix \
&& echo 8fda1192c5f93415206b7028c4afe694611d1a5525bfcb5f3f2d57cc87df0d56'  'nix \
| sha256sum -c \
&& chmod +x nix \
&& ./nix --version
```
Refs.:
- https://hydra.nixos.org/build/311250514
- https://hydra.nixos.org/build/312837149


2)
```bash
export NIX_CONFIG="extra-experimental-features = nix-command flakes auto-allocate-uids"
export PATH="$HOME"/.nix-profile/bin:"$PATH"
export NIX_PATH=nixpkgs=$(./nix eval --raw github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd#path)
```

### 

TODO: why it lacks behind, it is now pointing to 2.25 but it must be 2.26.
look into discourse
```bash
curl -L https://hydra.nixos.org/job/nix/master/buildStatic.nix.x86_64-linux/latest/download-by-type/file/binary-dist > nix \
&& chmod +x nix \
&& ./nix --version
```


```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'
```



TODO: maintenance-2.26 is broken?

https://github.com/NixOS/nix/issues/9176

check this in browser:

https://hydra.nixos.org/job/nix/maintenance-2.25/buildStatic.nix.x86_64-linux

https://hydra.nixos.org/job/nix/master/buildStatic.nix.x86_64-linux/latest/

https://hydra.nixos.org/job/nix/maintenance-2.26/buildStatic.nix-cli.x86_64-linux/latest-finished
https://hydra.nixos.org/job/nix/maintenance-2.27/buildStatic.nix-cli.x86_64-linux/latest-finished
https://hydra.nixos.org/job/nix/maintenance-2.28/buildStatic.nix-cli.x86_64-linux/latest-finished
https://hydra.nixos.org/job/nix/maintenance-2.29/buildStatic.nix-cli.x86_64-linux/latest-finished




```bash
ldd "$(nix build --no-link --print-build-logs --print-out-paths 'github:NixOS/nix/9cb662d#nix-cli-static')"/bin/nix
```
Refs.:
- https://github.com/NixOS/nix/releases/tag/2.27.1


https://hydra.nixos.org/job/nix/master/buildStatic.nix-cli.x86_64-linux/latest/

the previus link redirects to this link (latest success build):
https://hydra.nixos.org/build/278148689

This, as of now, is this build:

https://hydra.nixos.org/job/nix/maintenance-2.25/buildStatic.nix.x86_64-linux/latest


This must be success for all (even for other archtectures), right?
```bash
nix \
shell \
--ignore-environment \
nixpkgs#bashInteractive \
nixpkgs#hydra-check \
--command \
bash \
<<'COMMAND'
# hydra-check --arch x86_64-linux --channel nixos/release-24.05 nixStatic
# hydra-check --arch x86_64-linux --channel nixos/release-24.11 nixStatic
hydra-check --arch x86_64-linux --channel nixos/release-25.05 nixStatic
hydra-check --arch x86_64-linux --channel master nixStatic
hydra-check --arch x86_64-linux --channel unstable nixStatic

# hydra-check --arch aarch64-linux --channel nixos/release-24.05 nixStatic
# hydra-check --arch aarch64-linux --channel nixos/release-24.11 nixStatic
hydra-check --arch aarch64-linux --channel nixos/release-25.05 nixStatic
hydra-check --arch aarch64-linux --channel master nixStatic
hydra-check --arch aarch64-linux --channel unstable nixStatic
COMMAND
```

```bash
curl -L https://hydra.nixos.org/job/nix/maintenance-2.25/buildStatic.nix.x86_64-linux/latest/download-by-type/file/binary-dist -o nix \
&& chmod +x nix \
&& ./nix --version
```
Refs.:
- https://github.com/NixOS/nix/issues/8144
- https://github.com/containerbase/base/pull/3066/files#diff-92a562189b79bf0b6bfe28cc697d5726955290aa94518b9bcae956c3b1a8bc32R360
- https://discourse.nixos.org/t/building-a-statically-linked-nix-for-hpc-environments/10865/16
- TODO: https://discourse.nixos.org/t/where-can-i-get-a-statically-built-nix/34253/15
- TODO: help in there https://github.com/NixOS/nix/issues/9176



```bash
nix \
store \
ls \
--store https://cache.nixos.org/ \
--long \
"$(nix eval nixpkgs/107d5ef05c0b1119749e381451389eded30fb0d5#nixStatic)"
```

```bash
nix \
store \
ls \
--store https://cache.nixos.org/ \
--long \
"$(nix eval 'github:NixOS/nix/5df19752460b5e750e47d82bf93f918ba6c4dde5?narHash=sha256-kLtQhp3rCpbBYXkGvWNJvGKEcD5f0YWvWh9HZEYNA50%3D#hydraJobs.buildStatic.nix-cmd.x86_64-linux')"
```

TODO: https://github.com/NixOS/nix/issues/5509
```bash
nix \
store \
ls \
--store https://cache.nixos.org/ \
--eval-store auto \
--long \
--recursive \
"$(nix eval --raw nixpkgs#nixStatic)"
```


```bash
nix \
store \
ls \
--store https://cache.nixos.org/ \
--long \
--recursive \
"$(nix eval --raw 'github:NixOS/nix/fa4bd39c6a4017d7ad6451002ff4bf12999417a3?narHash=sha256-JaJ2dtt2G2eO/zR/4kgYBVcjjWRDy9YeRSfK%2BQxaFno%3D#hydraJobs.buildStatic.nix.x86_64-linux')"'/bin'

nix \
store \
ls \
--store https://cache.nixos.org/ \
--long \
--recursive \
"$(nix eval --raw 'github:NixOS/nix/fa4bd39c6a4017d7ad6451002ff4bf12999417a3?narHash=sha256-JaJ2dtt2G2eO/zR/4kgYBVcjjWRDy9YeRSfK%2BQxaFno%3D#hydraJobs.buildStatic.nix.aarch64-linux')"'/bin'
```
Refs.:
- https://hydra.nixos.org/build/278148846
- https://hydra.nixos.org/build/278148689
- https://hydra.nixos.org/job/nix/master/buildStatic.nix.x86_64-linux#tabs-links
- https://hydra.nixos.org/job/nix/master/buildStatic.nix.aarch64-linux#tabs-links
- 
- https://hydra.nixos.org/job/nixpkgs/trunk/nixStatic.x86_64-linux#tabs-links
- https://hydra.nixos.org/job/nixpkgs/trunk/nixStatic.aarch64-linux#tabs-links
- 
- https://hydra.nixos.org/job/nix/master/buildStatic.nix-cmd.x86_64-linux#tabs-links
- https://hydra.nixos.org/job/nix/master/buildStatic.nix-cmd.aarch64-linux#tabs-links
- 
- https://hydra.nixos.org/job/nix/master/buildStatic.nix.x86_64-linux#tabs-links
- https://hydra.nixos.org/job/nix/master/buildStatic.nix.aarch64-linux#tabs-links


```bash
nix \
path-info \
--eval-store auto \
--closure-size \
--human-readable \
--json \
--store https://cache.nixos.org \
'github:NixOS/nix/fa4bd39c6a4017d7ad6451002ff4bf12999417a3?narHash=sha256-JaJ2dtt2G2eO/zR/4kgYBVcjjWRDy9YeRSfK%2BQxaFno%3D#hydraJobs.buildStatic.nix.x86_64-linux' \
| jq -r '.[].url | split("/") | .[1] | split(".")[0]'

nix \
path-info \
--eval-store auto \
--closure-size \
--human-readable \
--json \
--store https://cache.nixos.org \
'github:NixOS/nix/83ec81789a0fe93ea8072651c6bf121dec12da13?narHash=sha256-FPHZ/vhb/eubcEzw3vMiVeif67moCI%2BrbnpNzz9%2BRvY%3D#hydraJobs.buildStatic.nix-cmd.aarch64-linux' \
| jq -r '.[].url | split("/") | .[1] | split(".")[0]'
```


```bash
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
gitlab:abstract-binary/nix-nar-rs/c8d9250b9be837abafa0046cb9c2a852b846da6a#static-x86_64-linux
```


```bash
NAR_HASH='0qm7zfi163sw36880gfbfdpk9d6j48ms0g8i1cwz6db8lqary96a'
curl \
https://cache.nixos.org/nar/"$NAR_HASH".nar.xz \
--output nix.nar.xz
```



### 


```bash
hydra-check \
--arch x86_64-linux \
--channel nix maintenance-2.28/buildStatic.nix-cli \
--json \
| jq -r '."maintenance-2.28/buildStatic.nix-cli.x86_64-linux".[0].build_id'

hydra-check \
--arch aarch64-linux \
--channel nix maintenance-2.28/buildStatic.nix-cli \
--json \
| jq -r '."maintenance-2.28/buildStatic.nix-cli.aarch64-linux".[0].build_id'
```

```bash
hydra-check \
--arch x86_64-darwin \
--channel nix maintenance-2.28/buildStatic.nix-cli \
--json \
| jq -r '."maintenance-2.28/buildStatic.nix-cli.x86_64-darwin".[0].build_id'

hydra-check \
--arch aarch64-darwin \
--channel nix maintenance-2.28/buildStatic.nix-cli \
--json \
| jq -r '."maintenance-2.28/buildStatic.nix-cli.aarch64-darwin".[0].build_id'
```


```bash
nix build --no-link --print-build-logs --print-out-paths nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.nix

nix build --no-link --print-build-logs --print-out-paths nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.nix

nix build --no-link --print-build-logs --print-out-paths nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.nix

nix build --no-link --print-build-logs --print-out-paths nixpkgs#pkgsCross.pkgsCross.aarch64-darwin.pkgsStatic.nix
```

TODO: why and how those are/were cached?
```bash
cp "$(
nix \
build \
--max-jobs 0 \
--no-link \
--print-out-paths \
--system x86_64-linux \
'github:NixOS/nix/fa4bd39c6a4017d7ad6451002ff4bf12999417a3?narHash=sha256-JaJ2dtt2G2eO/zR/4kgYBVcjjWRDy9YeRSfK%2BQxaFno%3D#hydraJobs.buildStatic.nix.x86_64-linux'
)"/bin/nix \
nix-x86_64-linux

cp "$(
nix \
build \
--max-jobs 0 \
--no-link \
--print-build-logs \
--print-out-paths \
--system aarch64-linux \
'github:NixOS/nix/fa4bd39c6a4017d7ad6451002ff4bf12999417a3?narHash=sha256-JaJ2dtt2G2eO/zR/4kgYBVcjjWRDy9YeRSfK%2BQxaFno%3D#hydraJobs.buildStatic.nix.aarch64-linux'
)"/bin/nix \
nix-aarch64-linux

cp "$(
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--system x86_64-darwin \
nixpkgs#nixStatic.outPath 
)"/bin/nix \
nix-x86_64-darwin

cp "$(
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--system aarch64-darwin \
nixpkgs#nixStatic.outPath
)"/bin/nix \
nix-aarch64-darwin
```

```bash
file nix-*
file -i nix-*
```

```bash
curl https://cache.nixos.org/spy13ngvs1fyj82jw2w3nwczmdgcp3ck.narinfo

curl https://cache.nixos.org/sq6lbk5j7vbh4brgysycwzqm5rn4y1l3.narinfo \
| grep 'URL: ' \
| cut -d '/' -f2 \
| cut -d '.' -f1
```

```bash
curl https://cache.nixos.org/nar/039kj1af32jm43qd78yvizdbjg7clj0iqwaxyb3jgxfjgv16dcsn.nar.xz \
-o nix.nar.xz \
&& xz -d nix.nar.xz
```


Broken!
```bash
nix \
--option allowed-impure-host-deps \
'/bin/sh /usr/lib/libSystem.B.dylib /usr/lib/system/libunc.dylib /dev/zero /dev/random /dev/urandom' \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--system aarch64-darwin \
nixpkgs#nixStatic
```


### latest nix static from hydra + home-manager

Note: it really is bare bones, few tools, but in cli sense it is long/cursed.
```bash
curl -L https://hydra.nixos.org/job/nix/master/buildStatic.nix.x86_64-linux/latest/download-by-type/file/binary-dist > nix \
&& chmod +x nix \
&& ./nix --version

./nix \
--option sandbox true \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
shell \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334 \
nixpkgs#bashInteractive \
nixpkgs#home-manager \
nixpkgs#nix \
--command \
bash \
-c \
'
export NIX_CONFIG="extra-experimental-features = nix-command flakes auto-allocate-uids"
export PATH="$HOME"/.nix-profile/bin:"$PATH"
export NIX_PATH=nixpkgs=$(./nix eval --raw github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334#path)

home-manager init \
&& cd /home/"$USER"/.config/home-manager/ \
&& nix \
--option sandbox false \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--option warn-dirty false \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334 \
--override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9 \
&& home-manager init --switch \
&& home-manager generations
'
```


```bash
nix \
shell \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334 \
nixpkgs#bashInteractive \
nixpkgs#home-manager \
nixpkgs#nix \
--command \
bash \
-c \
'
home-manager init \
&& cd /home/"$USER"/.config/home-manager/ \
&& nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334 \
--override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9 \
&& home-manager init --switch \
&& home-manager generations
'

home-manager switch
home-manager switch --flake '.#'"$USER"
```

### nix static from hydra + home-manager + nix + zsh

More involving example:
```bash
BUILD_ID=297111184
curl -L https://hydra.nixos.org/build/$BUILD_ID/download-by-type/file/binary-dist > nix \
&& (echo 7838348c0e560855921cfa97051161bd63e29ee7ef4111eedc77228e91772958'  'nix \
| sha256sum -c) \
&& chmod +x nix \
&& ./nix --version \
&& ./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
shell \
--ignore-environment \
--keep HOME \
--keep SHELL \
--keep USER \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#file \
nixpkgs#gnused \
nixpkgs#nix \
nixpkgs#gitMinimal \
nixpkgs#home-manager \
--command \
bash \
<<'COMMANDS'
# set -x

OLD_PWD=$(pwd)

# ! test -z "$USER" || exit 1
# id "$USER" &>/dev/null || exit 1

mkdir -pv /home/"$USER"/.config/home-manager && cd $_

cat << 'EOF' > flake.nix
{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      userName = "vagrant";
      homeDirectory = "/home/${userName}";

      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # overlays.default = nixpkgs.lib.composeManyExtensions [
      #   (final: prev: {
      #     fooBar = prev.hello;
      #   })];

      # pkgs = import nixpkgs {
      #           inherit system;
      #           overlays = [ self.overlays.default ];
      #         };            
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      homeConfigurations."${userName}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ pkgs, ... }:
            {
              home.stateVersion = "25.05";
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

                hello
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
    };
}
EOF

test -f /home/"$USER"/.config/home-manager/flake.nix || echo 'not found flake.nix'

sed -i 's/.*userName = ".*";/userName = "'"$USER"'";/' /home/"$USER"/.config/home-manager/flake.nix

git config init.defaultBranch \
|| git config --global init.defaultBranch main

git init \
&& git add .

"$OLD_PWD"/nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--option warn-dirty false \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd \
--override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9

# Even removing all packages it still making home-manager break, why?
"$OLD_PWD"/nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--option warn-dirty false \
profile \
remove \
'.*'

# It looks like the symbolic link breaks home-manager, why?
ls -ahl "$HOME"/.local/state/nix/profiles/profile || true
file "$HOME"/.local/state/nix/profiles || true
test -d "$HOME"/.local/state/nix/profiles && rm -frv "$HOME"/.local/state/nix/profiles

git add .

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

home-manager \
switch \
-b backup \
--print-build-logs \
--option warn-dirty false

/home/"$USER"/.nix-profile/bin/zsh \
-lc 'nix flake --version' \
|| echo 'The instalation may have failed!'

test -L /home/"$USER"/.nix-profile/bin/zsh \
&& "$OLD_PWD"/nix \
store \
gc \
--option keep-build-log false \
--option keep-derivations false \
--option keep-env-derivations false \
--option keep-failed false \
--option keep-going false \
--option keep-outputs true \
&& "$OLD_PWD"/nix \
store \
optimise

# test -L /home/"$USER"/.nix-profile/bin/zsh \
# && test -f "$OLD_PWD"/nix && rm -v "$OLD_PWD"/nix

# For some reason in the first execution it fails
# needing re loging, but this workaround allows a
# way better first developer experience.
/home/"$USER"/.nix-profile/bin/zsh \
-lc 'home-manager switch 1> /dev/null 2> /dev/null' 2> /dev/null || true
COMMANDS

./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--no-use-registries \
shell \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd#bashInteractive \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd#home-manager \
--command \
bash \
-c \
'
/home/"$USER"/.nix-profile/bin/zsh \
-cl \
"
nix --version \
&& nix flake --version \
&& home-manager --version \
&& hello \
&& home-manager switch
"
'
```

In the exec format:
TODO: add it as an script with some simple name to be add in some .bashrc and/or .profile for start up and/or login.
```bash
cat >> "$HOME"/.profile << 'EOF'
./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--no-use-registries \
shell \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd#bashInteractive \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd#home-manager \
--command \
bash \
-c \
'exec "$HOME"/.nix-profile/bin/zsh --login'
EOF
```


```bash
warning: '/nix/var/nix' does not exist, so Nix will use '/home/vagrant/.local/share/nix/root' as a chroot store
```

```bash
ls -alh ~/.config/home-manager/
cat ~/.config/home-manager/home.nix
nano ~/.config/home-manager/home.nix
```


It is broken. Only works inside chroot/nix shell:
```bash
/home/"$USER"/.nix-profile/bin/zsh -cl "nix --version"
```





```bash
rm -rfv "$HOME"/{.local/state,.nix-channels,.nix-defexpr,.nix-profile,.config/nixpkgs,.cache/nix}
```






TODO: help in there
https://github.com/nix-community/home-manager/issues/3752#issuecomment-2061051384


### home-manager.lib.hm.dag.entryAfter


For x86_64-linux:
```bash
# BUILD_ID="$(
# hydra-check \
# --arch x86_64-linux \
# --channel nix maintenance-2.28/buildStatic.nix-cli \
# --json \
# | jq -r '."maintenance-2.28/buildStatic.nix-cli.x86_64-linux".[0].build_id'
# )"
BUILD_ID=297111184
# echo $BUILD_ID

curl -L https://hydra.nixos.org/build/$BUILD_ID/download-by-type/file/binary-dist > nix \
&& echo 7838348c0e560855921cfa97051161bd63e29ee7ef4111eedc77228e91772958'  'nix \
| sha256sum -c \
&& chmod +x nix \
&& ./nix --version

# curl -L https://hydra.nixos.org/build/297111184/download-by-type/file/binary-dist > nix \
# && chmod +x nix \
# && ./nix --version
```
Refs.:
- https://hydra.nixos.org/build/297111184


```nix
home.activation = {
  startPythonHttpServer = home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    "${lib.getExe pkgs.python3}" -m http.server 6789 >&2 &
  '';
};
```



### Helper to test


```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/alpine:3.20.3

RUN apk update \
 && apk \
      add \
      --no-cache \
      ca-certificates \
      curl \
      shadow \
 && mkdir -pv -m 0700 /home/abcuser \
 && addgroup abcgroup --gid 4455 \
 && adduser \
      -g '"An unprivileged user with an group"' \
      -D \
      -h /home/abcuser \
      -G abcgroup \
      -u 3322 \
      abcuser \
 && echo \
 && apk del shadow

# If it is uncommented nix profile works!
RUN mkdir -pv -m 1735 /nix/var/nix && chown -Rv abcuser:abcgroup /nix

ENV PATH=/home/abcuser/.nix-profile/bin:/home/abcuser/.local/bin:"$PATH"

USER abcuser
WORKDIR /home/abcuser
ENV USER="abcuser"
ENV PATH="/home/abcuser/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV NIX_CONFIG="extra-experimental-features = nix-command flakes"

ENV HYDRA_BUILD_ID=297111184
# ENV NIXPKGS_COMMIT=7c43f080a7f28b2774f3b3f43234ca11661bf334

RUN mkdir -pv "$HOME"/.local/bin \
 && cd "$HOME"/.local/bin \
 && curl -L https://hydra.nixos.org/build/"$HYDRA_BUILD_ID"/download-by-type/file/binary-dist > nix \
 && chmod -v +x nix \
 && nix flake --version \
 && nix \
      registry \
      pin \
      nixpkgs github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334 \
 && nix flake metadata nixpkgs \
 && nix profile install github:edolstra/nix-serve \
 && nix profile install nixpkgs#python313
EOF


podman \
build \
--file=Containerfile \
--tag=alpine-with-static-nix .


podman rm container-nix-server --force
podman \
run \
--detach=true \
--interactive=true \
--name=container-nix-server \
--publish=4000:5000 \
--tty=true \
--rm=true \
localhost/alpine-with-static-nix:latest \
sh \
-cl \
'nix-serve'

podman \
run \
--interactive=true \
--net=host \
--tty=true \
--rm=true \
docker.nix-community.org/nixpkgs/nix-flakes \
sh \
-cl \
'
nix store info --store http://localhost:5000
'

podman \
run \
--interactive=true \
--net=host \
--tty=true \
--rm=true \
docker.nix-community.org/nixpkgs/nix-flakes \
sh \
-c \
'
nix \
--option flake-registry "" \
--offline \
copy \
--from http://localhost:5000 \
"$(nix --option flake-registry "" --offline eval --raw nixpkgs#python313)" \
--no-check-sigs

nix \
--option flake-registry "" \
--offline \
run \
nixpkgs#python311 -- -c "import this"

# ls -alh "$(nix --option flake-registry "" --offline eval --raw nixpkgs#python311)"/bin
'
```



```bash
podman \
run \
--device=/dev/kvm:rw \
--interactive=true \
--name=container-nix-server \
--publish=4000:5000 \
--tty=true \
--rm=true \
localhost/alpine-with-static-nix:latest \
sh \
-c \
'nix-serve'

podman \
run \
--interactive=true \
--net=host \
--tty=true \
--rm=true \
localhost/alpine-with-static-nix:latest \
sh \
-c \
'nix store info --store http://localhost:4000 && curl http://localhost:4000/nix-cache-info'

podman \
run \
--device=/dev/kvm:rw \
--interactive=true \
--name=container-client \
--net=host \
--tty=true \
--rm=true \
localhost/alpine-with-static-nix:latest \
sh 
```


```bash
nix \
path-info \
--offline \
--eval-store auto \
--closure-size \
--human-readable \
--json \
--recursive \
--store http://localhost:5000 \
github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334#python3
```


TODO: write an NixOS test that reproduces it!
https://github.com/NixOS/nix/issues/2637
https://github.com/NixOS/nix/issues/8101#issuecomment-2072870182
https://github.com/NixOS/nix/issues/7101
https://github.com/NixOS/nix/issues/9569#issuecomment-1849010136
https://github.com/NixOS/nix/issues/3177
https://github.com/NixOS/nix/issues/8101#issuecomment-1483878923
https://discourse.nixos.org/t/serve-nix-store-over-ssh-and-use-as-substituter/24528
https://discourse.nixos.org/t/cant-get-nix-serve-working-help-appreciated/18879/4


```bash
nix store ls --store http://localhost:4000 -lR "$(nix eval --raw nixpkgs#python3)"/bin
```



```bash
ping -c3 1.1.1.1
```



```bash
nix --option flake-registry "" --offline eval --raw nixpkgs#python3
```

```bash
nix --option flake-registry "" --offline path-info --derivation nixpkgs#python3
```

Worked!
```bash
nix \
copy \
--from http://localhost:4000 \
"$(nix --offline eval --raw nixpkgs#python311)" \
--no-check-sigs

nix \
--option flake-registry "" \
--offline \
run \
nixpkgs#python311 -- -c 'import this'
```
Refs.:
- https://discourse.nixos.org/t/help-with-local-binary-cache/27126/4


Broken:
```bash
nix \
--option flake-registry "" \
--offline \
--store http://localhost:5000 \
build \
--eval-store /nix/store \
--print-out-paths \
nixpkgs#hello


nix \
--option flake-registry "" \
--offline \
--store http://localhost:4000 \
--substituters http://localhost:4000/ \
build \
--builders-use-substitutes \
--eval-store local \
--keep-failed \
--max-jobs 0 \
--print-out-paths \
'nixpkgs#figlet'
```



Broken:
```bash
ls -al $(nix \
--option flake-registry "" \
--offline \
--store http://localhost:4000 \
build \
--eval-store 'local?root=/nix/store' \
--keep-failed \
--max-jobs 0 \
--print-out-paths \
'nixpkgs#figlet')
```


TODO:
```bash
--eval-store 'local?root=/nix/store' \
--eval-store '' \
--no-eval-cache \
--no-use-registries \
```
