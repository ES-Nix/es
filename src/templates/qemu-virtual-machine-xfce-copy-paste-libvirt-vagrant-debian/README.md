



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
&& cd "$HOME"/vagrant-examples/libvirt/debian/ \
&& vagrant up \
&& vagrant ssh


vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'


```


```bash
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```
