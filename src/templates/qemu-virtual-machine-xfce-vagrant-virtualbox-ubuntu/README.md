```bash
export NIXPKGS_ALLOW_UNFREE=1
nix run --impure '.#allTests'
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
apt-get update --assume-yes \
 && apt-get install --assume-yes \
     adduser \
     ca-certificates \
     curl \
     dbus-x11 \
     sudo \
     tar \
     terminator \
     wget \
     x11-apps \
     xfce4 \
     xz-utils \
 && apt-get --assume-yes autoremove \
 && apt-get --assume-yes clean \
 && rm -rf /var/lib/apt/lists/*
```


```bash
prepare-vagrant-vms \
&& cd "$HOME"/vagrant-examples/libvirt/ubuntu/ \
&& vagrant up \
&& vagrant ssh

vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'
```


```bash
cd "$HOME"/vagrant-examples/virtualbox/ubuntu
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```
