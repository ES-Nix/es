#!/usr/bin/env bash



# TODO:
# nix eval --impure --expr '((builtins.getFlake "github:NixOS/nixpkgs/8ba90bbc63e58c8c436f16500c526e9afcb6b00a").legacyPackages.${builtins.currentSystem}.stdenv.isDarwin)'

IS_DARWIN=$(nix eval --impure --expr '((builtins.getFlake "github:NixOS/nixpkgs").legacyPackages.${builtins.currentSystem}.stdenv.isDarwin)')
IS_LINUX=$(nix eval --impure --expr '((builtins.getFlake "github:NixOS/nixpkgs").legacyPackages.${builtins.currentSystem}.stdenv.isLinux)')


FLAKE_ARCHITECTURE=$(nix eval --impure --raw --expr 'builtins.currentSystem').

if [ "$IS_DARWIN" = "true" ]; then
  echo 'The system archtecture was detected as: '"$FLAKE_ARCHITECTURE"
  DUMMY_HOME_PREFIX='/Users'
fi

if [ "$IS_LINUX" = "true" ]; then
  echo 'The system archtecture was detected as: '"$FLAKE_ARCHITECTURE"
  DUMMY_HOME_PREFIX='/home'
fi


CONFIG_NIXPKGS=${OVERRIDE_DIRECTORY_CONFIG_NIXPKGS:-.config/nixpkgs}

export DUMMY_HOME="$DUMMY_HOME_PREFIX"/"$USER"

DIRECTORY_TO_CLONE="$DUMMY_HOME"/"$CONFIG_NIXPKGS"
# DIRECTORY_TO_CLONE="$DUMMY_HOME_PREFIX"/"$USER"/sandbox/sandbox

# export DUMMY_USER=alpine
export DUMMY_USER="$USER"
# export DUMMY_USER="$(id -un)"

# export DUMMY_HOSTNAME=alpine316.localdomain
export DUMMY_HOSTNAME="$(hostname)"


echo 'DIRECTORY_TO_CLONE:' $DIRECTORY_TO_CLONE
echo 'DUMMY_USER:' $DUMMY_USER
echo 'DUMMY_HOME:' $DUMMY_HOME
echo 'DUMMY_HOSTNAME:' $DUMMY_HOSTNAME

# BASE_HM_ATTR_NAME='"'"$DUMMY_USER-$DUMMY_HOSTNAME"'"'

#
HM_ATTR_FULL_NAME=$FLAKE_ARCHITECTURE$DUMMY_USER-$DUMMY_HOSTNAME
FLAKE_ATTR="$DIRECTORY_TO_CLONE"'#homeConfigurations.'$FLAKE_ARCHITECTURE'"'"$DUMMY_USER-$DUMMY_HOSTNAME"'"''.activationPackage'


echo "$DIRECTORY_TO_CLONE" \
&& rm -frv "$DIRECTORY_TO_CLONE" \
&& mkdir -pv "$DIRECTORY_TO_CLONE" \
&& cd "$DIRECTORY_TO_CLONE"


time \
nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#startConfig



sed -i 's/username = ".*";/username = "'$DUMMY_USER'";/g' flake.nix \
&& sed -i 's/hostname = ".*";/hostname = "'"$DUMMY_HOSTNAME"'";/g' flake.nix \
&& git init \
&& git status \
&& git add . \
&& git status \
&& git commit -m 'First nix home-manager commit from installer'

echo $FLAKE_ATTR
# TODO: --max-jobs 0 \


export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1

#--option eval-cache false \
#--option extra-trusted-public-keys binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg= \
#--option extra-substituters https://playing-bucket-nix-cache-test.s3.amazonaws.com \
time \
nix \
build \
--impure \
--keep-failed \
--no-link \
--print-build-logs \
--print-out-paths \
$FLAKE_ATTR

AUX=$(nix build --impure --print-out-paths $FLAKE_ATTR)
nix -vvvvv profile remove '.*'

# It looks like the symbolic link
ls -ahl "$HOME"/.local/state/nix/profiles/profile
file "$HOME"/.local/state/nix/profiles
rm -fv "$HOME"/.local/state/nix/profiles

"$AUX"/activate

home-manager generations

#set -x
#
### && time home-manager switch -b backuphm --impure --flake "$DIRECTORY_TO_CLONE"#$HM_ATTR_FULL_NAME \
#export NIXPKGS_ALLOW_UNFREE=1 \
#&& time home-manager switch -b backuphm --impure --flake "$DIRECTORY_TO_CLONE"#x86_64-linux.'\"'"vagrant-alpine316.localdomain"'\"' \
#&& home-manager generations


TARGET_SHELL='zsh' \
&& FULL_TARGET_SHELL=/home/"$DUMMY_USER"/.nix-profile/bin/"$TARGET_SHELL" \
&& echo \
&& ls -al "$FULL_TARGET_SHELL" \
&& echo \
&& echo "$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
&& echo \
&& sudo \
      -k \
      usermod \
      -s \
      /home/"$DUMMY_USER"/.nix-profile/bin/"$TARGET_SHELL" \
      "$DUMMY_USER"



#time \
#nix \
#--option eval-cache false \
#--option extra-trusted-public-keys binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg= \
#--option extra-substituters https://playing-bucket-nix-cache-test.s3.amazonaws.com \
#shell \
#github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb#{git,bashInteractive,coreutils,gnused,home-manager} \
#--command \
#bash <<-EOF
#    echo $DIRECTORY_TO_CLONE
#    rm -frv $DIRECTORY_TO_CLONE
#    mkdir -pv $DIRECTORY_TO_CLONE
#
#    cd $DIRECTORY_TO_CLONE
#
#    nix \
#    --refresh \
#    flake \
#    init \
#    --template \
#    github:ES-nix/es#"$(nix eval --impure --raw --expr 'builtins.currentSystem')".startConfig
#
#    sed -i 's/username = ".*";/username = "'$DUMMY_USER'";/g' flake.nix \
#    && sed -i 's/hostname = ".*";/hostname = "'"$DUMMY_HOSTNAME"'";/g' flake.nix \
#    && git init \
#    && git status \
#    && git add . \
#    && nix flake update --override-input nixpkgs github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb \
#    && git status \
#    && git add .
#
#    echo "$FLAKE_ATTR"
#    # TODO: --max-jobs 0 \
#    nix \
#    --option eval-cache false \
#    --option extra-trusted-public-keys binarycache-1:XiPHS/XT/ziMHu5hGoQ8Z0K88sa1Eqi5kFTYyl33FJg= \
#    --option extra-substituters https://playing-bucket-nix-cache-test.s3.amazonaws.com \
#    build \
#    --keep-failed \
#    --max-jobs 0 \
#    --no-link \
#    --print-build-logs \
#    --print-out-paths \
#    "$FLAKE_ATTR"
#
#    export NIXPKGS_ALLOW_UNFREE=1 \
#    && home-manager switch -b backuphm --impure --flake "$DIRECTORY_TO_CLONE"#"$HM_ATTR_FULL_NAME" \
#    && home-manager generations
#
#    #
#    TARGET_SHELL='zsh' \
#    && FULL_TARGET_SHELL=/home/"$DUMMY_USER"/.nix-profile/bin/"\$TARGET_SHELL" \
#    && echo \
#    && ls -al "\$FULL_TARGET_SHELL" \
#    && echo \
#    && echo "\$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
#    && echo \
#    && sudo \
#          -k \
#          usermod \
#          -s \
#          /home/"$DUMMY_USER"/.nix-profile/bin/"\$TARGET_SHELL" \
#          "$DUMMY_USER"
#
#EOF
