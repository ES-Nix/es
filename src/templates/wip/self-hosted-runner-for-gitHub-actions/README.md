

```bash
nix \
shell \
nixpkgs#github-runner \
--command \
sh \
-c \
'
  config.sh \
  --url https://github.com/ES-Nix/es \
  --pat "$PAT" \
  --ephemeral \
  --unattended \
  --replace \
  && run.sh
'
```
Refs.:
- ?

And manually:
```bash
gh workflow run tests.yml
```
