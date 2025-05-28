
```bash
! test -d "$HOME/.config/home-manager" \
&& mkdir -pv "$HOME/.config/home-manager" \
&& cd "$HOME/.config/home-manager" \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHomeManagerFlakeUtils

git --version || nix profile install nixpkgs#git
git init && git add .

nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'

nix \
shell \
github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334#home-manager \
--command \
sh \
-c \
'home-manager switch --flake "$HOME/.config/home-manager"#"$(id -un)"'

nix \
run \
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



### Extra commands

```bash
ls -alh /nix/var/nix/temproots/
```

```bash
nix --option keep-derivations false store gc -v
```


```bash
nix show-config | grep keep
```


```bash
file $(readlink -f .profiles/dev)
```


```bash
rm -frv .profiles
```


```bash
rm -fr .git
```

