



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
&& cd "$HOME"/vagrant-examples/libvirt/alpine/ \
&& vagrant up \
&& vagrant ssh


vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'

PRETTY_NAME="Alpine Linux v3.19"
```


```bash
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```



### 

```bash
cd /etc/nixos

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


sudo \
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8

sudo nixos-rebuild switch -L

sudo reboot
```
