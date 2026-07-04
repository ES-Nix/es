{
  description = "Comprehensive LaTeX Symbol List — Scott Pakin, compiled from CTAN source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

        # texdoc sub-derivation: symbols.tex + fake*.sty stubs + patch-idx + prune-idx
        comprehensiveDoc = pkgs.lib.findFirst
          (p: pkgs.lib.hasSuffix "-texdoc" (p.name or ""))
          (throw "comprehensive texdoc not found")
          pkgs.texlive.comprehensive.pkgs;

        # Writable copy — store paths are read-only
        comprehensiveSrc = pkgs.runCommand "comprehensive-src" { } ''
          mkdir $out
          cp -r "${comprehensiveDoc}/doc/latex/comprehensive/source/." $out/
          chmod -R u+w $out
        '';

        # python3 with toml for prune-idx
        pythonEnv = pkgs.python3.withPackages (ps: [ ps.toml ]);

        texEnv = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-small
            latexmk
            fontware
            # ── preamble layout packages ──────────────────────────────────
            iftex
            accsupp
            xstring
            mflogo
            changepage
            cutwin
            tocloft
            fancyhdr
            xcolor
            # ── Cyrillic/T2A support ─────────────────────────────────────
            cyrillic
            t2
            lh
            cm-super
            # ── Greek LGR encoding (teubner-subset.sty needs babel-greek) ─
            babel-greek
            # ── small/standard symbol packages ───────────────────────────
            rsfs
            wasysym
            wasy
            marvosym
            stmaryrd
            ifsym
            psnfss
            bbding
            dingbat
            eurosym
            skull
            countriesofeurope
            universa
            manfnt
            boondox
            mathabx
            genealogy
            metre
            phonetic
            pigpen
            pmhanguljamo
            teubner
            trsym
            epigraph
            dancers
            nfssext-cfr
            # ── dependency packages ───────────────────────────────────────
            relsize
            # Greek LGR encoding fonts (lgrcmr.fd etc.)
            cbfonts
            cbfonts-fd
            greek-fontenc
            # ── larger symbol packages ────────────────────────────────────
            mnsymbol
            fdsymbol
            boisik
            stix
            starfont
            knitting
            cmupint
            dozenal
            allrunes
            arcs
            fontawesome5
            # ── Helvetica for title page ──────────────────────────────────
            helvetic
            # ── font generation ───────────────────────────────────────────
            metafont
            metapost
            epstopdf
            # ── comprehensive source itself ───────────────────────────────
            comprehensive
            ;
        };

        latex-symbols = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-symbols";
          src = comprehensiveSrc;
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          nativeBuildInputs = [
            texEnv
            pythonEnv
            pkgs.perl
            pkgs.ghostscript
            pkgs.mftrace
            pkgs.fontforge
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
          ];
          buildPhase = ''
            export HOME="$PWD/.home"
            mkdir -p "$HOME"
            export TEXMFHOME="$PWD/.cache"
            export TEXMFVAR="$PWD/.cache/texmf-var"
            mkdir -p "$TEXMFVAR"

            # stub `locate` and alias python3 → python
            mkdir -p .bin
            printf '#!/bin/sh\n' > .bin/locate && chmod +x .bin/locate
            ln -sf ${pythonEnv}/bin/python3 .bin/python
            export PATH="$PWD/.bin:${pkgs.lib.makeBinPath [
              texEnv pythonEnv pkgs.perl pkgs.ghostscript
              pkgs.mftrace pkgs.fontforge
              pkgs.coreutils pkgs.gnugrep pkgs.gnused
            ]}"

            chmod +x makefake* maketitlepage patch-idx prune-idx 2>/dev/null || true

            # warm-up kpsewhich
            kpsewhich article.cls >/dev/null 2>&1 || true
            # ── Perl-based fakers: use real .sty when available ───────────
            for pair in \
              "MnSymbol:makefakeMnSymbol:fakeMnSymbol.sty" \
              "fdsymbol:makefakefdsymbol:fakefdsymbol.sty" \
              "boisik:makefakeboisik:fakeboisik.sty" \
              "stix:makefakestix:fakestix.sty" \
              "starfont:makefakestarfont:fakestarfont.sty" \
              "cmupint:makefakecmupint:fakecmupint.sty"
            do
              _pkg=$(echo "$pair" | cut -d: -f1)
              _script=$(echo "$pair" | cut -d: -f2)
              _stub=$(echo "$pair" | cut -d: -f3)
              _sty=$(kpsewhich "$_pkg.sty" 2>/dev/null || true)
              [ -z "$_sty" ] && _sty=/dev/null
              perl "$_script" "$_sty" > "$_stub" 2>/dev/null || touch "$_stub"
            done

            # ── worldflags (Python, uses kpsewhich internally) ────────────
            if kpsewhich worldflags.sty >/dev/null 2>&1; then
              python makefakeworldflags 2>/dev/null || touch fakeworldflags.sty
            else
              touch fakeworldflags.sty
            fi

            # ── figchild, utfsym (Python, read real .sty) ─────────────────
            for pkg in figchild utfsym; do
              if kpsewhich "$pkg.sty" >/dev/null 2>&1; then
                python "makefake$pkg" 2>/dev/null || touch "fake$pkg.sty"
              else
                touch "fake$pkg.sty"
              fi
            done

            # ── LuaLaTeX→pdfLaTeX converters (fontforge required) ─────────
            for pair in \
              "academicons:academicons.ttf" \
              "typicons:typicons.ttf" \
              "asapsym:Asap-Symbol.ttf" \
              "hamnosys:HamNoSysUnicode.ttf" \
              "logix:logix.otf"
            do
              _pkg=$(echo "$pair" | cut -d: -f1)
              _ttf=$(echo "$pair" | cut -d: -f2)
              if kpsewhich "$_pkg.sty" >/dev/null 2>&1; then
                python makefakelualatex "$_pkg" "$_ttf" 2>/dev/null || touch "fake$_pkg.sty"
              else
                touch "fake$_pkg.sty"
              fi
            done

            # fontmfizz needs special flag
            if kpsewhich fontmfizz.sty >/dev/null 2>&1; then
              python makefakelualatex fontmfizz font-mfizz.ttf 2>/dev/null || touch fakefontmfizz.sty
            else
              touch fakefontmfizz.sty
            fi

            # ── remaining stubs ───────────────────────────────────────────
            touch fakeknitting.sty 2>/dev/null || true
            if kpsewhich knitting.sty >/dev/null 2>&1; then
              kpsewhich knitting.sty | xargs -I{} sed '/Standard chart commands/,$d' {} \
                > fakeknitting.sty 2>/dev/null || touch fakeknitting.sty
            fi

            # ── versatim.tex (apl package override) ──────────────────────
            printf '%% Do-nothing replacement for the apl package'"'"'s versatim.tex\n\\endinput\n' > versatim.tex

            # ── symlink non-LaTeX MF/TFM files ────────────────────────────
            for fname in hands.mf greenpoint.mf nkarta.mf astrosym.mf \
                         moonphase.mf dancers.mf smfpr10.mf umranda.mf umrandb.mf \
                         cryst.mf dice3d.mf magic.mf fselch10.mf msym10.tfm \
                         knot1.mf knot2.mf knot3.mf knot4.mf knot5.mf \
                         knot6.mf knot7.mf cmrj.tfm; do
              fullfname=$(kpsewhich "$fname" 2>/dev/null || true)
              [ -n "$fullfname" ] && ln -sf "$fullfname" . || true
            done

            # ── junicode / lilyglyphs dirs (real fonts not in sandbox) ────
            mkdir -p junicode lilyglyphs

            # ── lightbulb font ────────────────────────────────────────────
            mpost -mem=mfplain '\mode:=proof; prologues:=2; labelfont cmr17; input lightbulb10' \
              2>/dev/null || true
            [ -f lightbulb10.65 ] && mv lightbulb10.65 lightbulb.eps || true
            if [ -f lightbulb.eps ]; then
              mftrace -V -fpfb --simplify lightbulb10 2>/dev/null || true
              if [ -f lightbulb10.pfb ]; then
                fontforge -lang=ff -c \
                  'Open($1); LB="LightBulb"; SetFontNames(LB+"10",LB,LB+"10"); Generate("lightbulb10.pfb");' \
                  lightbulb10.pfb 2>/dev/null || true
              fi
              ps2pdf -dEPSCrop lightbulb.eps lightbulb.pdf 2>/dev/null || true
            fi
            printf 'lightbulb10 LightBulb10 <lightbulb10.pfb\n' > lightbulb.map

            # ── LGR.def shim: nixpkgs greek-fontenc ships lgrenc.def, not LGR.def ──
            printf '\\input{lgrenc.def}\\endinput\n' > LGR.def

            # ── Pass 1: initial compile ───────────────────────────────────
            pdflatex -interaction=nonstopmode -jobname symbols-a4 \
              '\PassOptionsToClass{a4paper}{article}\input{symbols}' || true

            # ── Pass 2 ────────────────────────────────────────────────────
            python patch-idx symbols-a4.idx 2>/dev/null || true
            pdflatex -interaction=nonstopmode -jobname symbols-a4 \
              '\PassOptionsToClass{a4paper}{article}\input{symbols}' || true

            # ── Index generation ──────────────────────────────────────────
            python patch-idx symbols-a4.idx 2>/dev/null || true
            makeindex -s symbols.ist symbols-a4 2>/dev/null || true
            cp symbols-a4.ind symbols-a4-full.ind 2>/dev/null || true
            python prune-idx symbols-a4.idx prune-idx-*.toml 2>/dev/null || true
            makeindex -s symbols.ist symbols-a4 2>/dev/null || true

            # ── Pass 3 ────────────────────────────────────────────────────
            pdflatex -interaction=nonstopmode -jobname symbols-a4 \
              '\PassOptionsToClass{a4paper}{article}\input{symbols}' || true

            # ── Update .aux with symbol count ─────────────────────────────
            totalsymbols=$(grep -Ec '\\item \\(sp)?verb' symbols-a4-full.ind 2>/dev/null || echo 0)
            if [ -f symbols-a4.aux ]; then
              grep -v prevtotalsymbols symbols-a4.aux > symbols-a4.pts 2>/dev/null || cp symbols-a4.aux symbols-a4.pts
              printf '%s\n' "\\gdef\\prevtotalsymbols{$totalsymbols}" "\\gdef\\approxcount{}" \
                >> symbols-a4.pts
              mv symbols-a4.pts symbols-a4.aux
            fi

            # ── Pass 4: stabilise (no titlefile — avoids 1-page trap) ─────
            pdflatex -interaction=nonstopmode -jobname symbols-a4 \
              '\PassOptionsToClass{a4paper}{article}\input{symbols}' || true
          '';
          installPhase = ''
            mkdir -p $out
            cp symbols-a4.pdf $out/symbols.pdf
            cp symbols-a4.log $out/ 2>/dev/null || true
          '';
        };

        allTests =
          let name = "all-tests";
          in pkgs.writeShellApplication
            {
              name = name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show --all-systems '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#' \
                && nix develop '.#' --command sh -c 'true' \
                && nix flake check --all-systems --verbose '.#'
              '';
            } // { meta.mainProgram = name; };
      in
      {
        packages.default = latex-symbols;
        packages.allTests = allTests;

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${latex-symbols}/symbols.pdf"
          '');
          meta.description = "latex-symbols — Firefox";
        };
        apps.firefox = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${latex-symbols}/symbols.pdf"
          '');
          meta.description = "latex-symbols — Firefox";
        };
        apps.okular = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-okular" ''
            ${pkgs.kdePackages.okular}/bin/okular "${latex-symbols}/symbols.pdf"
          '');
          meta.description = "latex-symbols — Okular";
        };
        apps.chromium = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-chromium" ''
            ${pkgs.chromium}/bin/chromium "${latex-symbols}/symbols.pdf"
          '');
          meta.description = "latex-symbols — Chromium";
        };

        apps.allTests = {
          type = "app";
          program = pkgs.lib.getExe allTests;
          meta.description = "Run all tests for this flake";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            texEnv
            pythonEnv
            pkgs.perl
            pkgs.ghostscript
            pkgs.mftrace
            pkgs.fontforge
          ];
          shellHook = ''
            echo "latex-symbols dev shell — source at ${comprehensiveSrc}"
            echo "  cp -r ${comprehensiveSrc}/. /tmp/clsl && cd /tmp/clsl"
            echo "  pdflatex -jobname symbols-a4 '\\PassOptionsToClass{a4paper}{article}\\input{symbols}'"
          '';
        };

        checks.default = latex-symbols;
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
