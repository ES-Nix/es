


```bash
nix flake show '.#'

nix build --cores 5 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```
