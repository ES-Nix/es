

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
&& nix run '.#allTests' \
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



## Docker


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
    curl \
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
 && { getent group kvm || groupadd kvm; } \
 && usermod --append --groups kvm nixuser \
 && echo 'End kvm stuff!' \
 && echo 'Start tzdata stuff' \
 && (test -d /etc || mkdir -pv /etc) \
 && cp -v /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && apk del tzdata \
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
cat > Dockerfile << 'EOF'
FROM docker.io/library/alpine:3.21.2

RUN echo 'Creating user and group' \
 && addgroup abcgroup \
 && adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh \
 && echo abcuser:10000:5000 > /etc/subuid \
 && echo abcuser:10000:5000 > /etc/subgid \
 && echo 'User and group created!'

USER abcuser
WORKDIR /home/abcuser
EOF

docker \
build \
--file=Containerfile \
--tag=unprivileged-alpine .


docker \
run \
--interactive=true \
--network=none \
--tty=true \
--rm=true \
--volume="$(pwd)":/code:rw \
--workdir=/code \
unprivileged-alpine
```

```bash
env | sort
su -l abcuser -c id
su -l abcuser -c sh -c 'env | sort'

docker rm container-alpine -f
docker \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--hostname=container-alpine \
--interactive=true \
--name=container-alpine \
--network=host \
--privileged=true \
--tty=false \
--rm=false \
--volume="$(pwd)":/home/abcuser/code:ro \
docker.io/library/alpine:3.23.2 \
sh <<'COMMANDS'
echo 'Creating user and group' \
&& addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh \
&& echo abcuser:10000:5000 > /etc/subuid \
&& echo abcuser:10000:5000 > /etc/subgid \
&& echo 'User and group created!'

su -l abcuser -c sh -c \
'
./code/nix --extra-experimental-features nix-command --extra-experimental-features flakes run nixpkgs#hello
'
COMMANDS

docker diff container-alpine
docker rm container-alpine -f

getent group kvm \
&& groupmod -g $(stat -c '%g' /dev/kvm) kvm \
&& getent group kvm \
&& chown -v 1234:999 /dev/kvm \
&& touch /dev/kvm
```

```bash
docker \
run \
--hostname=container-nix-flakes \
--interactive=true \
--name=container-nix-flakes \
--tty=false \
--rm=false \
docker.io/nixpkgs/nix-flakes \
sh <<'COMMANDS'
nix run github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852#pkgsStatic.nix -- run github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852#hello
COMMANDS

docker diff container-nix-flakes

docker rm container-nix-flakes


docker \
run \
--hostname=container-nix-flakes \
--interactive=true \
--name=container-nix-flakes \
--tty=true \
--rm=true \
--volume="$(pwd)":/home/abcuser/code:ro \
docker.io/nixpkgs/nix-flakes 
```



```bash
docker \
run \
--security-opt seccomp=unconfined \
--interactive=true \
--platform linux/arm64 \
--privileged=true \
--rm=true \
--tty=false \
docker.io/library/alpine:3.23.2 \
sh <<'COMMANDS'
uname -a
addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh

apk add --no-cache curl

su -l abcuser -c sh -c \
'
curl -L https://hydra.nixos.org/build/312837149/download-by-type/file/binary-dist > nix \
&& chmod +x nix \
&& ./nix --version

./nix --extra-experimental-features nix-command --extra-experimental-features flakes run nixpkgs#hello
'
COMMANDS


docker \
run \
--interactive=true \
--platform linux/amd64 \
--privileged=true \
--rm=true \
--tty=false \
docker.io/library/alpine:3.23.2 \
sh <<'COMMANDS'
uname -a
addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh

apk add --no-cache curl

su -l abcuser -c sh -c \
'
curl -L https://hydra.nixos.org/build/313290523/download-by-type/file/binary-dist > nix \
&& chmod +x nix \
&& ./nix --version

./nix --extra-experimental-features nix-command --extra-experimental-features flakes run nixpkgs#hello
'
COMMANDS
```



```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/ubuntu:24.04

