


```bash
nix run '.#allTests'
```


```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose '.#'
```



Invoking in the host:
```bash
ssh  \
-o ConnectTimeout=1 \
-o ConnectionAttempts=2 \
-o StrictHostKeyChecking=no \
-o GlobalKnownHostsFile=/dev/null \
-o UserKnownHostsFile=/dev/null \
-o LogLevel=ERROR \
nixuser@localhost \
-p 2000 \
cat /etc/os-release
```

```bash
cat /etc/ssh/sshd_config
```
