# es


## Remote using this flake


### Example: nginx in an NixOS QEMU VM

```bash
nix run --impure 'github:ES-Nix/es/?dir=src/templates/nginx'
```


```bash
nix build --cores 8 --no-link --print-build-logs --print-out-paths --impure \
'github:ES-Nix/es/?dir=src/templates/pandoc-latex'

nix build --cores 8 --no-link --print-build-logs --print-out-paths --impure \
'github:ES-Nix/es/?dir=src/templates/memcached-static'
```



```bash
docker \
run \
--tty=true \
--interactive=true \
--rm=true \
docker.io/nixpkgs/nix-flakes \
bash
```


## With a local clone

TODO: remove warnings
TODO: better name things, consistenciy and case conventions

```bash
# Defines a multi-line bash array of templates
TEMPLATE_FOLDERS_RELATIVE_PATH=(
    './src/templates/pandoc-latex'
    # './src/templates/nginx'
    # './src/templates/nixos-build-vm-systemd-self-hosted-runner-for-gitHub-actions'
    # './src/templates/nixos-build-vm-kubernetes-self-hosted-runner-for-gitHub-actions'
    # './src/templates/nixos-tests-hello-systemd-service'
    # './src/templates/poetry2nix-basic-flask'
    # './src/templates/poetry2nix-basic'
    # './src/templates/qemu-virtual-machine-xfce-copy-paste-docker'
    # './src/templates/qemu-virtual-machine-xfce-copy-paste-docker-flask'
    # './src/templates/qemu-virtual-machine-xfce-copy-paste-docker-podman-flask'
    # './src/templates/qemu-virtual-machine-xfce-copy-paste-docker-python-script-and-package'
    # './src/templates/minimal-busybox-sandbox-shell'
    # './src/templates/nginx'
    # './src/templates/flake-utils-godot4'
    # './src/templates/nix-flakes-flake-utils-devShell'
    # './src/templates/nix-flakes-flake-utils-devShell-home-manager#homeConfigurations.x86_64-linux.vagrant.activationPackage'
)

for template in "${TEMPLATE_FOLDERS_RELATIVE_PATH[@]}"; do
    nix \
    build \
    --cores 6 \
    --no-link \
    --print-build-logs \
    --print-out-paths \
    --impure \
    "$template" \
    && nix \
        flake \
        check \
        --impure \
        "$template"
done
```


```bash
nix build --cores 8 --no-link --print-build-logs --print-out-paths --impure \
--override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
'./src/templates/redis-static' \
'./src/templates/nginx-static' \
'./src/templates/memcached-static' \
'./src/templates/memcached-static-cross'
```


TODO: re-execute
```bash
nix build --cores 6 --no-link --print-build-logs --print-out-paths --impure \
--override-input nixpkgs 'github:NixOS/nixpkgs/95600680c021743fd87b3e2fe13be7c290e1cac4' \
'./src/templates/binfmt-emulated-systems-python-docker-registry-images'
```

Only in unstable it has the binfmt needed:
```bash
nix build --cores 6 --no-link --print-build-logs --print-out-paths --impure \
--override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
'./src/templates/binfmt-emulated-systems-hello' \
'./src/templates/binfmt-emulated-systems-docker' \
'./src/templates/binfmt-emulated-riscv64-python-alpine-wheels-via-pip-and-docker'
```

'./src/templates/qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-ubuntu' \


TODO: It takes too long to build. 
```bash
nix build --cores 6 --no-link --print-build-logs --print-out-paths --impure \
--override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
'./src/templates/nixos-iso-offline-install'
```

It is broken, see the issue.
```bash
nix build --cores 8 --no-link --print-build-logs --print-out-paths --impure \
--override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
'./src/templates/valkey-static'
```
Refs.:
- https://github.com/NixOS/nixpkgs/issues/387010

Only works in some different commit:
```bash
nix build --cores 6 --no-link --print-build-logs --print-out-paths --impure \
'./src/templates/docker-multiple-kernel-versions'
```

Only works in some different commit:
```bash
nix build --cores 6 --no-link --print-build-logs --print-out-paths --impure \
'./src/templates/bug-nixostest'
```


Cleaning/garbage collect:
```bash
nix \
store \
gc \
--verbose \
--option keep-outputs true \
--option keep-build-log true \
--option keep-derivations true \
--option keep-env-derivations true \
&& nix-collect-garbage --delete-old --verbose \
&& nix store optimise --verbose
```


## Contributing

```bash
nix flake clone 'git+ssh://git@github.com/ES-Nix/es.git' --dest es \
&& cd es 1>/dev/null 2>/dev/null \
&& (direnv --version 1>/dev/null 2>/dev/null && direnv allow) \
|| nix develop $SHELL
```


## Using 


```bash
nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```

```bash
nix flake show --json .# | jq '."templates"'
```


```bash
# https://xkcd.com/1654/
command -v curl || (command -v apt && sudo apt-get update && sudo apt-get install -y curl)
command -v curl || (command -v apk && sudo apk add --no-cache curl)

(( test -d /nix/var/nix \
|| test -w /nix \
|| test 1735 -eq $(stat -c '%a' /nix/var/nix)
) || sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix') \
&& curl -L https://hydra.nixos.org/build/278148689/download-by-type/file/binary-dist > nix \
&& echo 41ffe16f6119fbcf06f2e442d62cf7e051e272a9e2bac0cda754732652282134'  'nix \
 | sha256sum -c \
&& chmod +x nix \
&& ./nix --version \
&& ./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
run \
github:ES-nix/es#installStartConfigTemplate \
&& exec ~/.nix-profile/bin/zsh

# command -v ssh-keygen || nix profile install nixpkgs#openssh
# command -v git || nix profile install nixpkgs#git
```






