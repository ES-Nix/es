{
  description = "Pandoc format transformation matrix — academic paper through all common output formats";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

        texForXelatex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-small collection-xetex
            amsmath fontspec hyperref natbib lm tex-gyre tex-gyre-math;
        };

        texForLualatex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-small collection-luatex
            amsmath fontspec hyperref natbib lm tex-gyre tex-gyre-math;
        };

        pandocAst = pkgs.stdenvNoCC.mkDerivation {
          name = "pandoc-ast";
          src = ./sample;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = "pandoc --to json paper.md -o ast.json";
          installPhase = "mkdir -p $out && cp ast.json $out/";
          dontFixup = true;
        };

        markdownCiteproc = pkgs.stdenvNoCC.mkDerivation {
          name = "markdown-citeproc";
          src = ./sample;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            pandoc --citeproc --bibliography references.bib \
              --to markdown paper.md -o resolved.md
          '';
          installPhase = "mkdir -p $out && cp resolved.md $out/";
          dontFixup = true;
        };

        latexSource = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-source";
          src = ./sample;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            pandoc --standalone --bibliography references.bib \
              --natbib \
              -V colorlinks=true -V citecolor=Blue -V urlcolor=Blue \
              --to latex paper.md -o paper.tex
          '';
          installPhase = "mkdir -p $out && cp paper.tex references.bib $out/";
          dontFixup = true;
        };

        pdfXelatex = pkgs.stdenvNoCC.mkDerivation {
          name = "pdf-xelatex";
          dontUnpack = true;
          nativeBuildInputs = [ texForXelatex ];
          TEXMFHOME = "./texmf";
          TEXMFVAR = "./texmf-var";
          buildPhase = ''
            cp ${latexSource}/paper.tex .
            cp ${latexSource}/references.bib .
            xelatex -interaction=nonstopmode paper.tex
            bibtex paper
            xelatex -interaction=nonstopmode paper.tex
            xelatex -interaction=nonstopmode paper.tex
          '';
          installPhase = "mkdir -p $out && cp paper.pdf $out/paper-xelatex.pdf";
          dontPatchELF = true;
          dontFixup = true;
        };

        pdfLualatex = pkgs.stdenvNoCC.mkDerivation {
          name = "pdf-lualatex";
          dontUnpack = true;
          nativeBuildInputs = [ texForLualatex ];
          TEXMFHOME = "./texmf";
          TEXMFVAR = "./texmf-var";
          buildPhase = ''
            cp ${latexSource}/paper.tex .
            cp ${latexSource}/references.bib .
            lualatex -interaction=nonstopmode paper.tex
            bibtex paper
            lualatex -interaction=nonstopmode paper.tex
            lualatex -interaction=nonstopmode paper.tex
          '';
          installPhase = "mkdir -p $out && cp paper.pdf $out/paper-lualatex.pdf";
          dontPatchELF = true;
          dontFixup = true;
        };

        htmlCiteproc = pkgs.stdenvNoCC.mkDerivation {
          name = "html-citeproc";
          src = ./sample;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            pandoc --standalone --citeproc --bibliography references.bib \
              --mathjax paper.md -o paper.html
          '';
          installPhase = "mkdir -p $out && cp paper.html $out/";
          dontFixup = true;
        };

        htmlKatex = pkgs.stdenvNoCC.mkDerivation {
          name = "html-katex";
          src = ./sample;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            pandoc --standalone --citeproc --bibliography references.bib \
              --katex paper.md -o paper-katex.html
          '';
          installPhase = "mkdir -p $out && cp paper-katex.html $out/";
          dontFixup = true;
        };

        pdfWeasyprint = pkgs.stdenvNoCC.mkDerivation {
          name = "pdf-weasyprint";
          dontUnpack = true;
          nativeBuildInputs = [ pkgs.python3Packages.weasyprint ];
          buildPhase = ''
            export HOME=$(mktemp -d)
            export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
            weasyprint ${htmlCiteproc}/paper.html paper-weasyprint.pdf
          '';
          installPhase = "mkdir -p $out && cp paper-weasyprint.pdf $out/";
          dontFixup = true;
        };

        epub = pkgs.stdenvNoCC.mkDerivation {
          name = "epub";
          src = ./sample;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            pandoc --standalone --citeproc --bibliography references.bib \
              paper.md -o paper.epub
          '';
          installPhase = "mkdir -p $out && cp paper.epub $out/";
          dontFixup = true;
        };

        docx = pkgs.stdenvNoCC.mkDerivation {
          name = "docx";
          src = ./sample;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            pandoc --standalone --citeproc --bibliography references.bib \
              paper.md -o paper.docx
          '';
          installPhase = "mkdir -p $out && cp paper.docx $out/";
          dontFixup = true;
        };

        testPdfLinks = pkgs.stdenvNoCC.mkDerivation {
          name = "test-pdf-links";
          dontUnpack = true;
          nativeBuildInputs = [ pkgs.python3Packages.pymupdf ];
          buildPhase = ''
            python3 - <<'EOF'
import fitz
import sys

def check_links(path, label):
    doc = fitz.open(path)
    total = sum(len(page.get_links()) for page in doc)
    if total == 0:
        print(f"FAIL: {label} — no link annotations", file=sys.stderr)
        sys.exit(1)
    print(f"OK: {label} — {total} link(s)")

check_links("${pdfXelatex}/paper-xelatex.pdf", "xelatex")
check_links("${pdfLualatex}/paper-lualatex.pdf", "lualatex")
EOF
          '';
          installPhase = "mkdir -p $out && echo passed > $out/result";
          dontFixup = true;
        };

        testPdfColorLinks = pkgs.runCommand "test-pdf-color-links" {
          nativeBuildInputs = [
            pkgs.python3Packages.pymupdf
            pkgs.python3Packages.opencv4
            pkgs.python3Packages.numpy
          ];
        } ''
          python3 - <<'EOF'
