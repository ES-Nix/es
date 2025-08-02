



```bash
nix fmt . \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```



```bash
file $(readlink -f $(which hello))
readelf -h $(readlink -f $(which hello))
objdump -a  $(readlink -f $(which hello))
```


```bash
nix eval --json --apply 'builtins.attrNames' 'nixpkgs#pkgsCross' | jq .
```




```bash
# nix build --cores 7 --no-link --print-build-logs --print-out-paths \
# 'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.i686-embedded.hello'
#
# nix build --cores 7 --no-link --print-build-logs --print-out-paths \
# 'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.riscv64-embedded.hello'
#
# nix build --cores 7 --no-link --print-build-logs --print-out-paths \
# 'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.ppcle-embedded.hello'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.armv7l-hf-multiplatform.hello'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.aarch64-multiplatform.hello'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.ppc64.hello'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.s390x.hello'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.riscv64.hello'
```




```bash
nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.armv7l-hf-multiplatform.toybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.aarch64-multiplatform.toybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.ppc64.toybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.s390x.toybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.riscv64.toybox'
```



```bash
nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.armv7l-hf-multiplatform.busybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.aarch64-multiplatform.busybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.ppc64.busybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.s390x.busybox'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.riscv64.busybox'
```


```bash
nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.memcached'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.aarch64-multiplatform.pkgsStatic.memcached'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.ppc64.pkgsStatic.memcached'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.s390x.pkgsStatic.memcached'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.riscv64.pkgsStatic.memcached'
```

```bash
nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.redis'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.aarch64-multiplatform.pkgsStatic.redis'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.ppc64.pkgsStatic.redis'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.s390x.pkgsStatic.redis'

nix build --cores 7 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343#pkgsCross.riscv64.pkgsStatic.redis'
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
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.hello' \
'nixpkgs#pkgsCross.aarch64-multiplatform.hello' \
'nixpkgs#pkgsCross.ppc64.hello' \
'nixpkgs#pkgsCross.s390x.hello' \
'nixpkgs#pkgsCross.riscv64.hello' \
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.hello' \
'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.hello' \
'nixpkgs#pkgsCross.ppc64.pkgsStatic.hello' \
'nixpkgs#pkgsCross.s390x.pkgsStatic.hello' \
'nixpkgs#pkgsCross.riscv64.pkgsStatic.hello' \
'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.redis' \
'nixpkgs#pkgsCross.ppc64.pkgsStatic.redis' \
'nixpkgs#pkgsCross.s390x.pkgsStatic.redis' \
'nixpkgs#pkgsCross.riscv64.pkgsStatic.redis' \
'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.memcached' \
'nixpkgs#pkgsCross.ppc64.pkgsStatic.memcached' \
'nixpkgs#pkgsCross.s390x.pkgsStatic.memcached' \
'nixpkgs#pkgsCross.riscv64.pkgsStatic.memcached' \
'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.valkey' \
'nixpkgs#pkgsCross.ppc64.pkgsStatic.valkey' \
'nixpkgs#pkgsCross.s390x.pkgsStatic.valkey' \
'nixpkgs#pkgsCross.riscv64.pkgsStatic.valkey'
```


TODO: 
```bash
        pkgs.pkgsStatic.toybox.overrideAttrs 
          (oldAttrs: 
            {
              hardeningDisable = [ "fortify" ]; 
              buildPhase = "make clean && make sh";
              installPhase = "rm -frv $out && mkdir -pv $out/bin && cp -v sh $out/bin";
            }
          )
```





