


Great references:
- https://nixcademy.com/posts/cross-compilation-with-nix/


At some point have you tried to run something like this:
```bash
docker run --entrypoint=/bin/sh -it --platform linux/amd64 amd64/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'

docker run --entrypoint=/bin/bash -it --platform linux/arm arm32v5/python:3.9.19-bookworm \
-c 'dpkg --print-architecture && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/arm arm32v6/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/arm arm32v7/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/arm64 arm64v8/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/s390x s390x/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/riscv64 riscv64/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/386 i386/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/mips64le mips64le/python:3.9.19-slim-bookworm \
-c 'dpkg --print-architecture && uname -m && python3 --version'

docker run --entrypoint=/bin/sh -it --platform linux/ppc64le ppc64le/python:3.9.19-alpine3.20 \
-c 'apk --print-arch && uname -m && python3 --version'
```
Refs.:
- https://hub.docker.com/_/python
- https://peps.python.org/pep-0011/
- https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=python3
- https://github.com/docker-library/python/issues/698#issuecomment-1036463695


and it seemed almost impossible?! Just use Nix! 


Why the version chosen is 3.9.19? Because that is the one that is avaliable in all arches.
```bash
270dace49bc95a7f88ad187969179ff0d2ba20ed
```


It made me really confused initially:
> For non-musl (so GNU libc), it's the awkwardly named gnu64.
> https://news.ycombinator.com/item?id=27825902


```bash
nix eval nixpkgs#pkgsCross.gnu64.stdenv.hostPlatform.config
nix eval nixpkgs#pkgsCross.aarch64-multiplatform.stdenv.hostPlatform.config
```
Refs.:
- https://nix.dev/tutorials/cross-compilation.html



```bash
nix eval nixpkgs#stdenv.hostPlatform.system
nix eval nixpkgs#lib.systems.parse.execFormats.macho
nix eval nixpkgs#stdenv.hostPlatform.parsed.cpu.name
nix eval nixpkgs#stdenv.hostPlatform.parsed.kernel.execFormat
```
Refs.:
- https://github.com/NixOS/nixpkgs/pull/235990/files#diff-2828f66a476875b1160e3c241960db085c2a3933211cc187bcd1fb456fb95e7fR76





```bash
nix flake show '.#'
nix flake metadata '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'
nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#' --rebuild

nix fmt '.#'

# nix flake check --verbose '.#'
```



TODO: check it, it made me really confused
https://github.com/NixOS/nixpkgs/issues/283098


TODO: Transform that in an flake and write NixOS tests for it!
```bash
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
  pkgs = import nixpkgs {};

  # Create a C program that prints Hello World
  helloWorld = pkgs.writeText "hello.c" ''
    #include <stdio.h>

    int main (void)
    {
      printf ("Hello, world!\n");
      return 0;
    }
  '';

  # A function that takes host platform packages
  crossCompileFor = hostPkgs:
    # Run a simple command with the compiler available
    hostPkgs.runCommandCC "hello-world-cross-test" {} ''
      # Wine requires home directory
      HOME=$PWD

      # Compile our example using the compiler specific to our host platform
      $CC ${helloWorld} -o hello

      # Run the compiled program using user mode emulation (Qemu/Wine)
      # buildPackages is passed so that emulation is built for the build platform
      ${hostPkgs.stdenv.hostPlatform.emulator hostPkgs.buildPackages} hello > $out

      # print to stdout
      cat $out
    '';
in {
  # Statically compile our example using the two platform hosts
  rpi = crossCompileFor pkgs.pkgsCross.raspberryPi;
  windows = crossCompileFor pkgs.pkgsCross.mingwW64;
}
```
Refs.:
- https://nix.dev/tutorials/cross-compilation.html#real-world-cross-compiling-of-a-hello-world-example




TODO: Test all expected things to happen?
It existis:
```bash
ls -alh /proc/sys/fs/binfmt_misc/aarch64-linux
```

Check its content:
```bash
cat /proc/sys/fs/binfmt_misc/aarch64-linux
```


TODO: how to build using Nix an OCI distroless image that does the same thinng?
```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64,riscv64,arm,s390x,ppc64le,mips64le
```


```bash
nix build --no-link --print-build-logs --print-out-paths \
github:NixOS/nixpkgs/fe866c653c24adf1520628236d4e70bbb2fdd949#pkgsCross.armv7l-hf-multiplatform.pkgsMusl.dockerTools.examples.layered-image
```



## Other images that do the same



```bash
docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d
```
Refs.:
- https://github.com/moby/moby/issues/44291#issuecomment-1642108937



## armv5tel "Illegal instruction" golang 1.21.0


TODO: try to test it!
```bash
package main
import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
```
Refs.:
- https://github.com/golang/go/issues/62475


## discourse NixOS

TODO: really hard to test that, maybe Vagrant VM?
My guess is that as it is from non-NixOS system it is an FHS PATH, and because that it does not appear 
in the sandbox, and as it is hardcoded when the sandbox is disabled it just finds the correct thing. 

https://discourse.nixos.org/t/issue-building-with-qemu-binfmt-on-non-nixos/10750

TODO: 
1) test that nix show-config have the sandbox paths added raleted to binfmt
2) try to call some operation durin build to prove that it is able to execute emulates code

##


TODO: test that!

```bash
docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d
```
https://github.com/moby/moby/issues/44291#issuecomment-1642108937

