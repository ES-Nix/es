

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash
nix run '.#testNixAutoChrootStoreDriverInteractive'
```


```bash
nix run '.#testNixIssue9194DriverInteractive'
```


```bash
nix run '.#allTests'
```
