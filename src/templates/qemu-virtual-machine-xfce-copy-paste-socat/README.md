


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
echo 111222333 > ~/l0g.txt
socat TCP-LISTEN:2222,reuseaddr,fork EXEC:/bin/sh
```

Invoking in the host:
```bash
nc -w 1 localhost 2222 <'cat ~/l0g.txt'
echo ' cat ~/l0g.txt' | nc -w 1 localhost 2222 
```
