#

```bash
nix run '.#allTests'
```


```bash
rm -fv nixos.qcow2; 
nix \
run \
--impure \
--verbose \
'.#'
```


```bash
cd "$HOME"/vagrant-examples/libvirt/nixos/ \
&& vagrant up \
&& vagrant ssh
```


```bash
vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'
```

```bash
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


##



```bash
cd /etc/nixos \
&& nix \
shell \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852 \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#gnused \
nixpkgs#nix \
nixpkgs#git \
--command \
bash \
<<'COMMANDS'

cat << 'EOF' | sudo tee custom-configuration.nix
{ config, nixpkgs, pkgs, lib, modulesPath, ... }:
let
  cfg = config;
in
{
    environment.systemPackages = with pkgs; [
        kubectl
        kubernetes

        (
          writeScriptBin "wk8s-sudo" ''
            #! ${pkgs.runtimeShell} -e
                while true; do
                  sudo -E kubectl get pod --all-namespaces -o wide \
                  && echo \
                  && sudo -E kubectl get services --all-namespaces -o wide \
                  && echo \
                  && sudo -E kubectl get deployments.apps --all-namespaces -o wide \
                  && echo \
                  && sudo -E kubectl get nodes --all-namespaces -o wide;
                  sleep 1;
                  clear;
                done
          ''
        )
      ];

  services.kubernetes.roles = [ "master" "node" ];
  services.kubernetes.masterAddress = "${cfg.networking.hostName}";
  environment.variables.KUBECONFIG = "/etc/${cfg.services.kubernetes.pki.etcClusterAdminKubeconfig}";
}
EOF

cd /etc/nixos \
&& sed -i 's|./guest-agent.nix|./guest-agent.nix ./custom-configuration.nix|g' configuration.nix \
&& git init \
&& git add . \
&& nix \
    flake \
    lock \
    --override-input nixstable github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852
COMMANDS

sudo nixos-rebuild switch -L --flake .# --show-trace

sudo reboot
```
