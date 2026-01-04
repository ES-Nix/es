

```bash
nix \
run \
--refresh \
--override-input \
nixpkgs \
github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852 \
github:ES-nix/es#installQEMUVirtualMachineDockerTemplate \
&& { direnv &>/dev/null && direnv deny QEMUVirtualMachineDocker || true; } \
&& cd QEMUVirtualMachineDocker \
&& nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
&& nix \
      build \
      --no-link \
      --print-build-logs \
      --print-out-paths \
      .#nixosConfigurations.vm.config.system.build.vm \
&& nix run --impure --refresh --verbose .# \
&& rm -fv nixos.qcow2 \
&& chmod -v 0600 id_ed25519 \
&& { ssh-add -l 1> /dev/null 2> /dev/null ; test $? -eq 2 && eval $(ssh-agent -s); } || true \
&& echo 'There could be an race condition in here?' \
&& { ssh-add -L | grep -q "$(cat id_ed25519.pub)" || ssh-add -v id_ed25519; } \
&& { ssh-add -L | grep -q "$(cat id_ed25519.pub)" || echo 'erro in ssh-add -L'; } \
&& { ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null  || true; } \
&& for i in {1..600}; do
  ssh \
      -o ConnectTimeout=1 \
      -oStrictHostKeyChecking=accept-new \
      -p 10022 \
      nixuser@localhost \
         -- \
         sh  <<<'docker images' 1>/dev/null 2>/dev/null \
  && break

  ! ((i % 11)) && echo Iteration $i, date $(date +'%d/%m/%Y %H:%M:%S:%3N')
  sleep 0.1
done \
&& { direnv allow || true; } \
&& nix --option warn-dirty false develop .# --command docker images
```

```bash
kill $(pgrep qemu)

lsof -i :10022 1> /dev/null 2> /dev/null && kill "$(pgrep .qemu-system)"

pgrep qemu
echo $!
```

Be careful!
```bash
{ kill $(pgrep qemu) || true; } \
&& { ssh-keygen -R '[localhost]:10022' || true; } \
&& cd .. \
&& rm -frv QEMUVirtualMachineDocker

rm -fv ~/.ssh/known_hosts
```

TODO: is there an way to make it just work or it is not needed?
```bash
ssh-keyscan -H -p 10022 -t ecdsa localhost >> ~/.ssh/known_hosts
```
Refs.:
- https://stackoverflow.com/a/73644766
