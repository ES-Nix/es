

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```



Invoking in the host:
```bash
start
```


Or using with docker:
```bash
docker run -it --rm --publish=5000:5000 myapp-oci-image:0.0.1
```


Or using with podman:
```bash
podman run -it --rm --publish=5000:5000 localhost/myapp-oci-image:0.0.1
```


```bash
curl http://127.0.0.1:5000
firefox http://127.0.0.1:5000
```

TODO: missing checks that validate code formating, like black.


```bash
nix build --no-link --print-build-logs --print-out-paths '.#checks.x86_64-linux.testMyappOCIImageDockerFirefoxOCR'
```


```bash
okular $(nix build --no-link --print-build-logs --print-out-paths '.#checks.x86_64-linux.testMyappOCIImageDockerFirefoxOCR')/screen.png
```
