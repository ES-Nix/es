{
  description = "PDF-to-Markdown reconstruction via citation-annotation roundtrip";

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

        # ── STAGE 0: produce the sample input PDF ──────────────────────────
        # In production, replace samplePdf with a derivation that provides
        # your own PDF at $out/paper.pdf.

        latexSourceForSample = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-source-for-sample";
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

        samplePdf = pkgs.stdenvNoCC.mkDerivation {
          name = "sample-pdf";
          dontUnpack = true;
          nativeBuildInputs = [ texForXelatex ];
          TEXMFHOME = "./texmf";
          TEXMFVAR = "./texmf-var";
          buildPhase = ''
            cp ${latexSourceForSample}/paper.tex .
            cp ${latexSourceForSample}/references.bib .
            xelatex -interaction=nonstopmode paper.tex
            bibtex paper
            xelatex -interaction=nonstopmode paper.tex
            xelatex -interaction=nonstopmode paper.tex
          '';
          installPhase = "mkdir -p $out && cp paper.pdf $out/paper.pdf";
          dontPatchELF = true;
          dontFixup = true;
        };

        # ── STAGE 1: extract citation link annotations via raw PDF object access ─
        # pdftohtml does not preserve GoTo named-destination hrefs; instead we
        # use pymupdf's xref_object() to read the raw /A /D value from each
        # Link annotation and pair it with the text at the link bounding box.

        extractAnnotations = pkgs.runCommand "extract-annotations"
          {
            nativeBuildInputs = [ pkgs.python3Packages.pymupdf ];
          } ''
                    mkdir -p $out
                    python3 - <<EOF
          import fitz, json, sys
          from collections import defaultdict

          doc = fitz.open("${samplePdf}/paper.pdf")

          # pymupdf >= 1.23 exposes link['nameddest'] for named-destination GoTo links
          # (what natbib+hyperref produces).  natbib emits TWO link annotations per
          # citation: one for "[Author," and one for "Year]".  We collect overlapping
          # words per cite key and extract the author name from the "[Author," word.
          key_words = defaultdict(list)
          for page_num, page in enumerate(doc):
              words = page.get_text('words')
              for link in page.get_links():
                  named = link.get('nameddest', "")
                  if not named.startswith('cite.'):
                      continue
                  cite_key = named[len('cite.'):]
                  lr = fitz.Rect(link['from'])
                  key_words[cite_key].extend(w[4] for w in words if fitz.Rect(w[:4]).intersects(lr))

          result = []
          seen = set()
          for cite_key, wlist in key_words.items():
              if cite_key in seen:
                  continue
              seen.add(cite_key)
              open_words = [w for w in wlist if w.startswith('[') and ',' in w]
              if not open_words:
                  continue
              author = open_words[0].lstrip('[').rstrip(',').strip()
              if author:
                  result.append({'author': author, 'cite_key': cite_key})

          with open("$out/links.json", 'w') as f:
              json.dump(result, f, ensure_ascii=False, indent=2)
          print(f"Extracted {len(result)} citation(s):", file=sys.stderr)
          for r in result:
              print(f"  [{r['author']}, YEAR] -> {r['cite_key']}", file=sys.stderr)
          EOF
        '';

        # ── STAGE 2: extract plain body text ──────────────────────────────

        extractText = pkgs.runCommand "extract-text"
          {
            nativeBuildInputs = [ pkgs.python3Packages.pymupdf ];
          } ''
                    mkdir -p $out
                    python3 - <<EOF
          import fitz, sys

          doc = fitz.open("${samplePdf}/paper.pdf")
          parts = []
          for page in doc:
              parts.append(page.get_text('text'))
          text = '\n'.join(parts)
          with open("$out/raw.txt", 'w') as f:
              f.write(text)
          print(f"Extracted {len(doc)} page(s), {len(text)} chars", file=sys.stderr)
          EOF
        '';

        # ── STAGE 3: inject citation syntax, strip extracted bibliography ─

        reconstructMd = pkgs.runCommand "reconstruct-md"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          } ''
                    mkdir -p $out
                    python3 - <<PYEOF
          import json, re, sys

          with open("${extractAnnotations}/links.json") as f:
              links = json.load(f)

          with open("${extractText}/raw.txt") as f:
              content = f.read()

          # natbib renders citations as [Author, Year]; replace with pandoc [@cite_key]
          for entry in links:
              author = re.escape(entry['author'])
              key = entry['cite_key']
              content = re.sub(r'\[' + author + r',\s*\d{4}\]', '[@' + key + ']', content)

          # Drop bibliography section — bibtex regenerates it from references.bib
          content = re.split(r'\nReferences\n|\nBibliography\n', content, maxsplit=1)[0]

          # Use first non-empty line as document title
          title = "Reconstructed Document"
          for line in content.splitlines():
              if line.strip():
                  title = line.strip()
                  break

          frontmatter = '---\ntitle: "' + title + '"\n---\n\n'
          content = content.replace(title + '\n', "", 1)

          with open("$out/reconstructed.md", 'w') as f:
              f.write(frontmatter + content.strip() + '\n')

          citations = re.findall(r'\[@([^\]]+)\]', content)
          print(f"Recovered {len(set(citations))} unique citation(s): {sorted(set(citations))}", file=sys.stderr)
          PYEOF
        '';

        # ── STAGE 4: reconstructed Markdown → LaTeX ────────────────────────

        rebuildLatex = pkgs.stdenvNoCC.mkDerivation {
          name = "rebuild-latex";
          dontUnpack = true;
          nativeBuildInputs = [ pkgs.pandoc ];
          buildPhase = ''
            cp ${./sample/references.bib} references.bib
            pandoc --standalone \
              --bibliography references.bib \
              --natbib \
              -V colorlinks=true -V citecolor=Blue -V urlcolor=Blue \
              --to latex ${reconstructMd}/reconstructed.md -o paper.tex
          '';
          installPhase = "mkdir -p $out && cp paper.tex references.bib $out/";
          dontFixup = true;
        };

        # ── STAGE 5: rebuild PDFs ──────────────────────────────────────────

        rebuildPdfXelatex = pkgs.stdenvNoCC.mkDerivation {
          name = "rebuild-pdf-xelatex";
          dontUnpack = true;
          nativeBuildInputs = [ texForXelatex ];
          TEXMFHOME = "./texmf";
          TEXMFVAR = "./texmf-var";
          buildPhase = ''
            cp ${rebuildLatex}/paper.tex .
            cp ${rebuildLatex}/references.bib .
            xelatex -interaction=nonstopmode paper.tex
            bibtex paper
            xelatex -interaction=nonstopmode paper.tex
            xelatex -interaction=nonstopmode paper.tex
          '';
          installPhase = "mkdir -p $out && cp paper.pdf $out/paper-xelatex.pdf";
          dontPatchELF = true;
          dontFixup = true;
        };

        rebuildPdfLualatex = pkgs.stdenvNoCC.mkDerivation {
          name = "rebuild-pdf-lualatex";
          dontUnpack = true;
          nativeBuildInputs = [ texForLualatex ];
          TEXMFHOME = "./texmf";
          TEXMFVAR = "./texmf-var";
          buildPhase = ''
            cp ${rebuildLatex}/paper.tex .
            cp ${rebuildLatex}/references.bib .
            lualatex -interaction=nonstopmode paper.tex
            bibtex paper
            lualatex -interaction=nonstopmode paper.tex
            lualatex -interaction=nonstopmode paper.tex
          '';
          installPhase = "mkdir -p $out && cp paper.pdf $out/paper-lualatex.pdf";
          dontPatchELF = true;
          dontFixup = true;
        };

        # ── TESTS (same logic as original, now on rebuilt PDFs) ────────────

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

            check_links("${rebuildPdfXelatex}/paper-xelatex.pdf", "xelatex")
            check_links("${rebuildPdfLualatex}/paper-lualatex.pdf", "lualatex")
            EOF
          '';
          installPhase = "mkdir -p $out && echo passed > $out/result";
          dontFixup = true;
        };

        testPdfColorLinks = pkgs.runCommand "test-pdf-color-links"
          {
            nativeBuildInputs = [
              pkgs.python3Packages.pymupdf
              pkgs.python3Packages.opencv4
              pkgs.python3Packages.numpy
            ];
          } ''
                    python3 - <<'EOF'
          import fitz, cv2, numpy as np, sys

          doc = fitz.open("${rebuildPdfXelatex}/paper-xelatex.pdf")
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

        testPdfLinkDests = pkgs.runCommand "test-pdf-link-dests"
          {
            nativeBuildInputs = [ pkgs.qpdf pkgs.python3 ];
          } ''
                    python3 - <<'EOF'
          import subprocess, json, sys

          data = json.loads(subprocess.check_output(
              ['qpdf', '--json', '${rebuildPdfXelatex}/paper-xelatex.pdf']))

          objs = {}
          for item in data.get('qpdf', []):
              if isinstance(item, dict):
                  objs.update(item)

          cite_dests = set()
          for k, v in objs.items():
              if not isinstance(v, dict): continue
              val = v.get('value', {})
              if not isinstance(val, dict): continue
              if val.get('/Subtype') != '/Link': continue
              action = val.get('/A', {})
              if not isinstance(action, dict): continue
              dest = action.get('/D', "")
              if isinstance(dest, str) and dest.startswith('u:cite.'):
                  cite_dests.add(dest[2:])

          print(f"GoTo citation destinations in annotations: {sorted(cite_dests)}")
          if len(cite_dests) < 4:
              print(f"FAIL: expected >= 4 unique cite.* destinations, got {len(cite_dests)}", file=sys.stderr)
              sys.exit(1)

          catalog = objs['obj:1 0 R']['value']
          names_ref = catalog['/Names']
          dests_ref = objs[f'obj:{names_ref}']['value']['/Dests']
          dests_val = objs[f'obj:{dests_ref}']['value']

          named_dests = {}
          def collect_names(entries):
              for i in range(0, len(entries) - 1, 2):
                  name = entries[i]
                  if isinstance(name, str) and name.startswith('u:'):
                      name = name[2:]
                  dv = entries[i + 1]
                  if isinstance(dv, str) and dv.endswith(' R'):
                      dv = objs[f'obj:{dv}']['value']
                  named_dests[name] = dv

          collect_names(dests_val.get('/Names', []))
          for kid_ref in dests_val.get('/Kids', []):
              collect_names(objs[f'obj:{kid_ref}']['value'].get('/Names', []))

          print(f"Named destinations in PDF: {sorted(named_dests.keys())}")

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
                && nix build --no-link --print-build-logs --print-out-paths '.#samplePdf' \
                && nix build --no-link --print-build-logs --print-out-paths '.#extractAnnotations' \
                && nix build --no-link --print-build-logs --print-out-paths '.#extractText' \
                && nix build --no-link --print-build-logs --print-out-paths '.#reconstructMd' \
                && nix build --no-link --print-build-logs --print-out-paths '.#rebuildLatex' \
                && nix build --no-link --print-build-logs --print-out-paths '.#rebuildPdfXelatex' \
                && nix build --no-link --print-build-logs --print-out-paths '.#rebuildPdfLualatex' \
                && nix build --no-link --print-build-logs --print-out-paths '.#testPdfLinks' \
                && nix build --no-link --print-build-logs --print-out-paths '.#testPdfColorLinks' \
                && nix build --no-link --print-build-logs --print-out-paths '.#testPdfLinkDests' \
                && nix flake check --all-systems --verbose '.#'
              '';
            } // { meta.mainProgram = name; };

      in
      {
        packages = {
          default = reconstructMd;
          inherit samplePdf
            extractAnnotations extractText reconstructMd
            rebuildLatex rebuildPdfXelatex rebuildPdfLualatex
            testPdfLinks testPdfColorLinks testPdfLinkDests
            allTests;
        };

        apps = {
          default = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-sample-pdf" ''
              ${pkgs.kdePackages.okular}/bin/okular "${samplePdf}/paper.pdf"
            '');
          };
          openSamplePdf = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-sample-pdf" ''
              ${pkgs.kdePackages.okular}/bin/okular "${samplePdf}/paper.pdf"
            '');
          };
          openRebuiltPdf = {
            type = "app";
            program = toString (pkgs.writeShellScript "open-rebuilt-pdf" ''
              ${pkgs.kdePackages.okular}/bin/okular "${rebuildPdfXelatex}/paper-xelatex.pdf"
            '');
          };
          allTests = {
            type = "app";
            program = pkgs.lib.getExe allTests;
          };
        };

        checks = {
          inherit rebuildPdfXelatex rebuildPdfLualatex
            testPdfLinks testPdfColorLinks testPdfLinkDests;
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.pandoc
            pkgs.nixpkgs-fmt
            pkgs.python3Packages.pymupdf
          ];
        };
      }
    );
}
