

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
&& poetry show --tree
```


```bash
source .venv/bin/activate
```

```bash
django-admin startproject minitwitter .
```

```bash
python manage.py migrate
```

```bash
python manage.py runserver
```


```bash
curl http://127.0.0.1:8000/ | grep -q 'The install worked successfully! Congratulations!'
echo $?
```

```bash
mkdir -pv dj-jwt-ah \
&& cd $_ \
&& django-admin startproject myabcproject . \
&& python manage.py runserver
```

