# es

## Contributing

```bash
nix flake clone 'git+ssh://git@github.com/ES-Nix/es.git' --dest es \
&& cd es 1>/dev/null 2>/dev/null \
&& (direnv --version 1>/dev/null 2>/dev/null && direnv allow) \
|| nix develop $SHELL
```

## Using 

1)
```bash
command -v curl || (command -v apt && sudo apt-get update && sudo apt-get install -y curl)
command -v curl || (command -v apk && sudo apk add --no-cache curl)


NIX_RELEASE_VERSION=2.10.2 \
&& time curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh

export NIX_CONFIG='extra-experimental-features = nix-command flakes'

time \
nix \
--refresh \
run \
github:ES-nix/es#installStartConfigTemplate
```


```bash
nix \
run \
--refresh \
github:ES-nix/es#sendToCacheInstallStartConfigTemplate
```

```bash
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 \
&& nix show-derivation --impure github:NixOS/nixpkgs/nixpkgs-unstable#darwin.builder
```

```bash
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 \
&& nix build --impure --print-build-logs github:NixOS/nixpkgs/nixpkgs-unstable#darwin.builder
```

```bash
nix build --impure --no-link --print-build-logs \
"$HOME"/.config/nixpkgs#nixosConfigurations.x86_64-linux.build-vm-dev.config.system.build.vm
```

```bash
error: derivation '/nix/store/v8hi07w07q0dvdf035y73xm6ia2ps09y-python3-3.10.10.drv' may not be deterministic: output '/nix/store/ppjxjd3li8r9b61n1nn5jqgdd20bcvj7-python3-3.10.10' differs
```

```bash
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
nix build --impure --print-build-logs nixpkgs#glibc

FLAKE_ATTR="$DIRECTORY_TO_CLONE"'#homeConfigurations.'$FLAKE_ARCHITECTURE'"'"$DUMMY_USER-$DUMMY_HOSTNAME"'"''.activationPackage'


export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1

time \
nix \
--option eval-cache false \
--option extra-trusted-public-keys binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg= \
--option extra-substituters https://playing-bucket-nix-cache-test.s3.amazonaws.com \
build \
--impure \
--keep-failed \
--no-link \
--print-build-logs \
--print-out-paths \
'.#homeConfigurations.aarch64-darwin."alvaro-Maquina-Virtual-de-Alvaro.local".activationPackage'

$FLAKE_ATTR


nix \
build \
--impure \
--keep-failed \
--no-link \
--print-build-logs \
--print-out-paths \
'.#homeConfigurations.aarch64-darwin."alvaro-Maquina-Virtual-de-Alvaro.local".activationPackage'
```


```bash
nix \
build \
--impure \
--print-build-logs \
--print-out-paths \
--rebuild \
--expr \
'
  (                                         
    with builtins.getFlake "github:NixOS/nixpkgs/f0fa012b649a47e408291e96a15672a4fe925d65";
    with legacyPackages.${builtins.currentSystem};
    (pkgsStatic.python3Minimal.override
      {
        reproducibleBuild = true;
      }
    )
  )
'
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

```bash
checks.suportedSystem = self.packages.suportedSystem;


mkdir -pv hosts/minimal-example-nixos
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


```bash
templates = import ./src/templates { system = "x86_64-linux"; } ;
templates.default = import ./src/templates;

packages.checkNixFormat = pkgsAllowUnfree.runCommand "check-nix-format" { } ''
    ${pkgsAllowUnfree.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
    
    # For fix
    # find . -type f -iname '*.nix' -exec nixpkgs-fmt {} \;
    
    mkdir $out #sucess
'';

apps.${name} = flake-utils.lib.mkApp {
    inherit name;
    drv = packages.${name};
};
```
