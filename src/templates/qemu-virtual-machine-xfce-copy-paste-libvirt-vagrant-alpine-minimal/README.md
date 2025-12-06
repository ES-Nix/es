



```bash
nix fmt . \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
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
cd "$HOME"/vagrant-examples/libvirt/alpine/
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```


ss -lx | grep libvirt


virsh version
virsh capabilities
virsh list --all


sudo virsh -c qemu:///system capabilities
sudo virsh pool-list --all
sudo virsh net-list --all


journalctl --unit libvirtd.service --no-pager

systemctl is-active libvirtd.socket
