



```bash
curl -L https://hydra.nixos.org/build/257665509/download-by-type/file/binary-dist > nix \
&& chmod +x nix \
&& ./nix --version
```

Not a must:
```bash
echo a559d9c4c144859251ab5441cf285f1c38861e4bb46509e38229474368286467'  'nix \
| sha256sum -c
```


Really bare bones:
```bash
./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
shell \
nixpkgs#bashInteractive \
nixpkgs#home-manager \
nixpkgs#nix \
--command \
bash \
-c \
'
home-manager init --switch \
&& home-manager generations
'
```


More involving example:
```bash
./nix \
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
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#gnused \
nixpkgs#nixStatic \
nixpkgs#gitMinimal \
nixpkgs#home-manager \
--command \
bash \
<<'COMMANDS'
# set -x

OLD_PWD=$(pwd)

mkdir -pv /home/"$USER"/.config/home-manager && cd $_

cat << 'EOF' > flake.nix
{
  description = "Home Manager configuration";

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
      homeDirectory = "/home/${userName}";

      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."${userName}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ pkgs, ... }:
            {
              home.stateVersion = "23.11";
              home.username = "${userName}";
              home.homeDirectory = "${homeDirectory}";

              programs.home-manager = {
                enable = true;
              };

              home.packages = with pkgs; [
                git
                nixStatic
                zsh
              ];

              nix = {
                enable = true;
                package = pkgs.nixStatic;
                extraOptions = ''
                  experimental-features = nix-command flakes
                '';
                registry.nixpkgs.flake = nixpkgs;
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


test -f /home/"$USER"/.config/home-manager/flake.nix || echo not found flake.nix

sed -i 's/.*userName = ".*";/userName = "'"$USER"'";/' /home/"$USER"/.config/home-manager/flake.nix

git config init.defaultBranch \
|| git config --global init.defaultBranch main

git init && git add .

"$OLD_PWD"/nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--option warn-dirty false \
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


test -L /home/"$USER"/.nix-profile/bin/zsh \
&& test -f "$OLD_PWD"/nix && rm -v "$OLD_PWD"/nix

# For some reason in the first execution it fails
# needing re loging, but this workaround allows a
# way better first developer experience.
/home/"$USER"/.nix-profile/bin/zsh \
-lc 'home-manager switch 1> /dev/null 2> /dev/null' 2> /dev/null || true
COMMANDS
```


```bash
/home/"$USER"/.nix-profile/bin/zsh -l
```



```bash
./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
shell \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
nixpkgs#bashInteractive \
nixpkgs#home-manager \
--command \
bash \
-c \
'exec /home/"$USER"/.nix-profile/bin/zsh -l'
```


TODO: help in there
https://github.com/nix-community/home-manager/issues/3752#issuecomment-2061051384

### home-manager.lib.hm.dag.entryAfter


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
FROM docker.io/library/alpine:3.19.1

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
ENV NIX_CONFIG="extra-experimental-features = nix-command flakes"

ENV HYDRA_BUILD_ID=257665509
ENV NIXPKGS_COMMIT=58a1abdbae3217ca6b702f03d3b35125d88a2994

RUN mkdir -pv "$HOME"/.local/bin \
 && cd "$HOME"/.local/bin \
 && curl -L https://hydra.nixos.org/build/"$HYDRA_BUILD_ID"/download-by-type/file/binary-dist > nix \
 && chmod -v +x nix \
 && nix flake --version \
 && nix \
      registry \
      pin \
      nixpkgs github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8 \
 && nix flake metadata nixpkgs \
 && nix profile install github:edolstra/nix-serve \
 && nix profile install nixpkgs#python3
EOF


podman \
build \
--file=Containerfile \
--tag=alpine-with-static-nix .


podman \
run \
--device=/dev/kvm:rw \
--interactive=true \
--tty=true \
--rm=true \
localhost/alpine-with-static-nix:latest \
sh \
-l
```




```bash
podman \
run \
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
--interactive=true \
--name=container-client \
--net=host \
--tty=true \
--rm=true \
localhost/alpine-with-static-nix:latest \
sh \
-c \
'
nix \
copy \
--from http://localhost:4000 \
"$(nix --option flake-registry "" --offline  eval --raw nixpkgs#python311)" \
--no-check-sigs

nix \
--option flake-registry "" \
--offline \
run \
nixpkgs#python311 -- -c "import this"

ls -alh "$(nix --option flake-registry "" --offline  eval --raw nixpkgs#python311)"/bin
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
github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8#python3
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
nix store ls --store http://localhost:4000  -lR "$(nix eval --raw nixpkgs#python3)"/bin
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
"$(nix --option flake-registry "" --offline  eval --raw nixpkgs#python311)" \
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
