
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

(! test -d "$HOME/.config/home-manager" && mkdir -pv "$HOME/.config/home-manager") \
&& cd "$HOME/.config/home-manager" \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHomeManagerFlakeUtils \
&& (git --version || nix profile install nixpkgs#git) \
&& git init \
&& git add . \
&& nix fmt . \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#' \
&& nix \
shell \
github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334#home-manager \
--command \
sh \
-c \
'home-manager switch --flake "$HOME/.config/home-manager"#"$(id -un)"'

nix \
run \
--no-write-lock-file \
github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9 \
-- \
switch --flake "$HOME/.config/home-manager"#"$(id -un)"
```
Refs.:
- 


```bash
nix eval --apply 'builtins.attrNames' '.#homeConfigurations.x86_64-linux.vagrant'
```

```bash
nix build --no-link --print-build-logs --print-out-paths '.#homeConfigurations.x86_64-linux.vagrant.activationPackage'
```


```bash
nix build --no-link --print-build-logs --print-out-paths '.#homeConfigurations.aarch64-linux.vagrant.activationPackage'
```
