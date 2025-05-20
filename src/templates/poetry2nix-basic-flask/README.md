
poetry2nix-flask-nixos-tests

https://github.com/ALT-F4-LLC/example-nix-python

[How To Setup Nix Flakes](https://www.youtube.com/watch?v=oqXWrkvZ59g)


```bash
mkdir -pv poetry2nix-basic \
&& cd $_ \
&& nix \
flake \
init \
--template \
github:ES-nix/es#poetry2nixBasic
direnv allow || true
nix flake check '.#' --verbose
```


```bash
nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```

```bash
nix build --no-link --print-build-logs --print-out-paths '.#checks.x86_64-linux.test-nixos'
nix build --no-link --print-build-logs --print-out-paths '.#'
nix build --no-link --print-build-logs --print-out-paths '.#myappOCIImage'
nix run '.#'
nix develop '.#' --command python -c 'from app.main import start; start()'
```


```bash
nix flake init --template github:nix-community/poetry2nix
```
