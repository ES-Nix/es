

```bash
nix flake show '.#'

nix build --cores 7 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```
