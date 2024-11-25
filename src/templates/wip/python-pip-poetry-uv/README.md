



### conda

```bash
git clone https://github.com/gisliany/uber-liveability-natal.git \
&& cd uber-liveability-natal 

nix \
shell \
nixpkgs#python3 \
nixpkgs#conda \
nixpkgs#bashInteractive \
bash \
conda-shell
```

```bash
conda-install \
&& conda env update --file environment.yml
```


### uv

TODO:
- https://www.reddit.com/r/NixOS/comments/1fdxpam/help_request_python_development_specifically_with/
- https://github.com/astral-sh/uv/issues/4450


### pip/poetry

```bash
git clone https://github.com/peidrao/Desafio-Backend.git \
&& cd Desafio-Backend \
&& make run
```
Refs.:
- https://github.com/peidrao/Desafio-Backend?tab=readme-ov-file#como-utilizar-o-projeto


```bash
git clone https://github.com/imobanco/django-poc.git \
&& cd django-poc

nix \
shell \
nixpkgs#python3 \
nixpkgs#wrk \
nixpkgs#bashInteractive \
bash \
-c
'python3 -m venv .venv'


source .venv/bin/activate
```

TODO: https://github.com/wg/wrk/issues/507



### ?

nano ~/.config/Code/User/settings.json



```bash
mkdir -pv ~/sandbox/sandbox \
&& cd ~/sandbox/sandbox \
&& nix flake init --template templates#full
```



```bash
git init \
&& git status \
&& git add . \
&& nix flake update --override-input nixpkgs github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343 \
&& git status \
&& git add . \
&& git commit -m 'First nix flake commit'"$(date +'%d/%m/%Y %H:%M:%S:%3N')" \
&& nix flake lock \
&& git add . \
&& git commit -m 'Second nix flake commit'"$(date +'%d/%m/%Y %H:%M:%S:%3N')" \
&& git status
```

```bash
nix flake show .#
```


###

```bash
nix \
build \
--impure \
--expr \
'
(
  let
    overlay = (final: prev:
      let
        myOverride = {
          packageOverrides = pyFinal: pyPrev: {
            opentelemetry-instrumentation-asgi = pyPrev.opentelemetry-instrumentation-asgi.overridePythonAttrs (_: { doCheck = true; });
          };
        };
        in {
          python3 = prev.python3.override myOverride;
          python3Packages = final.python3.pkgs;
        }
      );
  
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/0b6fa5ee40c14df33494d4ed9da1251e872fb0c2");
    pkgs = import nixpkgs { overlays = [ overlay ]; };    
  in
    pkgs.python3Packages.opentelemetry-instrumentation-asgi
)
'
```


pkgs.python3.pkgs.opentelemetry-instrumentation-asgi

b7ac9d147b09455ca948ef8eba72c872932f55f1


```bash
nix build github:NixOS/nixpkgs/407ba0172149f7a17581db8925579c7c1ff1f783#python3Packages.opentelemetry-instrumentation-asgi -L
```






