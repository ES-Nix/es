

Inspired by: 
- [Running NixOS Tests with Nix Flakes](https://blakesmith.me/2024/03/02/running-nixos-tests-with-flakes.html)
- [Writing a NixOS service module](https://scvalex.net/posts/58/)
- [Saved by NixOS Integration Tests, Surprisingly](https://boinkor.net/2024/02/saved-by-nixos-integration-tests-surprisingly/)


```bash
nix build -L '.#checks.x86_64-linux.helloNixosTest'
```


```bash
nix run '.#checks.x86_64-linux.helloNixosTest.driverInteractive'
```


```bash
# In the python prompt, the one >>>
start_all()
run_tests()
```


## Extras



```bash
nix build '.#checks.aarch64-linux.helloNixosTest'
```

```bash
error: a 'aarch64-linux' with features {} is required to build 
'/nix/store/bkby99bafd47j3hr2rkfqns0fl2qsfj0-append-initrd-secrets.drv', 
but I am a 'x86_64-linux' with features {benchmark, big-parallel, kvm, nixos-test} 
```
