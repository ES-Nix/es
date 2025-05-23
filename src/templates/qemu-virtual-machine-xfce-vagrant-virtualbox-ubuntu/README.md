```bash
nix flake metadata '.#'
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
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
prepare-vagrant-vms \
&& cd "$HOME"/vagrant-examples/libvirt/ubuntu/ \
&& vagrant up \
&& vagrant ssh


vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'

PRETTY_NAME="Alpine Linux v3.19"
```


```bash
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```
