

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#testNixOSBareDriverInteractive
```


```bash
nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```


### 

```bash
python3 --version \
&& python3 -m venv .venv \
&& source .venv/bin/activate \
&& python3 -m pip install numpy
```
