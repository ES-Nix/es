
bug-nixostest

```bash
nix fmt . \
&& nix flake show --all-systems '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' --rebuild \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```


