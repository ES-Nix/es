


```bash
nix \
run \
--refresh \
--override-input \
nixpkgs \
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
github:ES-nix/es#installQEMUVirtualMachineDockerTemplate \
&& ((direnv &>/dev/null ) && direnv deny QEMUVirtualMachineDocker || true) \
&& cd QEMUVirtualMachineDocker

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm

chmod -v 0600 id_ed25519

ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -L | grep -q "$(cat id_ed25519.pub)") || ssh-add -v id_ed25519

ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null;

#while ! ssh -o ConnectTimeout=1 -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true' ; do 
#  echo $(date +'%d/%m/%Y %H:%M:%S:%3N')
#  sleep 1
#done

for i in {1..500}; do
  ssh -o ConnectTimeout=1 -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true' \
  && break
  
  ! $((i % 5)) && echo $(date +'%d/%m/%Y %H:%M:%S:%3N')
  sleep 0.2
done


direnv allow
nix develop .# --command docker images
```


```bash
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
.#nixosConfigurations.vm.config.system.build.vm
```

```bash
direnv deny

chmod -v 0600 id_ed25519

ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -l | grep -q "$(cat id_ed25519.pub)") || ssh-add id_ed25519

ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null;
for i in web{0..60};do ssh -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true':
sleep 1;
echo $(date +'%d/%m/%Y %H:%M:%S:%3N');
done;
direnv allow
docker images

# ssh-keyscan -H -p 10022 -t ecdsa localhost >> ~/.ssh/known_hosts
```

https://stackoverflow.com/a/73644766


nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659
