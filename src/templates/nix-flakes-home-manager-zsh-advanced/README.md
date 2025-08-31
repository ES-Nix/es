



```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

xz --version || sudo apt-get install -y xz
xz --version || sudo apk add --no-cache xz

# curl -s https://api.github.com/repos/NixOS/nix/tags | jq -r '.[0].name'
NIX_RELEASE_VERSION=2.28.4 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --yes --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh \
&& export NIX_CONFIG='extra-experimental-features = nix-command flakes' \
&& nix -vv registry pin nixpkgs github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd

mkdir -pv "$HOME"/.config/home-manager \
&& cd $_ \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#nixFlakesHomeManagerZshAdvanced \
--verbose

(git --version || nix profile install nixpkgs#git) \
&& (git config init.defaultBranch || git config --global init.defaultBranch main) \
&& git init \
&& git add . \
&& git status

ls -alh "$HOME"/.local/state/nix/profiles/profile/manifest.json \
&& sudo rm -fv "$HOME"/.local/state/nix/profiles/profile/manifest.json

ls -alh "$HOME"/.config/nix/registry.json \
&& sudo rm -fv "$HOME"/.config/nix/registry.json

nix shell nixpkgs#home-manager --command sh -c 'home-manager -b bckup switch --flake .#"$USER"'

"$HOME"/.nix-profile/bin/zsh \
-cl \
'
nix --version \
&& nix flake --version \
&& home-manager --version \
&& home-manager generations \
&& home-manager switch --flake .#"$USER"
'
echo 'exec /home/"$USER"/.nix-profile/bin/zsh --login' >> ~/.profile
```
Refs.:
- https://github.com/Misterio77/nix-starter-configs/issues/3#issuecomment-1312809082
- https://github.com/nix-community/home-manager/issues/2942#issuecomment-1378627909


```bash
nix fmt . \
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
--override-input nixpkgs github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd \
--override-input nixpkgs-unstable github:NixOS/nixpkgs/4faa5f5321320e49a78ae7848582f684d64783e9 \
--override-input home-manager github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9
```
