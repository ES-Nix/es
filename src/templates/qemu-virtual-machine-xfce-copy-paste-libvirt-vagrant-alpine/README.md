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
cd "$HOME"/vagrant-examples/libvirt/alpine/ \
&& vagrant up \
&& vagrant ssh
```


```bash
# vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'
```


```bash
cd "$HOME"/vagrant-examples/libvirt/alpine/
vagrant destroy --force; vagrant destroy --force


cd "$HOME"/vagrant-examples/libvirt/alpine/ \
&& vagrant up \
&& for i in {1..20}; do { vagrant ssh -c 'true' && break; } ; sleep 0.1; done \
&& vagrant ssh
```

While not "solved" https://github.com/vagrant-libvirt/vagrant-libvirt/pull/1835
is expected!
```bash
[fog][WARNING] Unrecognized arguments: libvirt_ip_command
```
Refs.:
- https://github.com/vagrant-libvirt/vagrant-libvirt/pull/1835
