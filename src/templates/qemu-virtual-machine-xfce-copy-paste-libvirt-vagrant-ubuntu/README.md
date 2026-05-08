# 



```bash
nix run '.#allTests'
```


```bash
export NIXPKGS_ALLOW_UNFREE=1

rm -fv nixos.qcow2; 
nix \
run \
--impure \
--verbose \
'.#'
```


```bash
cd "$HOME"/vagrant-examples/libvirt/ubuntu/ \
&& vagrant up \
&& vagrant ssh
```


```bash
cd "$HOME"/vagrant-examples/libvirt/ubuntu/ \
&& vagrant up \
&& for i in {1..20}; do { vagrant ssh -c 'true' && break; } ; sleep 0.1; done \
&& vagrant ssh
```


```bash
# vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release' 
```


```bash
cd "$HOME"/vagrant-examples/libvirt/ubuntu/
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```