RUN apt-get update -y \
 && apt-get install --assume-yes --no-install-recommends --no-install-suggests \
     adduser \
     ca-certificates \
     curl \
     file \
 && apt-get -y autoremove \
 && apt-get -y clean \
 && rm -rf /var/lib/apt/lists/*

RUN addgroup abcgroup --gid 4455  \
 && adduser -q \
     --gecos '"An unprivileged user with an group"' \
     --disabled-password \
     --ingroup abcgroup \
     --uid 3322 \
     abcuser

# If is added nix statically compiled works!
# RUN mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv abcuser:abcgroup /nix

USER abcuser
WORKDIR /home/abcuser
ENV USER="abcuser"
ENV PATH=/home/abcuser/.nix-profile/bin:/home/abcuser/.local/bin:"$PATH"
ENV NIX_CONFIG="extra-experimental-features = nix-command flakes"

RUN mkdir -pv "$HOME"/.local/bin \
 && cd "$HOME"/.local/bin \
 && curl -L https://hydra.nixos.org/build/316101186/download-by-type/file/binary-dist > nix \
 && chmod -v +x nix
EOF


podman \
build \
--file=Containerfile \
--tag=unprivileged-ubuntu24 .

podman \
run \
--interactive=true \
--tty=true \
--rm=true \
localhost/unprivileged-ubuntu24:latest \
bash \
-c \
'
# Works
nix flake --version
nix run nixpkgs#hello

# Broken
nix profile add nixpkgs#hello
file ~/.nix-profile
ls -Alh ~/.local/share/nix/root/nix/var/nix/profiles/per-user/
hello
'
```


```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/ubuntu:24.04

RUN apt-get update -y \
 && apt-get install --assume-yes --no-install-recommends --no-install-suggests \
     adduser \
     ca-certificates \
     curl \
     file \
 && apt-get -y autoremove \
 && apt-get -y clean \
 && rm -rf /var/lib/apt/lists/*

# RUN addgroup abcgroup --gid 4455  \
#  && adduser -q \
#      --gecos '"An unprivileged user with an group"' \
#      --disabled-password \
#      --ingroup abcgroup \
#      --uid 3322 \
#      abcuser

# If is added nix statically compiled works!
RUN mkdir -pv /nix/var/nix && chmod -v 1735 /nix && chown -Rv ubuntu:ubuntu /nix

USER ubuntu
WORKDIR /home/ubuntu
ENV USER="ubuntu"
ENV PATH=/home/ubuntu/.nix-profile/bin:/home/ubuntu/.local/bin:"$PATH"
ENV NIX_CONFIG="extra-experimental-features = nix-command flakes"

RUN cd /home/ubuntu \
 && ls -alh \
 && curl -L https://raw.githubusercontent.com/PedroRegisPOAR/dotfiles/main/bootstrap.sh > bootstrap.sh \
 && chmod +x bootstrap.sh \
 && ./bootstrap.sh

# RUN mkdir -pv "$HOME"/.local/bin \
#  && cd "$HOME"/.local/bin \
#  && curl -L https://hydra.nixos.org/build/316101186/download-by-type/file/binary-dist > nix \
#  && chmod -v +x nix
EOF

docker \
build \
--file=Containerfile \
--tag=unprivileged-ubuntu24 .

docker \
run \
--device=/dev/kvm:rw \
--interactive=true \
--tty=true \
--rm=true \
unprivileged-ubuntu24:latest \
bash \
-c \
'
# Works
nix flake --version
nix run nixpkgs#hello

# Broken
nix profile add nixpkgs#hello
file ~/.nix-profile
ls -Alh ~/.local/share/nix/root/nix/var/nix/profiles/per-user/
hello
'
```




docker \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=false \
--tty=false \
--rm=true \
--volume="$(pwd)":/home/abcuser/.local/bin:ro \
docker.io/library/alpine:3.21.2 \
sh <<'COMMANDS'
echo 'Creating user and group' \
&& addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh \
&& echo abcuser:10000:5000 > /etc/subuid \
&& echo abcuser:10000:5000 > /etc/subgid \
&& echo 'User and group created!'

su -l abcuser -c sh -c './code/nix --extra-experimental-features nix-command --extra-experimental-features flakes run nixpkgs#hello'
COMMANDS


docker \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--hostname=container-nix \
--interactive=true \
--name=container-alpine-with-ca-certificates-tzdata \
--privileged=true \
--tty=false \
--rm=true \
--volume="$(pwd)":/home/abcuser/.local/bin:ro \
docker.io/library/alpine:3.21.2 \
sh <<'COMMANDS'
echo 'Creating user and group' \
&& addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh \
&& echo abcuser:10000:5000 > /etc/subuid \
&& echo abcuser:10000:5000 > /etc/subgid \
&& echo 'User and group created!'

su -l abcuser -c sh -c \
'
export PATH=~/.nix-profile/bin:~/.local/bin:"$PATH"
nix --version
# nix --extra-experimental-features nix-command --extra-experimental-features flakes run nixpkgs#hello
'
COMMANDS




docker \
run \
--interactive=true \
--privileged=true \
--tty=false \
--rm=true \
--volume="$(pwd)":/home/abcuser/code:ro \
docker.io/library/alpine:3.21.2 \
sh <<'COMMANDS'
addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh

su -l abcuser -c sh -c \
'
export PATH=~/.nix-profile/bin:~/code:"$PATH"
nix --extra-experimental-features nix-command --extra-experimental-features flakes run nixpkgs#hello
'
COMMANDS


docker \
run \
--interactive=true \
--name=container-alpine \
--privileged=true \
--tty=false \
--rm=true \
--volume="$(pwd)":/home/abcuser/.local/bin:ro \
docker.io/library/alpine:3.21.2 \
sh <<'COMMANDS'
addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh

su -l abcuser -c sh -c \
'
~/.local/bin/nix --extra-experimental-features nix-command --extra-experimental-features flakes run nixpkgs#hello
'
COMMANDS


docker \
run \
--interactive=true \
--name=container-alpine \
--privileged=true \
--tty=false \
--rm=true \
docker.io/library/alpine:3.21.2 \
sh <<'COMMANDS'
addgroup abcgroup \
&& adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh
apk add --no-cache curl
su -l abcuser -c sh -c \
'
curl -L https://raw.githubusercontent.com/PedroRegisPOAR/dotfiles/main/bootstrap-unprivileged.sh | "$SHELL"
'
COMMANDS
