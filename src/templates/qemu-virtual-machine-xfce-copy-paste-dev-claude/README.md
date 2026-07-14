

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose '.#'
```


```bash
nix fmt . \
&& nix flake show --all-systems '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```


TODO:
```bash
echo aaaqqq > /tmp/xchg/f00.txt

cat "$(ls -td /tmp/nix-vm.* | head -n1)/xchg/f00"
```


```bash
git clone https://github.com/torvalds/linux.git \
&& cd linux \
&& git checkout 38fec10eb60d687e30c8c6b5420d86e8149f7557 \
&& ls -alh

nix \
shell \
github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0#ncurses

make menuconfig
make
```
