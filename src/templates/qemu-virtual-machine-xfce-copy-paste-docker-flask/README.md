

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




```bash
cat > compose.yaml << 'EOF'
services:
   redis: 
     image: static-redis-server-minimal:latest
     ports:
       - "6379:6379" 
   web:
     image: python3-flask-redis:0.0.1
     ports:
       - "5002:5002"
EOF

docker compose up -d
```

https://docs.docker.com/compose/gettingstarted/#step-1-set-up

```bash
curl http://localhost:5002/
```

```bash
docker compose down
```

```bash
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```
