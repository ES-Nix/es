
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
docker run -it --rm --publish=8000:8000 myapp-oci-image:0.0.1
```


Or using with podman:
```bash
podman run -it --rm --publish=8000:8000 localhost/myapp-oci-image:0.0.1
```


```bash
curl http://127.0.0.1:8000
firefox http://127.0.0.1:8000
```

TODO: missing checks that validate code formating, like black.




```bash
python -m myapp?
python -c 'import myapp?'
```


```bash
nix flake update '.#'
 ```

```bash
nix flake metadata '.#'
```

```bash
nix flake check '.#'
```


### bootstrapping djangorestframework with poetry


```bash
mkdir -v xptoapp \
&& cd xptoapp \
&& poetry config virtualenvs.in-project true \
&& poetry config virtualenvs.path . \
&& poetry init --no-interaction  \
&& poetry lock \
&& poetry show --tree \
&& poetry \
    add \
    djangorestframework==3.15.2 \
&& poetry lock \
&& poetry show --tree \
&& poetry run django-admin startproject drfhello . \
&& poetry run python manage.py migrate \
&& poetry run python manage.py runserver
```

django = "^5.1.3"


```bash
curl http://127.0.0.1:8000/ | grep -q 'The install worked successfully! Congratulations!'
echo $?
```


```bash
firefox http://127.0.0.1:8000/
```


```bash
source .venv/bin/activate
```


```bash
docker run -it --rm myapp-oci-image:0.0.1
```

https://discourse.nixos.org/t/how-to-run-a-django-flake-with-poetry2nix/27057
