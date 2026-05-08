

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
nix flake metadata '.#'
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```



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


### TODO: django rest with poetry

https://discourse.nixos.org/t/python-packaging-with-poetry-and-nix/26602


```bash
nix profile install nixpkgs#poetry
```

Bootstraping:
```bash
mkdir -v app-drf \
&& cd app-drf \
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
&& ls -alh \
&& source .venv/bin/activate \
&& django-admin startproject pr0j3ct . \
&& python manage.py migrate \
&& ls -alh \
&& python manage.py runserver
```


```bash
curl http://127.0.0.1:8000/ | grep -q 'The install worked successfully! Congratulations!'
echo $?
```

### TODO: django rest with uv

https://discourse.nixos.org/t/python-packaging-with-poetry-and-nix/26602


Bootstraping:
```bash
nix profile install nixpkgs#uv nixpkgs#python311

export UV_PYTHON_PREFERENCE="only-system"

rm -frv ~/test-uv; mkdir -v ~/test-uv \
&& cd ~/test-uv \
&& uv init example-app \
&& cd example-app \
&& uv venv --python 3.11 \
&& uv lock \
&& uv tree \
&& uv add djangorestframework==3.15.2 \
&& uv lock \
&& uv tree \
&& source .venv/bin/activate \
&& django-admin startproject pr0j3ct . \
&& python manage.py migrate \
&& ls -alh \
&& python manage.py runserver \
&& deactivate
```


```bash
curl http://127.0.0.1:8000/ | grep -q 'The install worked successfully! Congratulations!'
echo $?
```
