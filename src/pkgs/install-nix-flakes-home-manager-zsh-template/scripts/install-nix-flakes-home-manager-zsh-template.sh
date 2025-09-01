#!/usr/bin/env bash


time \
./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
shell \
--ignore-environment \
--keep HOME \
--keep NO_EXEC \
--keep SHELL \
--keep USER \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#gnused \
nixpkgs#nix \
nixpkgs#gitMinimal \
nixpkgs#home-manager \
--command \
bash \
<<'COMMANDS'
# set -x

OLD_PWD=$(pwd)

mkdir -pv /home/"$USER"/.config/home-manager && cd $_

"$OLD_PWD"/nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
--option auto-allocate-uids false \
--refresh \
flake \
init \
--template \
github:ES-nix/es#nixFlakesHomeManagerZsh \
--verbose

test -f /home/"$USER"/.config/home-manager/flake.nix || echo 'not found flake.nix'

sed -i 's/.*userName = ".*";/userName = "'"$USER"'";/' /home/"$USER"/.config/home-manager/flake.nix

(git config init.defaultBranch || git config --global init.defaultBranch main) \
&& git init \
&& git add .

#"$OLD_PWD"/nix \
#--extra-experimental-features nix-command \
#--extra-experimental-features flakes \
#--extra-experimental-features auto-allocate-uids \
#--option auto-allocate-uids false \
#--option warn-dirty false \
#flake \
#lock \
#--override-input nixpkgs github:NixOS/nixpkgs/d12251ef6e8e6a46e05689eeccd595bdbd3c9e60 \
#--override-input home-manager github:nix-community/home-manager/a631666f5ec18271e86a5cde998cba68c33d9ac6
#
#git add .

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

home-manager \
switch \
-b backup \
--print-build-logs \
--option warn-dirty false \
--verbose

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

# Useful to copy/paste
echo '/home/"$USER"/.nix-profile/bin/zsh --login'

test -z "$NO_EXEC" || exit 0

exec /home/"$USER"/.nix-profile/bin/zsh --login
