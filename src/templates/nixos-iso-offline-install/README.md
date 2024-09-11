



1) 
```bash
rm -fv mydisk.qcow2
nix run '.#' && nix run '.#run' 
```


2) For now no automatic login. So login with `nixuser` and password `1` 

3) In the VM's terminal:
```bash
sudo nixos-rebuild test \
&& sudo nixos-rebuild switch
```

TODO: it should be an nix flake


### Details


TODO: 
- Explain how to pass env vars to scripts!
- Do it for other env vars!
```bash
export DISK_NAME=foo-bar-mydisk.qcow2
```



TODO: for some reason it was error outing even commented, why? 
```nix
    # registry.nixpkgs.flake = nixpkgs;
    # nixPath = [ "nixpkgs=${pkgs.path}" ]; # TODO: test it
```



TODO: 
- is it possible to make an systemd unity reboot the machine?
- the goal would be to change user id to match the host one.
```nix
  # https://unix.stackexchange.com/questions/619671/declaring-a-sym-link-in-a-users-home-directory#comment1159159_619703
  systemd.services.fix-mount = {
    script = ''
      echo "Fixing mount"
      #
      mkdir /home/nixuser/code
      chown nixuser:nixgroup /home/nixuser/code
      echo "echo 1 | sudo -S mount -t 9p -o trans=virtio hostsharetag /home/nixuser/code" >> /home/nixuser/.profile
    '';
    wantedBy = [ "multi-user.target" ];
  };
``` 







nix build --file '<nixpkgs/nixos>' system -I nixos-config=/mnt/etc/nixos/configuration.nix -o /out

nix build --offline --no-use-registries --file '<nixpkgs/nixos>' system -I nixos-config=/mnt/etc/nixos/configuration.nix -o /out
nix build --offline --no-use-registries --file "$HACK_NIX_PATH"'/nixos' system -I nixos-config=/mnt/etc/nixos/configuration.nix -o /out

nix eval --expr 'builtins.nixPath'
date --rfc-3339=ns --utc
date --iso-8601=ns --utc


environment.variables.HACK_NIX_PATH = "${pkgs.path}";

environment.etc."channels/nixpkgs".source = pkgs.path;


nixos-install \
--no-root-password \
--no-registries \
--no-channel-copy


ls -alh /mnt/root/.nix-defexpr/channels


sudo \
nix-build \
--out-link /mnt/system \
--store /mnt \
--extra-substituters "auto?trusted=1" \
"$HACK_NIX_PATH"'/nixos' \
-A system \
-I "nixos-config=/mnt/etc/nixos/configuration.nix"




nix-build \
--out-link /mnt/system \
--store /mnt \
--extra-substituters "auto?trusted=1" \
"${pkgs.path}"'/nixos' \
-A system \
-I "nixos-config=/mnt/etc/nixos/configuration.nix"


${installBuild.nixos-install}/bin/nixos-install \
--no-root-password \
--no-registries

ls -alh /mnt/system

time nix --option cores 8 build --print-build-logs --print-out-paths '.#iso-nixos-offline-install-in-qcow2'
time nix --option cores 8 build --print-build-logs --print-out-paths --rebuild '.#iso-nixos-offline-install-in-qcow2'


TODO: figure it out why so many bugs/race conditions using the script that install NixOS
```bash
Error: You requested a partition from 537MB to 11.8GB (sectors 1048576..23068671).
The closest location we can manage is 537MB to 537MB (sectors 1048575..1048575).
```

```bash
Error: primary partition table array CRC mismatch
```


```bash
Error: The backup GPT table is corrupt, but the primary appears OK, so that will be used.
Error: primary partition table array CRC mismatch
```



```bash
sudo fdisk -l

sudo parted /dev/sda align-check
```
Refs.:
- https://superuser.com/a/1378922