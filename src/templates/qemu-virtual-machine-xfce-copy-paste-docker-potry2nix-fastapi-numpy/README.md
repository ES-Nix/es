


```bash
nix fmt . \
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --all-systems --verbose '.#'
```


```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose '.#'
```



Invoking in the host:
```bash
start
```


Or using with docker:
```bash
docker run --interactive=true --tty=true --rm=true --publish=5000:5000 myapp-oci-image:0.0.1
```


Or using with podman:
```bash
podman run --interactive=true --tty=true --rm=true --publish=5000:5000 localhost/myapp-oci-image:0.0.1
```


```bash
curl http://127.0.0.1:5000
firefox http://127.0.0.1:5000
```

TODO: missing checks that validate code formating, like black.
