
python3 -c 'import platform; print(platform.libc_ver())'


```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

# curl -s https://api.github.com/repos/NixOS/nix/tags | jq -r '.[0].name'
NIX_RELEASE_VERSION=2.29.0 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --yes --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh \
&& export NIX_CONFIG='extra-experimental-features = nix-command flakes' \
&& nix -vv registry pin nixpkgs github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334

mkdir hm-template \
&& cd $_ \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#nixFlakesHomeManagerZshAdvanced \
--verbose

git --version || nix profile install nixpkgs#git
git config init.defaultBranch \
|| git config --global init.defaultBranch main
git init && git add .

# TODO
sudo rm -fv "$HOME"/.local/state/nix/profiles/profile/manifest.json

nix shell nixpkgs#home-manager --command sh -c 'home-manager -b bckup switch --flake .#"$USER"'

/home/"$USER"/.nix-profile/bin/zsh \
-cl \
'
nix --version \
&& nix flake --version \
&& home-manager --version \
&& home-manager generations \
&& home-manager switch --flake .#"$USER"
'

# echo 'exec /home/"$USER"/.nix-profile/bin/zsh -l' >> ~/.bashrc
```
Refs.:
- https://github.com/Misterio77/nix-starter-configs/issues/3#issuecomment-1312809082
- https://github.com/nix-community/home-manager/issues/2942#issuecomment-1378627909


```bash
nix fmt \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#' \
&& git add .
```

```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/7848cd8c982f7740edf76ddb3b43d234cb80fc4d \
--override-input nixpkgs-unstable github:NixOS/nixpkgs/4faa5f5321320e49a78ae7848582f684d64783e9 \
--override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9
```
