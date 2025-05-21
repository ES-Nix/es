


```bash
nix flake metadata --json \
'.?dir=src/templates/qemu-virtual-machine-docker' \
| jq ".locks.nodes.root.inputs | keys"
```

```bash
nix flake info --json \
'.?dir=src/templates/qemu-virtual-machine-docker' \
| jq ".locks.nodes.root.inputs | keys"
```
Refs.:
- https://discourse.nixos.org/t/nix-flake-lock-how-to-exclude-input-from-update/51633
- https://github.com/NixOS/nix/issues/10015
