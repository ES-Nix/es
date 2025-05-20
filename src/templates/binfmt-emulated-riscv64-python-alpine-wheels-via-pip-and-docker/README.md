


```bash
nix flake show '.#'
nix flake metadata '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'
nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#' --rebuild

nix fmt '.#'

# nix flake check --verbose '.#'
```


```bash
cffi
cryptography
fastapi
lxml
maturin
msgpack
nh3
pandas
```
Refs.:
- https://lf-rise.atlassian.net/wiki/spaces/HOME/pages/75628548/Project+RP011+Python+Package+Support+for+RISC-V+riscv64?utm_content=313418783&utm_medium=social&utm_source=linkedin&hss_channel=lcp-97448757








```bash
cat > Containerfile << 'EOF'
FROM python:3.9.19-alpine3.20

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
--tag=unprivileged-python-alpine .


docker \
run \
--interactive=true \
--network=none \
--tty=true \
--rm=true \
--volume="$(pwd)":/code:rw \
--workdir=/code \
unprivileged-python-alpine
```


```bash
docker \
run \
--interactive=true \
--network=none \
--tty=true \
--rm=true \
--volume="$(pwd)":/code:rw \
--workdir=/code \
python:3.11.4-slim-bookworm  \
bash \
-c \
'
pip install --root-user-action=ignore --no-index --find-links '.' mmh3-4.1.0-cp311-cp311-linux_x86_64.whl
python3 -c "import mmh3; assert mmh3.hash128(bytes(123)) == 126000048256919600573431412872524959502"
'
```



```bash
docker \
run \
--interactive=true \
--network=none \
--tty=true \
--rm=true \
--volume="$(pwd)":/code:rw \
--workdir=/code \
python:3.9.19-alpine3.20  \
bash \
-c \
'
pip install --root-user-action=ignore --no-index --find-links '.' mmh3-4.1.0-cp311-cp311-linux_x86_64.whl
python3 -c "import mmh3; assert mmh3.hash128(bytes(123)) == 126000048256919600573431412872524959502"
'
```



```bash
python3 -m venv .venv \
&& source .venv/bin/activate
```
