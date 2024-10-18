# github self-hosted runner em uma máquina virtual NixOS usando systemd


Generating a token:
- https://github.com/settings/tokens
- with these checks: https://github.com/myoung34/docker-github-actions-runner/wiki/Usage#token-scope



```bash
nix flake show '.#'

nix build --cores 8 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```

```bash
rm -fv nixos.qcow2;  

nix run --impure --refresh --verbose .#
```


```bash
cp -v .env.example .env
test -f .env && source .env
```


Passo 2: Injetando manualmente o PAT. No terminal da VM use 
"seta para cima" (para acessar o histórico):
```bash
run-github-runner && sudo systemctl restart github-runner-nixos.service
```


Passo 3: Verifique que o runner aparece no link:
https://github.com/ES-Nix/es/actions/runners?tab=self-hosted


Passo 4: No terminal do clone local (apenas para testes manuais) do repositório:
```bash
export GH_TOKEN=ghp_yyyyyyyyyyyyyyy
```


Passo 5: Iniciando manualmente o workflow 
Note: o remoto tenta iniciar a execução com o código que está no REMOTO, ou seja,
modificações apenas locais não são executadas.
```bash
gh workflow run tests.yml --ref branch-name
```
Refs.:
- https://docs.github.com/en/enterprise-server@3.11/actions/using-workflows/manually-running-a-workflow?tool=cli#running-a-workflow


Pelo navegador:
https://github.com/ES-Nix/es/actions
