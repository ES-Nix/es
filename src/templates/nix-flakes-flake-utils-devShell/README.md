

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
