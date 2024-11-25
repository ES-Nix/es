


```bash
nix flake metadata '.#'

rm -fv nixos.qcow2;
nix run --impure --refresh --verbose '.#'
```

TODO: make more similar to others flake templates?
```bash
nix flake show --impure '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths --impure '.#'

nix flake check --impure --verbose '.#'
```
