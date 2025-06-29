


```bash
nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
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

cat /etc/ssh/sshd_config
