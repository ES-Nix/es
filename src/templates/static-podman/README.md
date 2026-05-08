

```bash
nix run '.#allTests'
```


```bash
docker run -it alpine

apk add --no-cache \
  build-base \
  go \
  git \
  pkgconfig \
  linux-headers \
  musl-dev \
  libseccomp-dev \
  libassuan-dev \
  gpgme-dev \
  btrfs-progs-dev \
  lvm2-dev \
&& git clone https://github.com/containers/podman.git \
&& cd podman \
&& git checkout v5.8.0 \
&& go build -x \
  -tags "exclude_graphdriver_devicemapper exclude_graphdriver_btrfs containers_image_openpgp" \
  -ldflags "-s -w -linkmode external -extldflags '-static'" \
  -o podman ./cmd/podman \
&& ls -alh podman \
&& ./podman --version \
&& ! ldd ./cmd/podman


&& CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
go build -x -work -v \
  -tags remoteclient \
  -o podman-remote \
  ./cmd/podman \
&& ls -alh podman-remote \
&& ./podman-remote --version \
&& ! ldd podman-remote

make podman-remote-static NATIVE_GOOS=linux NATIVE_GOARCH=amd64 GOOS=linux GOARCH=amd64

```


```bash
cat > Dockerfile << 'EOF'
FROM alpine AS builder

RUN apk add --no-cache \
    go \
    git \
    bash

# Set Go environment
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# Clone Podman v5.8.0
WORKDIR /src
RUN git clone --branch v5.8.0 --depth 1 https://github.com/containers/podman.git .

# Build static remote client
RUN go build -x -tags "remoteclient containers_image_openpgp" \
    -trimpath \
    -ldflags "-s -w" \
    -o /podman-remote \
    ./cmd/podman

# Stage 2: Final minimal image
FROM scratch
COPY --from=builder /podman-remote /podman-remote

# The resulting container has only the static binary
ENTRYPOINT ["/podman-remote"]
EOF

docker build -t podman-remote-static .

CID=$(docker create podman-remote-static) \
&& docker cp $CID:/podman-remote ./podman-remote \
&& docker rm $CID \
&& ls -alh podman-remote \
&& ./podman-remote --version \
&& ! ldd podman-remote
```



```bash
docker \
run \
--hostname=container-nix-flakes \
--interactive=true \
--name=container-nix-flakes \
--tty=true \
--rm=true \
docker.io/nixpkgs/nix-flakes


docker \
run \
--interactive=true \
--tty=false \
--rm=true \
docker.io/nixpkgs/nix-flakes \
sh <<'COMMANDS'
nix \
shell \
--override-flake nixpkgs github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852 \
nixpkgs#go \
nixpkgs#gnumake \
nixpkgs#bash \
nixpkgs#file \
nixpkgs#pkg-config \
--command \
bash \
-c \
'
git clone --branch v5.8.0 --depth 1 https://github.com/containers/podman.git \
&& cd podman \
&& make podman-remote-static \
&& ls -alh bin/podman-remote-static \
&& ! ldd bin/podman-remote-static \
&& file bin/podman-remote-static \
&& bin/podman-remote-static --version
'
COMMANDS
```
