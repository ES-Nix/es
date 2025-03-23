



https://matthewbauer.us/blog/all-the-versions.html


```bash
git ls-remote --exit-code --tags --refs \
https://github.com/NixOS/nixpkgs.git "refs/tags/21.11" | cut -f1
```
Refs.:
- https://stackoverflow.com/questions/64268055/when-listing-remote-tags-in-git-what-does-signify
- https://stackoverflow.com/a/67682506
- https://stackoverflow.com/a/52699078
- https://nixos.github.io/release-wiki/Branch-Off.html#on-the-master-branch
- https://stackoverflow.com/a/15949160





```bash
nixos-20.03-begin 506445d88e183bce80e47fc612c710eb592045ed
nixos-20.03 1db42b7fe3878f3f5f7a4f2dc210772fd080e205

nixos-20.09-begin aea7242187f21a120fe73b5099c4167e12ec9aab
nixos-20.09 1c1f5649bb9c1b0d98637c8c365228f57126f361

nixos-21-11-begin 506445d88e183bce80e47fc612c710eb592045ed
nixos-21-11 eabc38219184cc3e04a974fe31857d8e0eac098d

nixos-22.05-begin 7a94fcdda304d143f9a40006c033d7e190311b54
nixos-22.05 380be19fbd2d9079f677978361792cb25e8a3635

nixos-22.11-begin bd15cafc53d0aecd90398dd3ffc83a908bceb734
nixos-22.11 ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b

nixos-23.05-begin 90d94ea32eed9991e2b8c6a761ccd8145935c57c
nixos-23.05 70bdadeb94ffc8806c0570eb5c2695ad29f0e421

nixos-23.11-begin 7c6e3666e2040fb64d43b209b84f65898ea3095d
nixos-23.11 205fd4226592cc83fd4c0885a3e4c9c400efabb5

nixos-24.05-begin 5646423bfac84ec68dfc60f2a322e627ef0d6a95
nixos-24.05 b134951a4c9f3c995fd7be05f3243f8ecd65d798

nixos-24.11-begin aae12a743f75097dd3a60a8265978b995298babc
nixos-24.11 1546c45c538633ae40b93e2d14e0bb6fd8f13347
nixos-24.11 cdd2ef009676ac92b715ff26630164bb88fec4e0

# nix flake metadata github:NixOS/nixpkgs/nixos-unstable --refresh
nixos-unstable ba487dbc9d04e0634c64e3b1f0d25839a0a68246
```
