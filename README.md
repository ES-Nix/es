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

```bash
git init \
&& git status \
&& git add . \
&& nix flake update --override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
&& git status \
&& git add . \
&& git commit -m 'First nix flake commit'"$(date +'%d/%m/%Y %H:%M:%S:%3N')" \
&& nix flake lock \
&& git add . \
&& git commit -m 'Second nix flake commit'"$(date +'%d/%m/%Y %H:%M:%S:%3N')" \
&& git status
```


{
  description = "A template that shows all standard flake outputs";

  # Inputs
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-inputs

  # The flake in the current directory.
  # inputs.currentDir.url = ".";

  # A flake in some other directory.
  # inputs.otherDir.url = "/home/alice/src/patchelf";

  # A flake in some absolute path
  # inputs.otherDir.url = "path:/home/alice/src/patchelf";

  # The nixpkgs entry in the flake registry.
  inputs.nixpkgsRegistry.url = "nixpkgs";

  # The nixpkgs entry in the flake registry, overriding it to use a specific Git revision.
  inputs.nixpkgsRegistryOverride.url = "nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";

  # The master branch of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgsGitHub.url = "github:NixOS/nixpkgs";

  # Inputs as attrsets.
  # An indirection through the flake registry.
  inputs.nixpkgsIndirect = {
    type = "indirect";
    id = "nixpkgs";
  };

  # Transitive inputs can be overridden from a flake.nix file. For example, the following overrides the nixpkgs input of the nixops input:
  inputs.nixops.inputs.nixpkgs = {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
  };

  # It is also possible to "inherit" an input from another input. This is useful to minimize
  # flake dependencies. For example, the following sets the nixpkgs input of the top-level flake
  # to be equal to the nixpkgs input of the nixops input of the top-level flake:
  inputs.nixpkgs.url = "nixpkgs";

  inputs.c-hello.url = "github:NixOS/templates?dir=c-hello";
  inputs.rust-web-server.url = "github:NixOS/templates?dir=rust-web-server";
  inputs.nix-bundle.url = "github:NixOS/bundlers";

  # Work-in-progress: refer to parent/sibling flakes in the same repository
  # inputs.c-hello.url = "path:../c-hello";

  outputs = all@{ self, c-hello, rust-web-server, nixpkgs, nix-bundle, ... }: {

    # Utilized by `nix flake check`
    checks.x86_64-linux.test = c-hello.checks.x86_64-linux.test;

    # Utilized by `nix build .`
    defaultPackage.x86_64-linux = c-hello.defaultPackage.x86_64-linux;

    # Utilized by `nix build`
    packages.x86_64-linux.hello = c-hello.packages.x86_64-linux.hello;

    # Utilized by `nix run .#<name>`
    apps.x86_64-linux.hello = {
      type = "app";
      program = c-hello.packages.x86_64-linux.hello;
    };

    # Utilized by `nix bundle -- .#<name>` (should be a .drv input, not program path?)
    bundlers.x86_64-linux.example = nix-bundle.bundlers.x86_64-linux.toArx;

    # Utilized by `nix bundle -- .#<name>`
    defaultBundler.x86_64-linux = self.bundlers.x86_64-linux.example;

    # Utilized by `nix run . -- <args?>`
    defaultApp.x86_64-linux = self.apps.x86_64-linux.hello;

    # Utilized for nixpkgs packages, also utilized by `nix build .#<name>`
    legacyPackages.x86_64-linux.hello = c-hello.defaultPackage.x86_64-linux;

    # Default overlay, for use in dependent flakes
    overlay = final: prev: { };

    # # Same idea as overlay but a list or attrset of them.
    overlays = { exampleOverlay = self.overlay; };

    nixosConfigurations.myvm = let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          # system = "aarch64-linux";
          config = { allowUnfree = true; };
        };
     in
        nixpkgs.lib.nixosSystem 
        {
        # system = "aarch64-linux";
        system = "x86_64-linux";
        modules = let
                     nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly";      
          in [
          "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/build-vm.nix"
          "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-vm.nix"
          # "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/virtualisation/qemu-guest.nix"
          "${toString (builtins.getFlake "github:NixOS/nixpkgs/a8f8b7db23ec6450e384da183d270b18c58493d4")}/nixos/modules/installer/cd-dvd/channel.nix"

          ({
            boot.kernelParams = [
              "console=tty0"
              "console=ttyAMA0,115200n8"
              # Set sensible kernel parameters
              # https://nixos.wiki/wiki/Bootloader
              # https://git.redbrick.dcu.ie/m1cr0man/nix-configs-rb/commit/ddb4d96dacc52357e5eaec5870d9733a1ea63a5a?lang=pt-PT
              "boot.shell_on_fail"
              "panic=30"
              "boot.panic_on_fail" # reboot the machine upon fatal boot issues
              # TODO: test it
              "intel_iommu=on"
              "iommu=pt"

              # https://discuss.linuxcontainers.org/t/podman-wont-run-containers-in-lxd-cgroup-controller-pids-unavailable/13049/2
              # https://github.com/NixOS/nixpkgs/issues/73800#issuecomment-729206223
              # https://github.com/canonical/microk8s/issues/1691#issuecomment-977543458
              # https://github.com/grahamc/nixos-config/blob/35388280d3b06ada5882d37c5b4f6d3baa43da69/devices/petunia/configuration.nix#L36
              # cgroup_no_v1=all
              "swapaccount=0"
              "systemd.unified_cgroup_hierarchy=0"
              "group_enable=memory"
            ];

            boot.tmpOnTmpfs = false;
            # https://github.com/AtilaSaraiva/nix-dotfiles/blob/main/lib/modules/configHost/default.nix#L271-L273
            boot.tmpOnTmpfsSize = "100%";

            # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
            users.extraGroups.nixgroup.gid = 999;

            users.users.nixuser = {
              isSystemUser = true;
              password = "";
              createHome = true;
              home = "/home/nixuser";
              homeMode = "0700";
              description = "The VM tester user";
              group = "nixgroup";
              extraGroups = [
                              "podman"
                              "kvm"
                              "libvirtd"
                              "wheel"
              ];
              packages = with pkgs; [
                  direnv
                  file
                  gnumake
                  which
                  coreutils
              ];
              shell = pkgs.bashInteractive;
              uid = 1234;
              autoSubUidGidRange = true;

              openssh.authorizedKeys.keyFiles = [
                "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly" }"
              ];

              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly"
              ];
            };

              virtualisation = {
                # following configuration is added only when building VM with build-vm
                memorySize = 3072; # Use MiB memory.
                diskSize = 1024 * 16; # Use MiB memory.
                cores = 6;         # Simulate 6 cores.
                
                #
                docker.enable = false;
                podman.enable = true;
                
                #
                useNixStoreImage = true;
                writableStore = true; # TODO
              };

              nixpkgs.config.allowUnfree = true;
              nix = {
                # package = nixpkgs.pkgs.nix;
                extraOptions = "experimental-features = nix-command flakes";
                readOnlyStore = true;
              };

              # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
              services.openssh = {
                allowSFTP = true;
                kbdInteractiveAuthentication = false;
                enable = true;
                forwardX11 = false;
                passwordAuthentication = false;
                permitRootLogin = "yes";
                ports = [ 10022 ];
                authorizedKeysFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly" }"
                ];
              };

            time.timeZone = "America/Recife";
            system.stateVersion = "22.11";

            users.users.root = {
              password = "root";
              initialPassword = "root";
              openssh.authorizedKeys.keyFiles = [
                "${ pkgs.writeText "nixuser-keys.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyhLx5HU63zJJ5Lx4j+NTC/OQZ7Weloc8y+On467kly" }"
              ];
            };
          })
        ];
    };

    # Utilized by Hydra build jobs
    hydraJobs.example.x86_64-linux = self.defaultPackage.x86_64-linux;
  };
}



```bash
wget -q http://ix.io/4uHn -O flake.nix \
&& git add .
```

```bash
nix build --no-show-trace -L .#nixosConfigurations.myvm.config.system.build.toplevel
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
