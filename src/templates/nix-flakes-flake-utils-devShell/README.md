

```bash
mkdir -pv devShellHello \
&& cd devShellHello \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHello

nix profile install nixpkgs#git

git init &&  git add .
```
Refs.:
- 


```bash
nix develop '.#'
```

```bash
ls -alh /nix/var/nix/temproots/
```

```bash
nix store gc -v
```



```bash
file $(readlink -f .profiles/dev)
```


```bash
rm -frv .profiles
```
