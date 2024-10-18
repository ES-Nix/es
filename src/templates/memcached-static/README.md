


```bash
nix flake show '.#'

nix build --cores 5 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```
Refs.:
- https://book.hacktricks.xyz/network-services-pentesting/11211-memcache#manual



TODO: https://github.com/docker-library/memcached/blob/c75c22c45a0a79124becdc38b3c005b0b820ea20/1/alpine/Dockerfile#L9-L12