

nix \
--refresh \
flake \
init \
--template \
github:ES-Nix/es#qemuVirtualMachineDocker



```bash
ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -l | grep -q "$(cat ~/.ssh/id_ed25519.pub)") || ssh-add ~/.ssh/id_ed25519
```

