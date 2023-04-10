#!/usr/bin/env bash


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


echo 'DIRECTORY_TO_CLONE:' $DIRECTORY_TO_CLONE
echo 'DUMMY_USER:' $DUMMY_USER
echo 'DUMMY_HOME:' $DUMMY_HOME
echo 'DUMMY_HOSTNAME:' $DUMMY_HOSTNAME

BASE_HM_ATTR_NAME='"'$DUMMY_USER'-'$DUMMY_HOSTNAME'"'
FLAKE_ARCHITECTURE=$(nix eval --impure --raw --expr 'builtins.currentSystem').

echo $FLAKE_ARCHITECTURE

HM_ATTR_FULL_NAME=$FLAKE_ARCHITECTURE$BASE_HM_ATTR_NAME

FLAKE_ATTR="$DIRECTORY_TO_CLONE"'#homeConfigurations.'$HM_ATTR_FULL_NAME'.activationPackage'

# "$(nix eval --impure --raw --expr 'builtins.currentSystem')"-
#HM_ATTR_FULL_NAME='"'"$DUMMY_USER"-"$DUMMY_HOSTNAME"'"'
#FLAKE_ATTR="$DIRECTORY_TO_CLONE""#homeConfigurations.""$HM_ATTR_FULL_NAME"".activationPackage"

# nix profile install github:NixOS/nixpkgs/f5ffd5787786dde3a8bf648c7a1b5f78c4e01abb#git


echo "$DIRECTORY_TO_CLONE" \
&& rm -frv "$DIRECTORY_TO_CLONE" \
&& mkdir -pv "$DIRECTORY_TO_CLONE" \
&& cd "$DIRECTORY_TO_CLONE"

nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#$(nix eval --impure --raw --expr 'builtins.currentSystem').startConfig


echo Debug

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
$FLAKE_ATTR

#export NIXPKGS_ALLOW_UNFREE=1 \
#&& home-manager switch -b backuphm --impure --flake "$DIRECTORY_TO_CLONE"#"$HM_ATTR_FULL_NAME" \
#&& home-manager generations
#
##
#TARGET_SHELL='zsh' \
#&& FULL_TARGET_SHELL=/home/"$DUMMY_USER"/.nix-profile/bin/"$TARGET_SHELL" \
#&& echo \
#&& ls -al "$FULL_TARGET_SHELL" \
#&& echo \
#&& echo "$FULL_TARGET_SHELL" | sudo tee -a /etc/shells \
#&& echo \
#&& sudo \
#      -k \
#      usermod \
#      -s \
#      /home/"$DUMMY_USER"/.nix-profile/bin/"$TARGET_SHELL" \
#      "$DUMMY_USER"
#
#

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
