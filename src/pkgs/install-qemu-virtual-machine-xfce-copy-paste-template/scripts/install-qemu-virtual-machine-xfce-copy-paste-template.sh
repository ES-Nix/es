#!/usr/bin/env bash


# $(nix eval --impure --raw --expr 'builtins.currentSystem').

mkdir -pv QEMUVirtualMachineXfceCopyPaste \
&& cd QEMUVirtualMachineXfceCopyPaste \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#QEMUVirtualMachineXfceCopyPaste

direnv allow

git init \
&& git status \
&& git add . \
&& git status \
&& nix \
   flake \
   lock \
   --override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
   --override-input flake-utils github:numtide/flake-utils/5aed5285a952e0b949eb3ba02c12fa4fcfef535f

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm
