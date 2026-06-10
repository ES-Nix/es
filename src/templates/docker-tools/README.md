nix run '.#allTests'

Images (nixpkgs#dockerTools.examples):
- `bash:latest` — bash shell
- `redis:latest` — redis service layered on bash

```bash
# load and run
nix build --impure --no-link --print-out-paths '.#bash' | docker load
nix build --impure --no-link --print-out-paths '.#redis' | docker load

docker run --rm bash:latest bash -c 'echo hello'
docker run --rm -d --name demo-redis redis:latest && docker exec demo-redis /bin/healthcheck
```
