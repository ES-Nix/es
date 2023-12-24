



nix \
run \
--refresh \
github:ES-nix/es#installQEMUVirtualMachineDocker


nix \
--refresh \
flake \
init \
--template \
github:ES-Nix/es#qemuVirtualMachineDocker



rm -fv nixos.qcow2; nix run --impure --refresh --verbose .#vm


```bash
ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -l | grep -q "$(cat id_ed25519.pub)") || ssh-add id_ed25519

```



