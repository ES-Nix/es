

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
cd "$HOME"/vagrant-examples/libvirt/opensuse/ \
&& vagrant up \
&& vagrant ssh
```


```bash
vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'
```


```bash
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```
