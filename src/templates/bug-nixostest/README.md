
bug-nixostest

```bash
nix flake show '.#'
nix flake metadata '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'
nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#' --rebuild

nix fmt '.#'
```


