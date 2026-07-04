# latex-symbols

Reproducible Nix flake that compiles *The Comprehensive LaTeX Symbol List*
by Scott Pakin (~271 pages, 225+ packages) from CTAN source via nixpkgs.

## Quick start

```bash
# Build the PDF (~271 pages)
nix build '.#' && ls result/

# Open in Firefox
nix run '.#firefox'

# Dev shell (pdflatex + Python3 on PATH)
nix develop

# Run all checks
nix run '.#allTests'
```

## How it works

Source is taken from `pkgs.texlive.comprehensive` (texdoc component).
Packages unavailable in nixpkgs are replaced by `fake*.sty` stubs shipped with the source.
Build: 4× pdflatex + 2× makeindex (with `patch-idx` and `prune-idx` for index normalization).

## Reference

Scott Pakin, *The Comprehensive LaTeX Symbol List*, CTAN package `comprehensive`.
