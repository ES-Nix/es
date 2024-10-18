


```bash
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

# nix flake check --verbose '.#'
nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#checks.x86_64-linux.testBinfmtMany'
```





Broken!
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
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.memcached' \
'nixpkgs#pkgsCross.raspberryPi.pkgsStatic.memcached'
```



Works!
```bash
nix \
build \
--cores 8 \
--no-link \
--print-build-logs \
--print-out-paths \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343 \
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.memcached' \
'nixpkgs#pkgsCross.aarch64-multiplatform.memcached' \
'nixpkgs#pkgsCross.gnu32.memcached' \
'nixpkgs#pkgsCross.gnu64.memcached' \
'nixpkgs#pkgsCross.ppc64.memcached' \
'nixpkgs#pkgsCross.raspberryPi.memcached' \
'nixpkgs#pkgsCross.riscv64.memcached' \
'nixpkgs#pkgsCross.s390x.memcached'
```


TODO: add it or something like this to an test
```bash
docker run --name=container-memcached -d --rm -p=11211:11211 memcached:static-x86_64

docker \
run \
--rm \
-i \
-t \
--name debugger \
--pid container:container-memcached \
--network container:container-memcached \
alpine \
sh \
-c \
'ps'
```
Refs.:
- https://iximiuz.com/en/posts/docker-debug-slim-containers/
