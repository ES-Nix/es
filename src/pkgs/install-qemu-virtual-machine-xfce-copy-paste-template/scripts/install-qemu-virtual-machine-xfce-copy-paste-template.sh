#!/usr/bin/env bash


mkdir -pv QEMUVirtualMachineXfceCopyPaste \
&& cd QEMUVirtualMachineXfceCopyPaste \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#QEMUVirtualMachineXfceCopyPaste

direnv allow || true

git init \
&& git status \
&& git add . \
&& git status

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
