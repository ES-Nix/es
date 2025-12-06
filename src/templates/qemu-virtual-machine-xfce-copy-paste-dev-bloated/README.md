

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose '.#'
```



Invoking in the host:
```bash
start
```


Or using with docker:
```bash
docker run -it --rm --publish=5000:5000 myapp-oci-image:0.0.1
```


Or using with podman:
```bash
podman run -it --rm --publish=5000:5000 localhost/myapp-oci-image:0.0.1
```


```bash
curl http://127.0.0.1:5000
firefox http://127.0.0.1:5000
```

TODO: missing checks that validate code formating, like black.


```bash
nix fmt . \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```



```bash
python -m myapp?
python -c 'import myapp?'
```


```bash
nix flake update '.#'
 ```

```bash
nix flake metadata '.#'
```

```bash
nix flake check '.#'
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
