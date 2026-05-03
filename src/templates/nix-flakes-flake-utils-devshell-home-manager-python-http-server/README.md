
```bash
rm -frv ~/.config/home-manager/
```


```bash
mkdir -pv devShellHomeManagerFlakeUtilsPython3HttpServer \
&& cd devShellHomeManagerFlakeUtilsPython3HttpServer \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHomeManagerFlakeUtilsPython3HttpServer

git --version || nix profile install nixpkgs#git
git init && git add .

nix run github:nix-community/home-manager/release-25.11 -- switch --flake '.#vagrant'
# home-manager switch --flake '.#vagrant'
```
Refs.:
- 
