

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

../nix run github:nix-community/home-manager/release-25.11 -- switch --flake '.#vagrant'
home-manager switch --flake '.#vagrant'
```
Refs.:
- 