```bash
nix \
run \
--refresh \
github:ES-nix/es#sendToCacheInstallStartConfigTemplate
```


### 

```bash
nix registry list
```

```bash
nix flake show templates
```


TODO: test all the templates!
```bash
nix flake show templates --json
```




### 

- nix flake init --template templates#full
- https://xeiaso.net/blog/nix-flakes-terraform
- https://juliu.is/tidying-your-home-with-nix/#ive-changed-my-mind-how-do-i-get-both-stable-and-unstable
- https://discourse.nixos.org/t/home-manager-flake-does-not-provide-attribute/24926
- https://discourse.nixos.org/t/fixing-error-attribute-currentsystem-missing-in-flake/22386/7



```bash
nix \
--refresh \
run \
github:ES-nix/es#installStartConfigTemplate
```


```bash
rm -frv ~/.cache/nix/*
```

```bash
mkdir -pv ~/sandbox/sandbox \
&& cd ~/sandbox/sandbox
```

```bash
nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#"$(nix eval --impure --raw --expr 'builtins.currentSystem')".startConfig
```


```bash
nix shell nixpkgs#git -c sh -c 'git init && git add .'
```



```bash
# Precisa das variáveis de ambiente USER e HOME

# DIRECTORY_TO_CLONE=/home/"$USER"/.config/nixpkgs
DIRECTORY_TO_CLONE=/home/"$USER"/sandbox/sandbox

# export DUMMY_USER=alpine
export DUMMY_USER="$USER"
# export DUMMY_USER="$(id -un)"

# TODO: Mac
# export DUMMY_HOME="$HOME"
export DUMMY_HOME=/home/"$USER"

# export DUMMY_HOSTNAME=alpine316.localdomain
export DUMMY_HOSTNAME="$(hostname)"



BASE_HM_ATTR_NAME="$DUMMY_USER"-"$DUMMY_HOSTNAME"
FLAKE_ARCHITECTURE=$(nix eval --impure --raw --expr 'builtins.currentSystem').

HM_ATTR_FULL_NAME="$FLAKE_ARCHITECTURE"'"""'"$BASE_HM_ATTR_NAME"'"""'

FLAKE_ATTR="$DIRECTORY_TO_CLONE""#homeConfigurations.""$HM_ATTR_FULL_NAME"".activationPackage"

# "$(nix eval --impure --raw --expr 'builtins.currentSystem')"-
#HM_ATTR_FULL_NAME='"'"$DUMMY_USER"-"$DUMMY_HOSTNAME"'"'
#FLAKE_ATTR="$DIRECTORY_TO_CLONE""#homeConfigurations.""$HM_ATTR_FULL_NAME"".activationPackage"

nix profile install github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb#git
 
time \
nix \
--option eval-cache false \
--option extra-trusted-public-keys binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg= \
--option extra-substituters https://playing-bucket-nix-cache-test.s3.amazonaws.com \
shell \
github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb#{git,bashInteractive,coreutils,gnused,home-manager} \
--command \
bash <<-EOF
    echo $DIRECTORY_TO_CLONE
    rm -frv $DIRECTORY_TO_CLONE
    mkdir -pv $DIRECTORY_TO_CLONE

    cd $DIRECTORY_TO_CLONE
    
    nix \
    --refresh \
    flake \
    init \
    --template \
    github:ES-nix/es#"$(nix eval --impure --raw --expr 'builtins.currentSystem')".startConfig

    sed -i 's/username = ".*";/username = "'$DUMMY_USER'";/g' flake.nix \
    && sed -i 's/hostname = ".*";/hostname = "'"$DUMMY_HOSTNAME"'";/g' flake.nix \
    && git init \
    && git status \
    && git add . \
    && nix flake update --override-input nixpkgs github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb \
    && git status \
    && git add .
    
    echo "$FLAKE_ATTR"
    # TODO: --max-jobs 0 \
    nix \
    --option eval-cache false \
    --option extra-trusted-public-keys binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg= \
    --option extra-substituters https://playing-bucket-nix-cache-test.s3.amazonaws.com \
    build \
    --keep-failed \
    --max-jobs 0 \
    --no-link \
    --print-build-logs \
    --print-out-paths \
    "$FLAKE_ATTR"
    
    export NIXPKGS_ALLOW_UNFREE=1 \
    && home-manager switch -b backuphm --impure --flake "$DIRECTORY_TO_CLONE"#"$HM_ATTR_FULL_NAME" \
    && home-manager generations
    
    #
    TARGET_SHELL='zsh' \
    && FULL_TARGET_SHELL=/home/"$DUMMY_USER"/.nix-profile/bin/"\$TARGET_SHELL" \
    && echo \
    && ls -al "\$FULL_TARGET_SHELL" \
    && echo \
    && echo "\$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
    && echo \
    && sudo \
          -k \
          usermod \
          -s \
          /home/"$DUMMY_USER"/.nix-profile/bin/"\$TARGET_SHELL" \
          "$DUMMY_USER"
    
EOF
```
