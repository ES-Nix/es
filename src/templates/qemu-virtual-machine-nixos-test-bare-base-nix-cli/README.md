

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash
nix run '.#allTests'
```
