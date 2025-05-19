
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
poetry add 'fastapi[standard]'


fastapi dev app/main.py
poetry run start-app

uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

```bash
uvicorn==0.34.2
```
