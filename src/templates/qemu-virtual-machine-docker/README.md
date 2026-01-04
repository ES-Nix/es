


```bash
# && { direnv &>/dev/null && direnv deny QEMUVirtualMachineDocker || true } \
# && { direnv allow || true; } \

nix \
run \
--refresh \
--override-input \
nixpkgs \
github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852 \
github:ES-nix/es#installQEMUVirtualMachineDockerTemplate \
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
&& for i in {1..600}; do
  pgrep qemu \
  && break
  ! ((i % 11)) && echo $(date +'%d/%m/%Y %H:%M:%S:%3N')
  sleep 0.1
done \
&& pgrep qemu \
&& echo \
&& chmod -v 0600 id_ed25519 \
&& { ssh-add -l 1> /dev/null 2> /dev/null ; test $? -eq 2 && eval $(ssh-agent -s); } || true \
&& echo 'There could be an race condition in here?' \
&& { ssh-add -L | grep -q "$(cat id_ed25519.pub)" || ssh-add -v id_ed25519; } \
&& { ssh-add -L | grep -q "$(cat id_ed25519.pub)" || echo 'erro in ssh-add -L'; } \
&& ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null \
&& for i in {1..600}; do
  ssh \
      -o ConnectTimeout=1 \
      -oStrictHostKeyChecking=accept-new \
      -p 10022 \
      nixuser@localhost \
         -- \
         sh  <<<'docker images' 1>/dev/null 2>/dev/null \
  && break

  ! ((i % 11)) && echo $(date +'%d/%m/%Y %H:%M:%S:%3N')
  sleep 0.1
done \
&& nix --option warn-dirty false develop .# --command docker images
```

```bash
kill $(pgrep qemu)
```


```bash
#while ! ssh -o ConnectTimeout=1 -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true' ; do 
#  echo $(date +'%d/%m/%Y %H:%M:%S:%3N')
#  sleep 1
#done
```


```bash
direnv deny

chmod -v 0600 id_ed25519

ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -l | grep -q "$(cat id_ed25519.pub)") || ssh-add id_ed25519

ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null;
for i in {0..60};do ssh -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true':
sleep 1;
echo $(date +'%d/%m/%Y %H:%M:%S:%3N');
done;
direnv allow
docker images

# ssh-keyscan -H -p 10022 -t ecdsa localhost >> ~/.ssh/known_hosts
```
Refs.:
- https://stackoverflow.com/a/73644766
