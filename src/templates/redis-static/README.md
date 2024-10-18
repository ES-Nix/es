





```bash
nix flake show '.#'

nix build --cores 5 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```





```bash
nix \
build \
--cores 3 \
--no-link \
--print-build-logs \
--print-out-paths \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343 \
'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.redis' \
'nixpkgs#pkgsCross.gnu32.pkgsStatic.redis' \
'nixpkgs#pkgsCross.gnu64.pkgsStatic.redis' \
'nixpkgs#pkgsCross.ppc64.pkgsStatic.redis' \
'nixpkgs#pkgsCross.mips64el-linux-gnuabi64.pkgsStatic.redis' \
'nixpkgs#pkgsCross.riscv64.pkgsStatic.redis' \
'nixpkgs#pkgsCross.s390x.pkgsStatic.redis'
```