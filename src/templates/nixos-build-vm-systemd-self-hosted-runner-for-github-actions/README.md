# github self-hosted runner em uma máquina virtual NixOS usando systemd



```bash
nix fmt . \
&& nix flake show --allow-import-from-derivation --impure --refresh .# \
&& nix flake metadata --impure '.#' \
&& nix build --impure --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop --impure '.#' --command sh -c 'true' \
&& nix flake check --all-systems --impure --verbose '.#' \
&& git add .
```


Passo 1: 
Generating a token:
- https://github.com/settings/tokens
- with these checks: https://github.com/myoung34/docker-github-actions-runner/wiki/Usage#token-scope


Passo 2:
```bash
test -f .env || cp -v .env.example .env
test -f .env && source .env
```

Passo 3:
Adicione o PAT no .env!


Passo 4:
```bash
rm -fv nixos.qcow2; 
nix run --impure --refresh --verbose .#
```


Passo 5: Verifique que o runner aparece no link:
https://github.com/ES-Nix/es/actions/runners?tab=self-hosted


Passo 6: No terminal do clone local (apenas para testes manuais) do repositório:
```bash
export GH_TOKEN=ghp_yyyyyy
```

Passo 7: Iniciando manualmente o workflow 
Note: o remoto tenta iniciar a execução com o código que está no REMOTO, ou seja,
modificações apenas locais não são executadas.
```bash
gh workflow run tests.yml --ref branch-name
```
Refs.:
- https://docs.github.com/en/enterprise-server@3.11/actions/using-workflows/manually-running-a-workflow?tool=cli#running-a-workflow


Pelo navegador:
https://github.com/ES-Nix/es/actions
