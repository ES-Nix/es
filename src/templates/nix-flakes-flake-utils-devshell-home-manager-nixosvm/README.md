

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

nix run github:nix-community/home-manager/f63d0fe9d81d36e5fc95497217a72e02b8b7bcab -- switch --flake '.#vagrant'
# home-manager switch --flake '.#vagrant'
```
Refs.:
- 


```bash
(rm -frv ~/.config/home-manager/ || true) \
&& mkdir -m0755 -pv ~/.config/home-manager/ \
&& cd ~/.config/home-manager/ \
&& nix \
    --refresh \
    flake \
    init \
    --template \
    github:ES-nix/es#devShellHomeManagerFlakeUtilsNixOSVM \
&& (git --version \
|| nix profile install nixpkgs#git) \
&& git init \
&& git add . \
&& nix run github:nix-community/home-manager/f63d0fe9d81d36e5fc95497217a72e02b8b7bcab -- switch --flake '.#vagrant'
```