import fitz, cv2, numpy as np, sys

doc = fitz.open("${pdfXelatex}/paper-xelatex.pdf")
pix = doc[0].get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
img = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3)
bgr = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)

mask = cv2.inRange(hsv, np.array([100, 60, 60]), np.array([135, 255, 255]))
n, _, stats, _ = cv2.connectedComponentsWithStats(mask)
regions = [i for i in range(1, n) if stats[i, cv2.CC_STAT_AREA] >= 20]
print(f"blue regions: {len(regions)}")

if len(regions) < 4:
    print(f"FAIL: expected >= 4 blue citation regions, got {len(regions)}", file=sys.stderr)
    sys.exit(1)
print(f"OK: {len(regions)} blue citation region(s)")
EOF
          mkdir -p $out && echo passed > $out/result
        '';

        testPdfLinkDests = pkgs.runCommand "test-pdf-link-dests" {
          nativeBuildInputs = [ pkgs.qpdf pkgs.python3 ];
        } ''
          python3 - <<'EOF'
import subprocess, json, sys

data = json.loads(subprocess.check_output(
    ['qpdf', '--json', '${pdfXelatex}/paper-xelatex.pdf']))

# qpdf JSON v2: data['qpdf'] = [header, objects_dict]
objs = {}
for item in data.get('qpdf', []):
    if isinstance(item, dict):
        objs.update(item)

