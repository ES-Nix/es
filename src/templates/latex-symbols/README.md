# latex-symbols

Reproducible Nix flake producing a PDF reference of the Comprehensive LaTeX Symbol List.
Covers symbols from: `amsmath`, `amssymb`, `wasysym`, `marvosym`, `pifont`, `stmaryrd`, `ifsym`, `textcomp`.

## Quick start

```bash
# Build the PDF
nix build '.#' && ls result/

# Open in Firefox
nix run '.#firefox'

# Dev shell (pdflatex + all packages on PATH)
nix develop

# Run all checks
nix run '.#allTests'
```

## Symbol categories

| Section | Package |
|---------|---------|
| Greek Letters | LaTeX core |
| Binary Operators | LaTeX core |
| Relation Symbols | LaTeX core |
| Arrows | LaTeX core |
| AMS Math | `amssymb` |
| AMS Arrows | `amssymb` |
| Miscellaneous Math | LaTeX core + `amssymb` |
| Large Operators | `amsmath` |
| Text Mode | `textcomp` |
| Wasysym (planets, zodiac) | `wasysym` |
| Marvosym (comm, currency, zodiac) | `marvosym` |
| Pifont Dingbats | `pifont` (via `psnfss`) |
| St Mary Road | `stmaryrd` |
| ifsym Clocks & Alpine | `ifsym` |

## Reference

Based on *The Comprehensive LaTeX Symbol List* by Scott Pakin.
