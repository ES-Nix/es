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
# vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'
```


```bash
cd "$HOME"/vagrant-examples/libvirt/nixos/
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```


```bash
ss -lx | grep libvirt

virsh version
virsh capabilities
virsh list --all

sudo virsh -c qemu:///system capabilities
sudo virsh pool-list --all
sudo virsh net-list --all

journalctl --unit libvirtd.service --no-pager

systemctl is-active libvirtd.socket
```
