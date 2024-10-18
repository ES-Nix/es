


```bash
nix flake show '.#'
nix flake metadata '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'
nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#' --rebuild

nix fmt '.#'

# nix flake check --verbose '.#'
```


```bash
docker run --privileged --rm tonistiigi/binfmt --install aarch64
docker run --rm --platform linux/aarch64 alpine:3.20.3 uname -m
```


```bash
docker run --platform linux/386 --rm i386/alpine uname -a
docker run --platform linux/amd64 --rm amd64/alpine uname -a
docker run --platform linux/arm --rm arm32v6/alpine uname -a
docker run --platform linux/arm --rm arm32v7/alpine uname -a
docker run --platform linux/arm64 --rm arm64v8/alpine uname -a
docker run --platform linux/ppc64le --rm ppc64le/alpine uname -a
docker run --platform linux/riscv64 --rm riscv64/alpine uname -a
docker run --platform linux/s390x --rm s390x/alpine uname -a
```

```bash
docker run -it --platform linux/mips64le --rm mips64le/busybox:1.36.1-glibc uname -a
```



```bash
python -c "import sys; print(sys.byteorder)"
python -c "import sysconfig; print(sysconfig.get_platform())"
```
Refs.:
- https://serverfault.com/a/599012


TODO: pax-utils see scanelf results
```bash
ldd $(readlink -f $(which hello))
file $(readlink -f $(which hello))
readelf -h $(readlink -f $(which hello))
objdump -a  $(readlink -f $(which hello))
xxd -c 5 -l 6 $(readlink -f $(which hello))
hexdump -s 5 -n 1 $(readlink -f $(which hello))
```

```bash
gcc -E -dM - <<< '#include <endian.h>' |  grep BYTE_ORDER
```
Refs.:
- https://unix.stackexchange.com/questions/88934/is-there-a-system-command-in-linux-that-reports-the-endianness#comment1451184_122862


```bash
nix eval --json --apply 'builtins.attrNames' 'nixpkgs#pkgsCross' | jq .
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
'nixpkgs#pkgsCross.aarch64-multiplatform.toybox' \
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.toybox' \
'nixpkgs#pkgsCross.gnu32.toybox' \
'nixpkgs#pkgsCross.gnu64.toybox' \
'nixpkgs#pkgsCross.ppc64.toybox' \
'nixpkgs#pkgsCross.raspberryPi.toybox' \
'nixpkgs#pkgsCross.riscv32.toybox' \
'nixpkgs#pkgsCross.riscv64.toybox' \
'nixpkgs#pkgsCross.s390x.toybox'
```


```bash
nix \
build \
--cores 7 \
--no-link \
--print-build-logs \
--print-out-paths \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343 \
\
'nixpkgs#pkgsCross.aarch64-multiplatform.hello.out' \
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.hello.out' \
'nixpkgs#pkgsCross.gnu32.hello.out' \
'nixpkgs#pkgsCross.gnu64.hello.out' \
'nixpkgs#pkgsCross.mingw32.hello.out' \
'nixpkgs#pkgsCross.mingwW64.hello.out' \
'nixpkgs#pkgsCross.mips64el-linux-gnuabin32.hello.out' \
'nixpkgs#pkgsCross.mips64el-linux-gnuabi64.hello.out' \
'nixpkgs#pkgsCross.ppc64.hello.out' \
'nixpkgs#pkgsCross.raspberryPi.hello.out' \
'nixpkgs#pkgsCross.riscv32.hello.out' \
'nixpkgs#pkgsCross.riscv64.hello.out' \
'nixpkgs#pkgsCross.s390x.hello.out'
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
'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.hello' \
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.hello' \
'nixpkgs#pkgsCross.gnu32.pkgsStatic.hello' \
'nixpkgs#pkgsCross.gnu64.pkgsStatic.hello' \
'nixpkgs#pkgsCross.ppc64.pkgsStatic.hello' \
'nixpkgs#pkgsCross.raspberryPi.pkgsStatic.hello' \
'nixpkgs#pkgsCross.riscv64.pkgsStatic.hello' \
'nixpkgs#pkgsCross.s390x.pkgsStatic.hello'

# 'nixpkgs#pkgsCross.riscv32.pkgsStatic.hello' \
```


```bash
nix \
build \
--cores 7 \
--no-link \
--print-build-logs \
--print-out-paths \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343 \
\
'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.gnu32.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.gnu64.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.mips64el-linux-gnuabin32.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.mips64el-linux-gnuabi64.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.ppc64.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.raspberryPi.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.riscv32.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.riscv64.pkgsStatic.sqlite.out' \
'nixpkgs#pkgsCross.s390x.pkgsStatic.sqlite.out'
```





```bash
nix eval --json 'github:NixOS/nixpks/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06#virtualbox.meta.platforms' | jq
nix eval --json 'github:NixOS/nixpks/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06#python3.meta.platforms' | jq
nix eval --json 'github:NixOS/nixpks/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06#nodejs.meta.platforms' | jq
nix eval --json 'github:NixOS/nixpks/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06#qemu.meta.platforms' | jq

nix eval --json 'github:NixOS/nixpks/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06#pkgsStatic.python3.meta.platforms' | jq
nix eval --json 'github:NixOS/nixpks/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06#pkgsStatic.nodejs.meta.platforms' | jq
```



TODO: how to make it work?
```bash
echo ':DOSWin:M::MZ::/usr/local/bin/wine:' > register
```
Refs.:
- https://docs.kernel.org/admin-guide/binfmt-misc.html

```nix
x86_64-windows.magicOrExtension = "MZ";
```
Refs.:
- https://github.com/NixOS/nixpkgs/blob/23cbb250f3bf4f516a2d0bf03c51a30900848075/nixos/modules/system/boot/binfmt.nix#L144






TODO: use that in an flake
```bash
nix run github:emmanuelrosa/erosanix//df435beac4a196101c8eb961a6286c09433dd491#foobar2000
```
Refs.:
- https://discourse.nixos.org/t/using-wine-installing-foobar2000/17870/4


TODO: Test it with pkgsMusl and/or pkgsStatic
```bash
hello
pypy
rustpython
python3Minimal
python3
python3Full


graphviz
nodejs
nodejs-slim
bun
deno

gosu
tini
dumb-init
su-exec

bash
bashInteractive
busybox
coreutils
file
fish
gcc
git
gitMinimal
goawk
gnuawk
gnugrep
gnumake
cmake
hello
hexdump
inetutils
minio
objdump 
patchelf
readelf 
ripgrep
starship
busybox
toybox
tree
uutils-coreutils
which
util-linux
findutils
sqlite
sudo
sudo-rs
pax-utils
xorg.xclock
zsh
```
