



```bash
nix flake metadata '.#'
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```


```bash
export NIXPKGS_ALLOW_UNFREE=1

rm -fv nixos.qcow2; 
nix \
run \
--impure \
--verbose \
'.#'
```



```bash
prepare-vagrant-vms \
&& cd "$HOME"/vagrant-examples/libvirt/ubuntu/ \
&& vagrant up \
&& vagrant ssh


vagrant ssh -- -t 'id && cat /etc/os-release'
vagrant ssh -c 'id && cat /etc/os-release'

PRETTY_NAME="Alpine Linux v3.19"
```


```bash
cd "$HOME"/vagrant-examples/libvirt/ubuntu/
vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh
```



### Bootstrapping django project



```bash
mkdir -pv dj-jwt-ah \
&& cd $_ \
&& python3 -m venv .venv \
&& source .venv/bin/activate \
&& pip install --upgrade pip==24.2

pip \
install \
Django==5.1.2 \
django-filter==24.3 \
dj-rest-auth==6.0.0 \
djangorestframework==3.15.2 \
djangorestframework-simplejwt==5.3.1 \
Markdown==3.7 \
PyJWT==2.9.0 \
sqlparse==0.5.1
```


```bash
mkdir -pv dj-jwt-ah \
&& cd $_ \
&& python3 -m venv .venv \
&& source .venv/bin/activate \
&& pip install --upgrade pip==24.2

pip \
install \
asgiref \
Django \
django-filter \
dj-rest-auth \
djangorestframework \
djangorestframework-simplejwt
```

```bash
pip \
install \
djangorestframework
```

```bash
pip freeze
```


```bash
pip \
install \
asgiref==3.8.1
Django==5.1.2
djangorestframework==3.15.2
sqlparse==0.5.1
```


```bash
django-admin startproject minitwitter .
```


```bash
python manage.py startapp userauth
```

```bash
python manage.py migrate
```

```bash
python manage.py createsuperuser
```


```bash
python manage.py runserver
```



```bash
docker build . --tag minitwitter:0.0.1
```

```bash
docker run -it --publish=8000:8000 --rm minitwitter:0.0.1
```


```bash
EXPR=$(cat <<-'EOF'
(
  let
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a"); 
    pkgs = import nixpkgs {};
  in
    pkgs.python3.withPackages (p: with p; [ djangorestframework ])
)
EOF
)

nix \
shell \
--impure \
--expr \
"$EXPR"
```
