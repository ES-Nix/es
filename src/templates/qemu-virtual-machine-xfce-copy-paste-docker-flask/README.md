

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

```bash
curl http://localhost:5002/
```

```bash
docker compose down
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




```bash
docker \
run \
--tty=true \
--interactive=true \
--rm=true \
docker.io/nixpkgs/nix-flakes \
bash
```



https://docs.docker.com/compose/gettingstarted/#step-1-set-up




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
