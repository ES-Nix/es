#!/usr/bin/env bash



nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#$(nix eval --impure --raw --expr 'builtins.currentSystem').startConfig

git init \
&& git status \
&& git add . \
&& git status \
&& nix flake lock \
      --override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b