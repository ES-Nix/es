


```bash
nix \
run \
--refresh \
github:ES-nix/es#installQEMUVirtualMachineDockerTemplate \
&& cd QEMUVirtualMachineDocker

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm
```



```bash
chmod -v 0600 id_ed25519

ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -l | grep -q "$(cat id_ed25519.pub)") || ssh-add id_ed25519


ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null;
ssh -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true'

docker images

# ssh-keyscan -H -p 10022 -t ecdsa localhost >> ~/.ssh/known_hosts
```

