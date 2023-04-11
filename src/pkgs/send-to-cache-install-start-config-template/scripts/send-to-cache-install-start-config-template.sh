#!/usr/bin/env bash


export OVERRIDE_DIRECTORY_CONFIG_NIXPKGS=sandboxdir \
&& mkdir -pv "$OVERRIDE_DIRECTORY_CONFIG_NIXPKGS" \
&& cd "$OVERRIDE_DIRECTORY_CONFIG_NIXPKGS"

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
github:ES-nix/es#$(nix eval --impure --raw --expr 'builtins.currentSystem').startConfig



#sed -i 's/username = ".*";/username = "'$DUMMY_USER'";/g' flake.nix \
#&& sed -i 's/hostname = ".*";/hostname = "'"$DUMMY_HOSTNAME"'";/g' flake.nix \
#&& git init \
#&& git status \
#&& git add . \
#&& nix flake update --override-input nixpkgs github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb \
#&& git status \
#&& git add .


echo $FLAKE_ATTR


#nix \
#build \
#--eval-store auto \
#--keep-failed \
#--max-jobs 0 \
#--no-link \
#--print-build-logs \
#--print-out-paths \
#--store ssh-ng://builder \
#$FLAKE_ATTR


export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1

nix \
build \
--impure \
--eval-store auto \
--keep-failed \
--max-jobs 0 \
--no-link \
--print-build-logs \
--print-out-paths \
--store ssh-ng://builder \
'.#homeConfigurations.aarch64-darwin."alvaro-Maquina-Virtual-de-Alvaro.local".activationPackage'
