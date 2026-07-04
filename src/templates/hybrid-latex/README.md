# hybrid-latex NixOS flake

Packages [leo-brewin/hybrid-latex](https://github.com/leo-brewin/hybrid-latex) (v0.3, MIT) as a
reproducible Nix derivation. Embed and execute Python code blocks inside LaTeX documents.

## Quick start

```bash
# Build the sample PDF (integration test)
nix build .#sampleDoc && xdg-open result/main.pdf

# Dev shell (hybrid-latex + Python + TeX Live on PATH)
nix develop

# Run all checks
nix run '.#allTests'

# Run pylatex.sh on your own document
nix run '.#' -- -s -i mydoc
```

## How it works

1. Write `mydoc.tex` with `\begin{python}...\end{python}` blocks and `# py (tag.lineno, expr)` annotations.
2. `pylatex.sh -s -i mydoc` runs the pipeline:
   - `pypreproc.py` extracts Python → `mydoc_.py`
   - Python executes → `mydoc.pytxt`
   - `pypostproc.py` formats → `mydoc.pytex`
   - `pdflatex` compiles (auto-includes `mydoc.pytex`)
3. Use `\py{tag}` / `\py*{tag}` in the document to embed computed results.

## Flake outputs

| Output | Description |
|--------|-------------|
| `packages.hybrid-latex` | Packaged tool (bin/ lib/ tex/) |
| `packages.sampleDoc` | Built sample PDF — integration test |
| `packages.default` | Same as `sampleDoc` |
| `apps.default` | `pylatex.sh` |
| `checks.sample` | `nix flake check` integration test |
| `devShells.default` | Shell with all tools on PATH |
| `formatter` | `nixpkgs-fmt` |

## References

- https://github.com/leo-brewin/hybrid-latex
