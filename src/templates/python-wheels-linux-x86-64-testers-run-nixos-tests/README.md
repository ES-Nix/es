


```bash
nix flake show '.#'
nix flake metadata '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'
nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#' --rebuild

nix fmt '.#'

# nix flake check --verbose '.#'
```



```bash
nix \
build \
--impure \
--no-link \
--print-build-logs \
--print-out-paths \
--expr \
'
  (
      let
        nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06");
        pkgs = import nixpkgs { };    
      in
        with pkgs;[

          (python3.withPackages (pyPkgs: with pyPkgs; [

                                     ]
                          )
                        )
    ]
  )
'
```

Refs.:
- https://pythonwheels.com/
- https://mayeut.github.io/manylinux-timeline/




