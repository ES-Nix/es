

```bash
nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```

```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

curl -L https://hydra.nixos.org/build/297111184/download-by-type/file/binary-dist -o nix

# Not a must:
echo 7838348c0e560855921cfa97051161bd63e29ee7ef4111eedc77228e91772958'  'nix \
| sha256sum -c

chmod -v +x nix \
&& ./nix flake --version \
&& ./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--refresh \
run \
github:ES-nix/es#installStartConfigTemplate
```

```bash
./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--refresh \
run --impure 'github:ES-Nix/es/?dir=src/templates/nginx'

./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
run \
'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0#nixosTests.docker-rootless.driverInteractive'
```

```bash
nix build --no-link --print-build-logs --print-out-paths \
'.#homeConfigurations.x86_64-linux."vagrant-alpine319.localdomain".activationPackage'
```

```bash
sudo sh -c 'mkdir -pv -m 1735 /nix/var/nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'

# curl -s https://api.github.com/repos/NixOS/nix/tags | jq -r '.[0].name'
NIX_RELEASE_VERSION=2.29.0 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh \
&& export NIX_CONFIG='extra-experimental-features = nix-command flakes' \
&& nix -vv registry pin nixpkgs github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334
```

```bash
git ls-remote --exit-code --tags --refs https://github.com/NixOS/nixpkgs.git \
| cut -d'/' -f3 \
| grep -v 'backups' \
| grep -v 'black'
```

It usually points to "the firs commit in an branch":
```bash
git ls-remote --exit-code --tags --refs \
https://github.com/NixOS/nixpkgs.git "refs/tags/22.11" | cut -f1
```

```bash
nix derivation show /nix/store/r1fzphbbr0gs4ichvn2g4nlrq2cqghwc-user-environment.drv

```

### Testing it

```bash
cat > Containerfile << 'EOF'
FROM ubuntu:24.04 as ubuntu-base
RUN apt-get update -y \
 && apt-get install --no-install-recommends --no-install-suggests -y \
     adduser \
     ca-certificates \
     curl \
     sudo \
 && apt-get -y autoremove \
 && apt-get -y clean \
 && rm -rf /var/lib/apt/lists/*

RUN addgroup abcgroup --gid 4455  \
 && adduser -q \
     --gecos '"An unprivileged user with an group"' \
     --disabled-password \
     --ingroup abcgroup \
     --uid 3322 \
     abcuser \
 && echo 'abcuser:123' | chpasswd \
 && echo 'abcuser ALL=(ALL) NOPASSWD:SETENV: ALL' > /etc/sudoers.d/abcuser \
 && echo 'Start kvm stuff...' \
 && (getent group kvm || sudo groupadd kvm) \
 && usermod --append --groups kvm abcuser \
 && echo 'End kvm stuff!'

USER abcuser
WORKDIR /home/abcuser
ENV USER="abcuser"
# ENV PATH=/home/abcuser/.nix-profile/bin:/home/abcuser/.local/bin:"$PATH"
# ENV SHELL="/bin/bash"
EOF

docker \
build \
--file=Containerfile \
--target ubuntu-base \
--tag=ubuntu-base .

xhost + || nix run nixpkgs#xorg.xhost -- +
docker \
run \
--env="DISPLAY=${DISPLAY:-:0}" \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:rw \
--interactive=true \
--privileged=true \
--tty=true \
--rm=true \
ubuntu-base:latest
```


```bash
docker \
run \
--hostname=container-nix-hm \
--interactive=true \
--name=container-nix-hm \
--tty=true \
--rm=true \
ubuntu-base:latest
```




```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/alpine:3.20.3 as alpine-with-ca-certificates-tzdata

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
RUN mkdir -pv /nix/var/nix && chmod -v 1735 /nix && chown -Rv nixuser:nixgroup /nix

USER nixuser
WORKDIR /home/nixuser
ENV USER="nixuser"

RUN curl -L https://hydra.nixos.org/build/272142581/download-by-type/file/binary-dist -o nix \
 && chmod -v +x nix \
 && ./nix flake --version \
 && ./nix \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    --refresh \
    run \
    github:ES-nix/es#installStartConfigTemplate \
 && rm -v ./nix

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
--device=/dev/dri:ro \
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
--rm=false \
--userns=keep-id \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume="$(pwd)":/home/nixuser/code:rw \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh -cl 'touch /home/nixuser/code && nix run nixpkgs#xorg.xclock'
```
Refs.:
- 



```bash
podman \
run \
--group-add=keep-groups \
--privileged=false \
--rm=true \
--userns=keep-id \
--volume="$(pwd)":/home/nixuser/code:rw \
busybox \
sh \
-cl \
'id'
```


###

Where is it from?
```nix
      mkSystem = extraModules:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            # bake the git revision of the repo into the system
            ({ ... }: { system.configurationRevision = self.sourceInfo.rev; })
          ] ++ extraModules;
        };
```
