


```bash
nix flake metadata '.#'

rm -fv nixos.qcow2;
nix run --impure --refresh --verbose '.#'
```

```bash
nix flake show --impure '.#' \
&& nix flake metadata --impure '.#' \
&& nix build --impure --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop --impure '.#' --command sh -c 'true' \
&& nix flake check --impure --verbose '.#'
```
