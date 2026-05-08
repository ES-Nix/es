

```bash
nix run '.#allTests'
```


It is broken, see the issue.
```bash
nix build --cores 8 --no-link --print-build-logs --print-out-paths --impure \
--override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
'./src/templates/valkey-static'


nix build --cores 8 --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/a82ccc39b39b621151d6732718e3e250109076fa#valkey'

```
Refs.:
- https://github.com/NixOS/nixpkgs/issues/387010