# 1. Collect Link annotations with GoTo actions → gather dest names
cite_dests = set()
for k, v in objs.items():
    if not isinstance(v, dict): continue
    val = v.get('value', {})
    if not isinstance(val, dict): continue
    if val.get('/Subtype') != '/Link': continue
    action = val.get('/A', {})
    if not isinstance(action, dict): continue
    dest = action.get('/D', ''')
    if isinstance(dest, str) and dest.startswith('u:cite.'):
        cite_dests.add(dest[2:])  # strip 'u:' prefix

print(f"GoTo citation destinations in annotations: {sorted(cite_dests)}")
if len(cite_dests) < 4:
    print(f"FAIL: expected >= 4 unique cite.* destinations, got {len(cite_dests)}", file=sys.stderr)
    sys.exit(1)

# 2. Walk PDF Names/Dests tree and collect all named destinations
catalog = objs['obj:1 0 R']['value']
names_ref = catalog['/Names']
dests_ref = objs[f'obj:{names_ref}']['value']['/Dests']
kids      = objs[f'obj:{dests_ref}']['value'].get('/Kids', [])

named_dests = {}
for kid_ref in kids:
    entries = objs[f'obj:{kid_ref}']['value'].get('/Names', [])
    for i in range(0, len(entries) - 1, 2):
        name = entries[i]
        if isinstance(name, str) and name.startswith('u:'):
            name = name[2:]
        dest_val = entries[i + 1]
        if isinstance(dest_val, str) and dest_val.endswith(' R'):
            dest_val = objs[f'obj:{dest_val}']['value']
        named_dests[name] = dest_val

print(f"Named destinations in PDF: {sorted(named_dests.keys())}")

# 3. Verify every annotation destination exists in the Names tree
#    and resolves to an array whose first element is a page object ref
missing = [d for d in cite_dests if d not in named_dests]
if missing:
    print(f"FAIL: destinations missing from PDF Names tree: {missing}", file=sys.stderr)
    sys.exit(1)

for dest_name in cite_dests:
    dest = named_dests[dest_name]
    if not (isinstance(dest, list) and len(dest) >= 1 and
            isinstance(dest[0], str) and dest[0].endswith(' R')):
        print(f"FAIL: destination '{dest_name}' doesn't resolve to a page ref: {dest}", file=sys.stderr)
        sys.exit(1)

print(f"OK: all {len(cite_dests)} citation destinations resolve to bibliography page")
EOF
          mkdir -p $out && echo passed > $out/result
        '';

        rst = pkgs.stdenvNoCC.mkDerivation {
          name = "rst";
          dontUnpack = true;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            pandoc --to rst ${markdownCiteproc}/resolved.md -o paper.rst
          '';
          installPhase = "mkdir -p $out && cp paper.rst $out/";
          dontFixup = true;
        };

        allTests =
          let name = "all-tests"; in
          pkgs.writeShellApplication
            {
              inherit name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show --all-systems '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#pandocAst' \
                && nix build --no-link --print-build-logs --print-out-paths '.#markdownCiteproc' \
                && nix build --no-link --print-build-logs --print-out-paths '.#latexSource' \
                && nix build --no-link --print-build-logs --print-out-paths '.#pdfXelatex' \
                && nix build --no-link --print-build-logs --print-out-paths '.#pdfLualatex' \
                && nix build --no-link --print-build-logs --print-out-paths '.#htmlCiteproc' \
                && nix build --no-link --print-build-logs --print-out-paths '.#htmlKatex' \
                && nix build --no-link --print-build-logs --print-out-paths '.#pdfWeasyprint' \
                && nix build --no-link --print-build-logs --print-out-paths '.#epub' \
                && nix build --no-link --print-build-logs --print-out-paths '.#docx' \
                && nix build --no-link --print-build-logs --print-out-paths '.#rst' \
                && nix build --no-link --print-build-logs --print-out-paths '.#testPdfLinks' \
                && nix build --no-link --print-build-logs --print-out-paths '.#testPdfColorLinks' \
                && nix build --no-link --print-build-logs --print-out-paths '.#testPdfLinkDests' \
                && nix flake check --all-systems --verbose '.#'
              '';
            } // { meta.mainProgram = name; };

      in
      {
        packages = {
          default = pdfXelatex;
          inherit pandocAst markdownCiteproc latexSource
            pdfXelatex pdfLualatex
            htmlCiteproc htmlKatex pdfWeasyprint
            epub docx rst testPdfLinks testPdfColorLinks testPdfLinkDests
            allTests;
        };

        apps = {
          default = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-pdf-xelatex" ''
              ${pkgs.kdePackages.okular}/bin/okular "${pdfXelatex}/paper-xelatex.pdf"
            '');
          };
          openPdfXelatex = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-pdf-xelatex" ''
              ${pkgs.kdePackages.okular}/bin/okular "${pdfXelatex}/paper-xelatex.pdf"
            '');
          };
          openPdfLualatex = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-pdf-lualatex" ''
              ${pkgs.kdePackages.okular}/bin/okular "${pdfLualatex}/paper-lualatex.pdf"
            '');
          };
          openPdfWeasyprint = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-pdf-weasyprint" ''
              ${pkgs.firefox}/bin/firefox "${pdfWeasyprint}/paper-weasyprint.pdf"
            '');
          };
          openHtmlCiteproc = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-html-citeproc" ''
              ${pkgs.firefox}/bin/firefox "${htmlCiteproc}/paper.html"
            '');
          };
          openHtmlKatex = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-html-katex" ''
              ${pkgs.firefox}/bin/firefox "${htmlKatex}/paper-katex.html"
            '');
          };
          allTests = {
            type = "app";
            program = pkgs.lib.getExe allTests;
          };
        };

        checks = {
          inherit pdfXelatex pdfLualatex htmlCiteproc htmlKatex
            pdfWeasyprint epub docx testPdfLinks testPdfColorLinks testPdfLinkDests;
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.pandoc pkgs.nixpkgs-fmt ];
        };
      }
    );
}
