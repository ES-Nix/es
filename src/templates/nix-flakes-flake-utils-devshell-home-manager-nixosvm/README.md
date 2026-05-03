

```bash
mkdir -pv devShellHomeManagerFlakeUtilsNixOSVM \
&& cd devShellHomeManagerFlakeUtilsNixOSVM \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHomeManagerFlakeUtilsNixOSVM

git --version || nix profile install nixpkgs#git
git init && git add .

nix run github:nix-community/home-manager/release-25.11 -- switch --flake '.#vagrant'
# home-manager switch --flake '.#vagrant'
```
Refs.:
- 
