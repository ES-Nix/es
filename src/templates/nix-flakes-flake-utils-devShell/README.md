

```bash
mkdir -pv devShellHello \
&& cd devShellHello \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHello

git --version || nix profile install nixpkgs#git
git init && git add .
```
Refs.:
- 


```bash
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'
```



```bash
nix develop '.#' -c true
```


```bash
nix store gc -v
```


```bash
nix develop '.#' -c true
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

