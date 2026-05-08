

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

nix run github:nix-community/home-manager/f63d0fe9d81d36e5fc95497217a72e02b8b7bcab -- switch --flake '.#vagrant'
# home-manager switch --flake '.#vagrant'
```
Refs.:
- 
