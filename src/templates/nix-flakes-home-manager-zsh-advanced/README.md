

```bash
mkdir hm-template \
&& cd $_ \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#nixFlakesHomeManagerZshAdvanced \
--verbose

git init && git add .

nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
--override-input nixpkgs-unstable github:NixOS/nixpkgs/a76c4553d7e741e17f289224eda135423de0491d \
--override-input home-manager github:nix-community/home-manager/f33900124c23c4eca5831b9b5eb32ea5894375ce

home-manager switch --flake .#$USER
```
Refs.:
- https://github.com/Misterio77/nix-starter-configs/issues/3#issuecomment-1312809082
- https://github.com/nix-community/home-manager/issues/2942#issuecomment-1378627909


```bash
nix fmt \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#' \
&& git add .
```
