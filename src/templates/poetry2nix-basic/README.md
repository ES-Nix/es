


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
nix build --print-build-logs --print-out-paths '.#'
nix build --print-build-logs --print-out-paths '.#myappOCIImage'
nix run '.#'
nix develop '.#' --command python -c 'from app.main import start; start()'
```


```bash
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
# nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#checks.x86_64-linux.testBinfmtMany'
```


```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/a5e4bbcb4780c63c79c87d29ea409abf097de3f7
```

```bash
nix flake init --template github:nix-community/poetry2nix
```

```bash
podman run --rm localhost/myapp-oci-image:0.0.1
```

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (system: {
        default = pkgs.${system}.poetry2nix.mkPoetryApplication { projectDir = self; };
      });

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShellNoCC {
          name = "poetry2nix-example-devShell";
          packages = with pkgs.${system}; [
            (poetry2nix.mkPoetryEnv { projectDir = self; })
            poetry
          ];
        };
      });

      apps = forAllSystems (system: {
        default = {
          program = "${self.packages.${system}.default}/bin/start";
          type = "app";
        };
      });
    };
}
```
