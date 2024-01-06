#!/usr/bin/env bash


# $(nix eval --impure --raw --expr 'builtins.currentSystem').

mkdir -pv QEMUVirtualMachineXfceCopyPasteMinimal \
&& cd QEMUVirtualMachineXfceCopyPasteMinimal \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#QEMUVirtualMachineXfceCopyPasteMinimal

direnv allow

git init \
&& git status \
&& git add . \
&& git status \
&& nix \
   flake \
   lock \
   --override-input nixpkgs github:NixOS/nixpkgs/9c8bff77b5d51380f5da349d0a6fc515da6244b0 \
   --override-input flake-utils github:numtide/flake-utils/5aed5285a952e0b949eb3ba02c12fa4fcfef535f

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm
