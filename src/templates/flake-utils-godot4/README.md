

```bash
git clone --branch main --single-branch https://github.com/PedroRegisPOAR/TopDownShooter.git \
&& cd TopDownShooter \
&& git checkout b703e8a15f69fb78480328084f2b8d718417e240 \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#flakesUtilsGodot4 \
&& git add . \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --impure --no-link --print-build-logs --print-out-paths '.#' \
&& nix flake check --impure --verbose '.#' \
&& nix develop --impure '.#' --command true \
&& nix develop --impure '.#' --command nixGL godot4 --rendering-driver opengl3
```
Refs.:
- https://godot-rust.github.io/gdnative-book/recipes/nix-build-system.html





```bash
# git clone --branch main --single-branch --depth=1 https://github.com/PedroRegisPOAR/TopDownShooter.git
git config --global http.postBuffer 524288000 # Set buffer size to 500 MB
git config --global http.lowSpeedLimit 0      # Disable low speed limit
git config --global http.lowSpeedTime 999999  # Set low speed time limit to a large value
```
Refs.:
- https://stackoverflow.com/a/77999795
- https://github.com/orgs/community/discussions/48568#discussioncomment-9998178


```bash
git add .
```

```bash
nix develop --impure '.#' --command nixGL godot4 --rendering-driver opengl3
```


```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/alpine:3.21.2 as alpine-with-ca-certificates-tzdata

# https://stackoverflow.com/a/69918107
# https://serverfault.com/a/1133538
# https://wiki.alpinelinux.org/wiki/Setting_the_timezone
# https://bobcares.com/blog/change-time-in-docker-container/
# https://github.com/containers/podman/issues/9450#issuecomment-783597549
# https://www.redhat.com/sysadmin/tick-tock-container-time
ENV TZ=America/Recife

RUN apk update \
 && apk \
    add \
    --no-cache \
    ca-certificates \
    tzdata \
    shadow \
 && mkdir -pv /home/nixuser \
 && groupmod ping --gid 998 \
 && addgroup nixgroup --gid 999 \
 && adduser \
    -g '"An unprivileged user with an group"' \
    -D \
    -h /home/nixuser \
    -G nixgroup \
    -u 1234 \
    nixuser \
 && echo \
 && echo 'Start kvm stuff...' \
 && getent group kvm || groupadd kvm \
 && usermod --append --groups kvm nixuser \
 && echo 'End kvm stuff!' \
 && echo 'Start tzdata stuff' \
 && (test -d /etc || mkdir -pv /etc) \
 && cp -v /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && apk del tzdata shadow \
 && echo 'End tzdata stuff!' 

# sudo sh -c 'mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'
RUN mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv nixuser:nixgroup /nix

USER nixuser
WORKDIR /home/nixuser
ENV USER="nixuser"

RUN CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
 && $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/278148689/download-by-type/file/binary-dist > nix \
 && chmod -v +x nix \
 && ./nix --version \
 && echo \
 && ./nix \
         --extra-experimental-features nix-command \
         --extra-experimental-features flakes \
         --extra-experimental-features auto-allocate-uids \
         profile \
         install \
         github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0#nixVersions.nix_2_26 \
 && rm -v ./nix \
 && mkdir -pv "$HOME"/.config/nix \
 && grep 'experimental-features' "$HOME"/.config/nix/nix.conf -q &> /dev/null || (echo 'experimental-features = nix-command flakes' >> "$HOME"/.config/nix/nix.conf) \
 && grep 'nix-profile' "$HOME"/.profile -q  &> /dev/null || (echo 'export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"' >> "$HOME"/.profile) \
 && . "$HOME"/.profile \
 && nix flake --version \
 && nix \
    store \
    gc \
    --verbose \
    --option keep-build-log false \
    --option keep-derivations false \
    --option keep-env-derivations false \
    --option keep-failed false \
    --option keep-going false \
    --option keep-outputs false \
 && nix-collect-garbage --delete-old \
 && nix store optimise --verbose \
 && nix \
      registry \
      pin \
      nixpkgs github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0 \
 && nix flake metadata nixpkgs

EOF

podman \
build \
--cap-add=SYS_ADMIN \
--tag alpine-with-ca-certificates-tzdata \
--target alpine-with-ca-certificates-tzdata \
. \
&& podman kill container-alpine-with-ca-certificates-tzdata &> /dev/null || true \
&& podman rm --force container-alpine-with-ca-certificates-tzdata || true \
&& podman \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--tty=true \
--rm=true \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh -cl 'nix flake metadata nixpkgs'

xhost + || nix run nixpkgs#xorg.xhost -- +
podman \
run \
--device=/dev/kvm:rw \
--device=/dev/dri:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--userns=keep-id \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--tty=true \
--rm=true \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume=/etc/localtime:/etc/localtime:ro \
--volume="$(pwd)":/home/nixuser/code:rw \
--workdir=/home/nixuser/code \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh -l

xhost + || nix run nixpkgs#xorg.xhost -- +
podman \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--device=/dev/dri:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--group-add=keep-groups \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=false \
--tty=true \
--rm=true \
--userns=keep-id \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume="$(pwd)":/home/nixuser/code:rw \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh -cl 'touch /home/nixuser/code && nix run nixpkgs#xorg.xclock'
```
Refs.:
- 


Why NixOS does not have `/etc/localtime`? 
So the volume `--volume=/etc/localtime:/etc/localtime:ro` just breaks!?!


```bash
podman \
run \
--group-add=keep-groups \
--privileged=false \
--rm=true \
--userns=keep-id \
--volume="$(pwd)":/home/nixuser/code:rw \
busybox \
sh -cl 'id'
```



```bash
xhost + || nix run nixpkgs#xorg.xhost -- +
podman \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--device /dev/dri:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--security-opt seccomp=unconfined \
--shm-size=2G \
--tty=true \
--rm=true \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume=/etc/localtime:/etc/localtime:ro \
--volume="$(pwd)":/home/nixuser/code:rw \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh -l
```






```bash
cat > Dockerfile << 'EOF'
FROM docker.io/library/alpine:3.21.2 AS alpine-with-ca-certificates-tzdata

# https://stackoverflow.com/a/69918107
# https://serverfault.com/a/1133538
# https://wiki.alpinelinux.org/wiki/Setting_the_timezone
# https://bobcares.com/blog/change-time-in-docker-container/
# https://github.com/containers/podman/issues/9450#issuecomment-783597549
# https://www.redhat.com/sysadmin/tick-tock-container-time
ENV TZ=America/Recife

RUN apk update \
 && apk \
    add \
    --no-cache \
    ca-certificates \
    tzdata \
    shadow \
 && mkdir -pv /home/nixuser \
 && groupmod ping --gid 998 \
 && addgroup nixgroup --gid 999 \
 && adduser \
    -g '"An unprivileged user with an group"' \
    -D \
    -h /home/nixuser \
    -G nixgroup \
    -u 1234 \
    nixuser \
 && echo \
 && echo 'Start kvm stuff...' \
 && getent group kvm || groupadd kvm \
 && usermod --append --groups kvm nixuser \
 && echo 'End kvm stuff!' \
 && echo 'Start tzdata stuff' \
 && (test -d /etc || mkdir -pv /etc) \
 && cp -v /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && apk del tzdata shadow \
 && echo 'End tzdata stuff!' 

# sudo sh -c 'mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'
RUN mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv nixuser:nixgroup /nix

USER nixuser
WORKDIR /home/nixuser
ENV USER="nixuser"

RUN CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
 && $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/278148689/download-by-type/file/binary-dist > nix \
 && chmod -v +x nix \
 && ./nix --version \
 && echo \
 && ./nix \
         --extra-experimental-features nix-command \
         --extra-experimental-features flakes \
         --extra-experimental-features auto-allocate-uids \
         profile \
         install \
         github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0#nixVersions.nix_2_26 \
 && rm -v ./nix \
 && mkdir -pv "$HOME"/.config/nix \
 && grep 'experimental-features' "$HOME"/.config/nix/nix.conf -q &> /dev/null || (echo 'experimental-features = nix-command flakes' >> "$HOME"/.config/nix/nix.conf) \
 && grep 'nix-profile' "$HOME"/.profile -q  &> /dev/null || (echo 'export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"' >> "$HOME"/.profile) \
 && . "$HOME"/.profile \
 && nix flake --version \
 && nix \
    store \
    gc \
    --verbose \
    --option keep-build-log false \
    --option keep-derivations false \
    --option keep-env-derivations false \
    --option keep-failed false \
    --option keep-going false \
    --option keep-outputs false \
 && nix-collect-garbage --delete-old \
 && nix store optimise --verbose \
 && nix \
      registry \
      pin \
      nixpkgs github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0 \
 && nix flake metadata nixpkgs

EOF

docker \
build \
--tag alpine-with-ca-certificates-tzdata \
--target alpine-with-ca-certificates-tzdata \
. \
&& docker kill container-alpine-with-ca-certificates-tzdata &> /dev/null || true \
&& docker rm --force container-alpine-with-ca-certificates-tzdata || true \
&& docker \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--tty=true \
--rm=true \
docker.io/library/alpine-with-ca-certificates-tzdata:latest \
sh -cl 'nix flake metadata nixpkgs'

xhost + || nix run nixpkgs#xorg.xhost -- +
docker \
run \
--device=/dev/kvm:rw \
--device=/dev/dri:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--tty=true \
--rm=true \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume=/etc/localtime:/etc/localtime:ro \
--volume="$(pwd)":/home/nixuser/code:rw \
--workdir=/home/nixuser/code \
docker.io/library/alpine-with-ca-certificates-tzdata:latest \
sh -l

xhost + || nix run nixpkgs#xorg.xhost -- +
docker \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--device=/dev/dri:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=false \
--tty=true \
--rm=true \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume="$(pwd)":/home/nixuser/code:rw \
docker.io/library/alpine-with-ca-certificates-tzdata:latest \
sh -cl 'touch /home/nixuser/code && nix run nixpkgs#xorg.xclock'
```
Refs.:
- 


Why NixOS does not have `/etc/localtime`? 
So the volume `--volume=/etc/localtime:/etc/localtime:ro` just breaks!?!


```bash
podman \
run \
--group-add=keep-groups \
--privileged=false \
--rm=true \
--userns=keep-id \
--volume="$(pwd)":/home/nixuser/code:rw \
busybox \
sh -cl 'id'
```



```bash
xhost + || nix run nixpkgs#xorg.xhost -- +
podman \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--device /dev/dri:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--security-opt seccomp=unconfined \
--shm-size=2G \
--tty=true \
--rm=true \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume=/etc/localtime:/etc/localtime:ro \
--volume="$(pwd)":/home/nixuser/code:rw \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh -l
```
