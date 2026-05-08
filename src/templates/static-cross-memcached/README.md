


```bash
nix run '.#allTests'
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
docker \
run \
--interactive=true \
--name=container-nix-flakes \
--tty=false \
--rm=true \
5f751996a1dc6924ba55b08962b9b301f441d7009aba6173b0ce648186b45450 \
sh \
<<'COMMANDS'
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
COMMANDS


docker \
run \
--interactive=true \
--name=container-nix-flakes2 \
--tty=false \
--rm=true \
5f751996a1dc6924ba55b08962b9b301f441d7009aba6173b0ce648186b45450 \
sh \
<<'COMMANDS'
PKGS=(
'pkgsCross.armv7l-hf-multiplatform.memcached'
'pkgsCross.aarch64-multiplatform.memcached'
'pkgsCross.gnu32.memcached'
'pkgsCross.gnu64.memcached'
'pkgsCross.ppc64.memcached'
'pkgsCross.raspberryPi.memcached'
'pkgsCross.riscv64.memcached'
'pkgsCross.s390x.memcached'
)

for p in "${PKGS[@]}";
do
    nix \
    build \
    --no-link \
    --print-out-paths \
    --override-flake \
    nixpkgs \
    github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852 \
    'nixpkgs#'$p
done
COMMANDS
```




```bash
docker \
run \
--interactive=true \
--name=container-nix-flakes2 \
--tty=true \
--rm=true \
5f751996a1dc6924ba55b08962b9b301f441d7009aba6173b0ce648186b45450 \
sh \
<<'COMMANDS'

# 'nixpkgs#pkgsStatic.readline' \
# 'nixpkgs#pkgsStatic.busybox-sandbox-shell' \
# 'nixpkgs#pkgsStatic.busybox' \
# 'nixpkgs#pkgsStatic.coreutils' \
# 'nixpkgs#pkgsStatic.openssl' \
# 'nixpkgs#pkgsStatic.sqlite' \
# 'nixpkgs#pkgsStatic.redis' \
# 'nixpkgs#pkgsStatic.valkey' \
# 'nixpkgs#pkgsStatic.bash' \
# 'nixpkgs#pkgsStatic.bashInteractive' \
# 'nixpkgs#pkgsStatic.zsh' \
# 'nixpkgs#pkgsStatic.nginx' \
# 'nixpkgs#pkgsStatic.uv' \
# 'nixpkgs#pkgsStatic.starship' \
# 'nixpkgs#pkgsStatic.nix' \
# 'nixpkgs#pkgsStatic.perl' \
# 'nixpkgs#pkgsStatic.su' \
# 'nixpkgs#pkgsStatic.xorg.xclock' \
# 'nixpkgs#pkgsStatic.python3' \
# 'nixpkgs#pkgsStatic.rustpython'
# \
# 'nixpkgs#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.memcached' \
# 'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.memcached' \
# 'nixpkgs#pkgsCross.gnu32.pkgsStatic.memcached' \
# 'nixpkgs#pkgsCross.gnu64.pkgsStatic.memcached' \
# 'nixpkgs#pkgsCross.ppc64.pkgsStatic.memcached' \
# 'nixpkgs#pkgsCross.raspberryPi.pkgsStatic.memcached' \
# 'nixpkgs#pkgsCross.riscv64.pkgsStatic.memcached' \
# 'nixpkgs#pkgsCross.s390x.pkgsStatic.memcached'
# \
# 'nixpkgs#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.sqlite' \
# 'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.sqlite' \
# 'nixpkgs#pkgsCross.gnu32.pkgsStatic.sqlite' \
# 'nixpkgs#pkgsCross.gnu64.pkgsStatic.sqlite' \
# 'nixpkgs#pkgsCross.ppc64.pkgsStatic.sqlite' \
# 'nixpkgs#pkgsCross.raspberryPi.pkgsStatic.sqlite' \
# 'nixpkgs#pkgsCross.riscv64.pkgsStatic.sqlite' \
# 'nixpkgs#pkgsCross.s390x.pkgsStatic.sqlite'
# \
# 'nixpkgs#pkgsCross.armv7l-hf-multiplatform.pkgsStatic.apk-tools' \
# 'nixpkgs#pkgsCross.aarch64-multiplatform.pkgsStatic.apk-tools' \
# 'nixpkgs#pkgsCross.gnu32.pkgsStatic.apk-tools' \
# 'nixpkgs#pkgsCross.gnu64.pkgsStatic.apk-tools' \
# 'nixpkgs#pkgsCross.ppc64.pkgsStatic.apk-tools' \
# 'nixpkgs#pkgsCross.raspberryPi.pkgsStatic.apk-tools' \
# 'nixpkgs#pkgsCross.riscv64.pkgsStatic.apk-tools' \
# 'nixpkgs#pkgsCross.s390x.pkgsStatic.apk-tools'
# nixpkgs#apk-tools \
# nixpkgs#apt \
# nixpkgs#dnf5 \
# nixpkgs#dpkg \
# nixpkgs#pacman \
# nixpkgs#rpm \
# nixpkgs#xbps \

# 'nixpkgs#pkgsStatic.sudo' \
# 'nixpkgs#pkgsStatic.qemu-user' \
# 'nixpkgs#pkgsStatic.tini' \
# 'nixpkgs#pkgsStatic.python3Minimal' \
# 'nixpkgs#pkgsStatic.memcached' \


PKGS=(
pkgsStatic.readline
pkgsStatic.busybox-sandbox-shell
pkgsStatic.busybox
pkgsStatic.coreutils
pkgsStatic.openssl
pkgsStatic.sqlite
pkgsStatic.redis
pkgsStatic.valkey
pkgsStatic.bash
pkgsStatic.bashInteractive
pkgsStatic.zsh
pkgsStatic.nginx
pkgsStatic.uv
pkgsStatic.starship
pkgsStatic.nix
pkgsStatic.perl
pkgsStatic.su
pkgsStatic.xorg.xclock
pkgsStatic.python3
pkgsStatic.rustpython
)

for p in "${PKGS[@]}";
do
    nix \
    build \
    --no-link \
    --print-build-logs \
    --print-out-paths \
    --override-flake \
    nixpkgs \
    github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852 \
    'nixpkgs#'$p
done

COMMANDS
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
