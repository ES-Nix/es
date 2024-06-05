

```bash
mkdir -pv devShellHello \
&& cd devShellHello \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#devShellHello
```
Refs.:
- https://godot-rust.github.io/gdnative-book/recipes/nix-build-system.html
