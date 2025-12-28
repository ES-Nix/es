

```bash
mkdir -pv devShellHomeManagerFlakeUtils \
&& cd devShellHomeManagerFlakeUtils \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHomeManagerFlakeUtils

git --version || nix profile install nixpkgs#git
git init && git add .
```
Refs.:
- 
