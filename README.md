# es


1)
```bash
command -v curl || (command -v apt && sudo apt-get update && sudo apt-get install -y curl)
command -v curl || (command -v apk && sudo apk add --no-cache -y curl)


NIX_RELEASE_VERSION=2.10.2 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh

export NIX_CONFIG='extra-experimental-features = nix-command flakes'
```




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



```bash
mkdir -pv ~/sandbox/sandbox \
&& cd ~/sandbox/sandbox
```

```bash
nix flake init --template templates#full
```

```bash
nix flake show .#
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


checks.suportedSystem = self.packages.suportedSystem;


mkdir -pv hosts/minimal-example-nixos



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


      # templates = import ./src/templates { system = "x86_64-linux"; } ;
      # templates.default = import ./src/templates;

#      packages.checkNixFormat = pkgsAllowUnfree.runCommand "check-nix-format" { } ''
#        ${pkgsAllowUnfree.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
#
#        # For fix
#        # find . -type f -iname '*.nix' -exec nixpkgs-fmt {} \;
#
#        mkdir $out #sucess
#      '';
#
#      apps.${name} = flake-utils.lib.mkApp {
#        inherit name;
#        drv = packages.${name};
#      };