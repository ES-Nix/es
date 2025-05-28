



```bash
export NIXPKGS_ALLOW_UNFREE=1

nix flake metadata '.#'
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```


1)
```bash
rm -fv nixos.qcow2; 
nix \
run \
--impure \
--verbose \
'.#'
```


2)
```bash
prepare-vagrant-vms \
&& cd "$HOME"/vagrant-examples/libvirt/nixos/ \
&& vagrant up \
&& vagrant ssh


vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'


ANSI_COLOR="1;34"
BUG_REPORT_URL="https://github.com/NixOS/nixpkgs/issues"
BUILD_ID="24.05.20240530.d24e7fd"
DOCUMENTATION_URL="https://nixos.org/learn.html"
HOME_URL="https://nixos.org/"
ID=nixos
IMAGE_ID=""
IMAGE_VERSION=""
LOGO="nix-snowflake"
NAME=NixOS
PRETTY_NAME="NixOS 24.05 (Uakari)"
SUPPORT_END="2024-12-31"
SUPPORT_URL="https://nixos.org/community.html"
VERSION="24.05 (Uakari)"
VERSION_CODENAME=uakari
VERSION_ID="24.05"
```


```bash
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```


