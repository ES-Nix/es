# 



```bash
nix run '.#allTests'
```


```bash
rm -fv nixos.qcow2; 
nix \
run \
--impure \
--verbose \
'.#'
```


```bash
prepare-vagrant-vms \
&& cd "$HOME"/vagrant-examples/libvirt/nixos/ \
&& vagrant up \
&& vagrant ssh

# vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'
```

```bash
uid=1000(vagrant) gid=1000(vagrant) groups=1000(vagrant) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
NAME="AlmaLinux"
VERSION="9.5 (Teal Serval)"
ID="almalinux"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.5"
PLATFORM_ID="platform:el9"
PRETTY_NAME="AlmaLinux 9.5 (Teal Serval)"
ANSI_COLOR="0;34"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:almalinux:almalinux:9::baseos"
HOME_URL="https://almalinux.org/"
DOCUMENTATION_URL="https://wiki.almalinux.org/"
BUG_REPORT_URL="https://bugs.almalinux.org/"

ALMALINUX_MANTISBT_PROJECT="AlmaLinux-9"
ALMALINUX_MANTISBT_PROJECT_VERSION="9.5"
REDHAT_SUPPORT_PRODUCT="AlmaLinux"
REDHAT_SUPPORT_PRODUCT_VERSION="9.5"
SUPPORT_END=2032-06-01
```


```bash
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```

```bash
vagrant ssh -c 'sudo dnf install -y python3 && python3 --version'
```

While not "solved" https://github.com/vagrant-libvirt/vagrant-libvirt/pull/1835
is expected!
```bash
[fog][WARNING] Unrecognized arguments: libvirt_ip_command
```
Refs.:
- https://github.com/vagrant-libvirt/vagrant-libvirt/pull/1835
