# pandoc-format-matrix

Nix flake template with 11 named derivations, each a separate build step:

```
sample/ (paper.md + references.bib)
    ├── pandocAst           → ast.json          (pandoc AST, raw Citation nodes)
    ├── markdownCiteproc    → resolved.md        (citations as inline text)
    │   └── rst             → paper.rst          (chained from resolved.md)
    ├── latexSource         → paper.tex          (--standalone --citeproc)
    │   ├── pdfXelatex      → paper-xelatex.pdf
    │   └── pdfLualatex     → paper-lualatex.pdf
    ├── htmlCiteproc        → paper.html         (--mathjax)
    │   └── pdfWeasyprint   → paper-weasyprint.pdf
    ├── htmlKatex           → paper-katex.html   (--katex)
    ├── epub                → paper.epub
    └── docx                → paper.docx
```

## Usage

```bash
nix build .#pandocAst       # inspect pandoc's internal AST
nix build .#latexSource     # see the LaTeX pandoc generates
nix build .#pdfXelatex      # PDF via xelatex
nix build .#pdfLualatex     # PDF via lualatex
nix build .#htmlCiteproc    # HTML with MathJax
nix build .#htmlKatex       # HTML with KaTeX
nix build .#pdfWeasyprint   # PDF via weasyprint (HTML→PDF)
nix build .#epub
nix build .#docx
nix build .#rst

nix run .#allTests          # build everything
```
