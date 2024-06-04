

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


github:NixOS/nixpkgs/

nixos-22.11-begin bd15cafc53d0aecd90398dd3ffc83a908bceb734
nixos-22.11-end ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b

nixos-23.05-begin 90d94ea32eed9991e2b8c6a761ccd8145935c57c
nixos-23.05-end 70bdadeb94ffc8806c0570eb5c2695ad29f0e421

nixos-23.11-begin 7c6e3666e2040fb64d43b209b84f65898ea3095d
nixos-23.11-end 25cf937a30bf0801447f6bf544fc7486c6309234

nixos-24.05-begin 5646423bfac84ec68dfc60f2a322e627ef0d6a95
nixos-24.05-end d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8