```bash
nix \
build \
--impure \
--expr \
'
(
  let
    overlay = (final: prev:
      let
        myOverride = {
          packageOverrides = pyFinal: pyPrev: {
            opentelemetry-api = pyPrev.opentelemetry-api.overridePythonAttrs (_: rec { 
              src = prev.fetchFromGitHub {
                hash = "sha256-40IhNeBrtXkbFCuFNq9YuniMcQi3Vw5lHwSUKaFHP4k=";
                rev = "6583a83fdcdafbb1f060d714a7921ebd112ad316";
                owner = "xrmx";
                repo = "opentelemetry-python";
                name = "opentelemetry-python";
              };
              sourceRoot = "${src.name}/opentelemetry-api";
              version = "1.26.0";
              doCheck = false; # https://github.com/NixOS/nixpkgs/pull/227333/files#diff-3409c58bba42eaab6e834e12ca33f5ae33d96f06ebd0105d309bfbb3e9461692R46
            });
            opentelemetry-instrumentation = pyPrev.opentelemetry-instrumentation.overridePythonAttrs (_: rec { 
              dontCheckRuntimeDeps = true;
            });
            opentelemetry-instrumentation-asgi = pyPrev.opentelemetry-instrumentation-asgi.overridePythonAttrs (_: rec { 
              doCheck = false;
              dontCheckRuntimeDeps = true;
            });
          };
        };
        in {
          python3 = prev.python3.override myOverride;
          python3Packages = final.python3.pkgs;
        }
      );
  
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/0b6fa5ee40c14df33494d4ed9da1251e872fb0c2");
    pkgs = import nixpkgs { overlays = [ overlay ]; };    
  in
    # pkgs.python3Packages.opentelemetry-api
    # pkgs.python3Packages.opentelemetry-instrumentation
    pkgs.python3Packages.opentelemetry-instrumentation-asgi
)
'
```





opentelemetry-instrument uvicorn opentelemetry-instrumentation-fastapi:app --host 0.0.0.0 --port 8000


        # docker run --rm -ti --publish=8000:8000 python3-opentelemetry-instrumentation-fastapi:0.0.1
        python3WithOpentelemetryInstrumentationFastapiOCIImage = prev.dockerTools.buildImage {
          name = "python3-opentelemetry-instrumentation-fastapi";
          tag = "0.0.1";
          created = "now";
          copyToRoot = [
            final.appFastAPI
          ];
          config = {
            Cmd = [ "opentelemetry-instrument" "uvicorn" "opentelemetry-instrumentation-fastapi:app" "--host" "0.0.0.0" "--port" "8000" ];
            WorkingDir = "${final.appFastAPI}";
            Env = with prev; [
              "OTEL_INSTRUMENTATION_HTTP_CAPTURE_HEADERS_SERVER_RESPONSE='.*'"
            ];
          };
        };

python -m myFlaskServer
python -c 'import flask'
python -c 'import packageFlaskAPI'
python -c 'import myFlaskServer'







```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#pkgsStatic.hello) \
 | dot -Tps > pkgsStatic-hello.ps

okular pkgsStatic-hello.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#hello) \
 | dot -Tps > hello.ps

okular hello.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#readline) \
 | dot -Tps > readline.ps

okular readline.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#bash) \
 | dot -Tps > bash.ps

okular bash.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#bashInteractive) \
 | dot -Tps > bashInteractive.ps

okular bashInteractive.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#zsh) \
 | dot -Tps > zsh.ps

okular zsh.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#python3) \
 | dot -Tps > python3.ps

okular python3.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#python3Full) \
 | dot -Tps > python3Full.ps

okular python3Full.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#python3Minimal) \
 | dot -Tps > python3Minimal.ps

okular python3Minimal.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#pkgsMusl.python311) \
 | dot -Tps > pkgsMusl-python311.ps

okular pkgsMusl-python311.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#pkgsMusl.python3Minimal) \
 | dot -Tps > pkgsMusl-python3Minimal.ps

okular pkgsMusl-python3Minimal.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#pkgsStatic.python3Minimal) \
 | dot -Tps > pkgsStatic-python3Minimal.ps

okular pkgsStatic-python3Minimal.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#nodejs) \
 | dot -Tps > nodejs.ps

okular nodejs.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#nodejs-slim) \
 | dot -Tps > nodejs-slim.ps

okular nodejs-slim.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#git) \
 | dot -Tps > git.ps

okular git.ps
```


```bash
nix-store --query --graph --include-outputs --force-realise \
$(nix build --print-out-paths nixpkgs#ffmpeg-full) \
 | dot -Tps > ffmpeg-full.ps

okular ffmpeg-full.ps
```


```bash
nix path-info -rsSh $(nix path-info --derivation nixpkgs#hello)
```
