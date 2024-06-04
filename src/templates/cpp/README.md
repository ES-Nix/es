
```bash
cat > main.cpp <<-'EOF'
#include <iostream>
int main() {
    std::cout << "Hello world!" << std::endl;
    return 0;
}
EOF


nix shell -i nixpkgs#bashInteractive nixpkgs#llvmPackages_17.libstdcxxClang -c clang++ main.cpp
nix shell nixpkgs#bashInteractive nixpkgs#llvmPackages_17.libstdcxxClang -c clang++ main.cpp

./a.out
```
Refs.:
- https://discourse.nixos.org/t/c-and-libstdc-not-available/39126/9

```bash
# mktemp: command not found
```
Refs.:
- https://github.com/NixOS/nixpkgs/issues/316674
- 


```bash
nix build --print-build-logs --print-out-paths \
github:NixOS/nixpkgs/nixpkgs-unstable#pkgsCross.aarch64-multiplatform.pkgsLLVM.libunwind
```
Refs.:
- https://github.com/NixOS/nixpkgs/issues/313287

```bash
NIX_DEBUG=1 clang -fuse-ld=lld -v main.c
```
Refs.:
- https://github.com/NixOS/nixpkgs/issues/201591#issuecomment-2009484069
