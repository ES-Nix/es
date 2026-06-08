{
  description = "A Nix flake building all 53 official pandoc demo outputs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];
    in
    {
      overlays.default = final: prev: {
        inherit self final prev;

        # ── Input files from pandoc.org/demo/ ──────────────────────────────

        demoManualTxt = prev.fetchurl {
          url = "https://pandoc.org/demo/MANUAL.txt";
          hash = "sha256-645fmLnT+xsoB5zzQcvTUBh/UTbP8lKSlpz9+ji6ZgA=";
        };
        demoSlides = prev.fetchurl {
          url = "https://pandoc.org/demo/SLIDES";
          name = "SLIDES";
          hash = "sha256-juIcEgZjGELoHRdYIYW6i8QjvuW9iNIbUSnAhFyBvpg=";
        };
        demoPandocCss = prev.fetchurl {
          url = "https://pandoc.org/demo/pandoc.css";
          hash = "sha256-D8JYZ8aE7a0LXAXJN2f7Tr9N13Tqb4uk04ewH7XTwwY=";
        };
        demoFooterHtml = prev.fetchurl {
          url = "https://pandoc.org/demo/footer.html";
          hash = "sha256-OyPk97auBqkMuvvMK1UjVak0NRGQ3nxowISa67MY1Lc=";
        };
        demoPandoc1Md = prev.fetchurl {
          url = "https://pandoc.org/demo/pandoc.1.md";
          hash = "sha256-xOMN/nsG5KEuSQLUMiyQ9KPWEuHvuW1lR1r67NQQt6g=";
        };
        demoMathText = prev.fetchurl {
          url = "https://pandoc.org/demo/math.text";
          name = "math.text";
          hash = "sha256-SNlzunsL1hMg/5gv78vvLvIZJxCMuGaM52sb6TFECjI=";
        };
        demoMathTex = prev.fetchurl {
          url = "https://pandoc.org/demo/math.tex";
          name = "math.tex";
          hash = "sha256-5N7/dH8Mqqv1/PTYpjHRZhFAqSAQ3ylRzy3m8NJhyZk=";
        };
        demoCodeText = prev.fetchurl {
          url = "https://pandoc.org/demo/code.text";
          name = "code.text";
          hash = "sha256-yzVaZ6/MOMfaXkqTpgFOSGrAebKAJNsGxySZs0HdjBo=";
        };
        demoFancyheaders = prev.fetchurl {
          url = "https://pandoc.org/demo/fancyheaders.tex";
          hash = "sha256-6nCHkOEOIZgUosfwTlncZ+eJtrCYkST3GvK5uccDZZk=";
        };
        demoExample15Md = prev.fetchurl {
          url = "https://pandoc.org/demo/example15.md";
          hash = "sha256-WY85HOxHkt3u2gd86VwyD4iSM+jRlXIxwuf/xCuntzk=";
        };
        demoExample15Png = prev.fetchurl {
          url = "https://pandoc.org/demo/example15.png";
          hash = "sha256-uK5Cvt1fhEeuAvJHwomsAIUNPCud54nonpgrqF5NVQg=";
        };
        demoBiblioBib = prev.fetchurl {
          url = "https://pandoc.org/demo/biblio.bib";
          hash = "sha256-uPey+fGMT51LkMV6BvnOkaHVV3stWggjqdK2Ws3Igos=";
        };
        demoBiblioJson = prev.fetchurl {
          url = "https://pandoc.org/demo/biblio.json";
          hash = "sha256-sLgFMh+d1Ua4k7z7oq0/2wGjPBDnsH83gzhKRfRL6sk=";
        };
        demoBiblioYaml = prev.fetchurl {
          url = "https://pandoc.org/demo/biblio.yaml";
          hash = "sha256-seHfq8MDdWkD9+AhiQSAL+c0ivVlGBpwIRBcJNcFycE=";
        };
        demoCitations = prev.fetchurl {
          url = "https://pandoc.org/demo/CITATIONS";
          name = "CITATIONS";
          hash = "sha256-byfggD98RJ2kLPNdheQa2v68ehpSwSjsoPpbVoLUlBE=";
        };
        demoHowtoXml = prev.fetchurl {
          url = "https://pandoc.org/demo/howto.xml";
          hash = "sha256-ARHHcJWR1ra8U11lWukYgBhEOm0L3bsnt56BQE+trxk=";
        };
        demoHaskellWiki = prev.fetchurl {
          url = "https://pandoc.org/demo/haskell.wiki";
          hash = "sha256-fay7wEsvLhMnfEm0Pfn12dnkR2XKPaLuEyAxADs2AvU=";
        };
        demoTwocolumns = prev.fetchurl {
          url = "https://pandoc.org/demo/twocolumns.docx";
          hash = "sha256-Q58ZUDOLUjN8U0nQrjtOp2edc8xdY5+CSp/cTx1Psiw=";
        };
        demoFishwatch = prev.fetchurl {
          url = "https://pandoc.org/demo/fishwatch.yaml";
          hash = "sha256-7mIQkYqID4Vu2X25uhJFjM2Kt3n3f4l/CvOIdDPzYb8=";
        };
        demoFishtable = prev.fetchurl {
          url = "https://pandoc.org/demo/fishtable.rst";
          hash = "sha256-mLnEua/NbW9jeM28zP4J+UR+/3XHpc2SDTxJW8kfoJ4=";
        };
        demoSpecies = prev.fetchurl {
          url = "https://pandoc.org/demo/species.rst";
          hash = "sha256-adwgErsgeWmChby9z4JckUwIFy8Vl0fDrsz7rMbRhT0=";
        };
        # Pre-fetched pandoc.org homepage; network is blocked in the Nix sandbox
        demoPandocOrg = prev.fetchurl {
          url = "https://pandoc.org/";
          name = "pandoc-org-index.html";
          hash = "sha256-jvXOv/dGwJJ4TvecWlNtQnyiMUY+KlXGMlebCpXRYmw=";
        };
        # CSL style files
        demoIeeCsl = prev.fetchurl {
          url = "https://raw.githubusercontent.com/citation-style-language/styles/master/ieee.csl";
          hash = "sha256-tMdhn8FsRaMeTMMnHquU/+gxktO0x/xylHCjtFlEjeM=";
        };
        demoChicagoCsl = prev.fetchurl {
          url = "https://pandoc.org/demo/chicago-fullnote-bibliography.csl";
          hash = "sha256-t9yuYG8hp3+Drop3oD4c6F2DfOKzFNV/Ri51vmQziNo=";
        };

        # ── TeX Live environments ──────────────────────────────────────────

        texBeamer = final.texlive.combine {
          inherit (final.texlive) scheme-small beamer;
        };

        # xelatex (ex13) and lualatex (ex14); TeX Gyre replaces proprietary fonts
        texPdf = final.texlive.combine {
          inherit (final.texlive)
            scheme-small collection-xetex collection-luatex
            geometry fancyhdr hyperref amsmath fontspec lm
            tex-gyre tex-gyre-math;
        };

        # ── Builder ────────────────────────────────────────────────────────

        buildPandocDemo =
          { name
          , outputFile
          , cmd
          , isDirectory ? false
          , extraInputs ? [ ]
          , extraFiles ? { }
          }:
          let
            symlinkCmds = prev.lib.concatStrings
              (prev.lib.mapAttrsToList
                (fname: fdrv: "ln -sf ${fdrv} ./${fname}\n")
                extraFiles);
          in
          final.stdenvNoCC.mkDerivation {
            inherit name;
            phases = [ "buildPhase" "installPhase" ];
            buildInputs = [ final.pandoc ] ++ extraInputs;
            buildPhase = ''
              export HOME="$TMPDIR"
              ${symlinkCmds}
              pandoc ${prev.lib.escapeShellArgs cmd} \
                ${prev.lib.optionalString isDirectory "-o $out"}
            '';
            installPhase =
              if isDirectory then "true"
              else ''
                mkdir -p $out
                cp -r ${outputFile} $out/
              '';
            dontPatchELF = true;
            dontFixup = true;
          };

        # ── Demos ──────────────────────────────────────────────────────────

        example1 = final.buildPandocDemo {
          name = "example1";
          outputFile = "example1.html";
          cmd = [ "${final.demoManualTxt}" "-o" "example1.html" ];
        };

        example2 = final.buildPandocDemo {
          name = "example2";
          outputFile = "example2.html";
          cmd = [ "-s" "${final.demoManualTxt}" "-o" "example2.html" ];
        };

        example3 = final.buildPandocDemo {
          name = "example3";
          outputFile = "example3.html";
          extraFiles = {
            "pandoc.css" = final.demoPandocCss;
            "footer.html" = final.demoFooterHtml;
          };
          cmd = [
            "-s"
            "--toc"
            "-c"
            "pandoc.css"
            "-A"
            "footer.html"
            "${final.demoManualTxt}"
            "-o"
            "example3.html"
          ];
        };

        example4 = final.buildPandocDemo {
          name = "example4";
          outputFile = "example4.tex";
          cmd = [ "-s" "${final.demoManualTxt}" "-o" "example4.tex" ];
        };

        # Depends on example4 output
        example5 = final.buildPandocDemo {
          name = "example5";
          outputFile = "example5.text";
          cmd = [ "-s" "${final.example4}/example4.tex" "-o" "example5.text" ];
        };

        example6 = final.buildPandocDemo {
          name = "example6";
          outputFile = "example6.text";
          cmd = [ "-s" "-t" "rst" "--toc" "${final.demoManualTxt}" "-o" "example6.text" ];
        };

        example7 = final.buildPandocDemo {
          name = "example7";
          outputFile = "example7.rtf";
          cmd = [ "-s" "${final.demoManualTxt}" "-o" "example7.rtf" ];
        };

        example8 = final.buildPandocDemo {
          name = "example8";
          outputFile = "example8.pdf";
          extraInputs = [ final.texBeamer ];
          cmd = [ "-t" "beamer" "${final.demoSlides}" "-o" "example8.pdf" ];
        };

        example9 = final.buildPandocDemo {
          name = "example9";
          outputFile = "example9.db";
          cmd = [ "-s" "-t" "docbook" "${final.demoManualTxt}" "-o" "example9.db" ];
        };

        example10 = final.buildPandocDemo {
          name = "example10";
          outputFile = "example10.1";
          cmd = [ "-s" "-t" "man" "${final.demoPandoc1Md}" "-o" "example10.1" ];
        };

        example11 = final.buildPandocDemo {
          name = "example11";
          outputFile = "example11.tex";
          cmd = [ "-s" "-t" "context" "${final.demoManualTxt}" "-o" "example11.tex" ];
        };

        # Network fetch replaced by pre-fetched HTML (sandbox has no network)
        example12 = final.buildPandocDemo {
          name = "example12";
          outputFile = "example12.text";
          cmd = [ "-s" "-r" "html" "${final.demoPandocOrg}" "-o" "example12.text" ];
        };

        example13 = final.buildPandocDemo {
          name = "example13";
          outputFile = "example13.pdf";
          extraInputs = [ final.texPdf ];
          cmd = [ "${final.demoManualTxt}" "--pdf-engine=xelatex" "-o" "example13.pdf" ];
        };

        # Proprietary fonts (Palatino/Helvetica/Menlo) replaced by TeX Gyre equivalents
        example14 = final.buildPandocDemo {
          name = "example14";
          outputFile = "example14.pdf";
          extraInputs = [ final.texPdf ];
          extraFiles = { "fancyheaders.tex" = final.demoFancyheaders; };
          cmd = [
            "-N"
            "--variable=geometry:margin=1.2in"
            "--variable=mainfont:TeX Gyre Pagella"
            "--variable=sansfont:TeX Gyre Heros"
            "--variable=monofont:TeX Gyre Cursor"
            "--variable=fontsize:12pt"
            "--variable=version:2.0"
            "${final.demoManualTxt}"
            "--include-in-header=fancyheaders.tex"
            "--pdf-engine=lualatex"
            "--toc"
            "-o"
            "example14.pdf"
          ];
        };

        example15 = final.buildPandocDemo {
          name = "example15";
          outputFile = "example15.ipynb";
          extraFiles = { "example15.png" = final.demoExample15Png; };
          cmd = [ "${final.demoExample15Md}" "-o" "example15.ipynb" ];
        };

        example16a = final.buildPandocDemo {
          name = "example16a";
          outputFile = "example16a.html";
          cmd = [
            "-s"
            "--mathml"
            "-i"
            "-t"
            "dzslides"
            "${final.demoSlides}"
            "-o"
            "example16a.html"
          ];
        };

        example16b = final.buildPandocDemo {
          name = "example16b";
          outputFile = "example16b.html";
          cmd = [
            "-s"
            "--webtex"
            "-i"
            "-t"
            "slidy"
            "${final.demoSlides}"
            "-o"
            "example16b.html"
          ];
        };

        example16d = final.buildPandocDemo {
          name = "example16d";
          outputFile = "example16d.html";
          cmd = [
            "-s"
            "--mathjax"
            "-i"
            "-t"
            "revealjs"
            "${final.demoSlides}"
            "-o"
            "example16d.html"
          ];
        };

        example17a = final.buildPandocDemo {
          name = "example17a";
          outputFile = "mathDefault.html";
          cmd = [ "${final.demoMathText}" "-s" "-o" "mathDefault.html" ];
        };

        example17b = final.buildPandocDemo {
          name = "example17b";
          outputFile = "mathMathML.html";
          cmd = [ "${final.demoMathText}" "-s" "--mathml" "-o" "mathMathML.html" ];
        };

        example17c = final.buildPandocDemo {
          name = "example17c";
          outputFile = "mathWebTeX.html";
          cmd = [ "${final.demoMathText}" "-s" "--webtex" "-o" "mathWebTeX.html" ];
        };

        example17d = final.buildPandocDemo {
          name = "example17d";
          outputFile = "mathMathJax.html";
          cmd = [ "${final.demoMathText}" "-s" "--mathjax" "-o" "mathMathJax.html" ];
        };

        example17e = final.buildPandocDemo {
          name = "example17e";
          outputFile = "mathKaTeX.html";
          cmd = [ "${final.demoMathText}" "-s" "--katex" "-o" "mathKaTeX.html" ];
        };

        # Demos page says --syntax-highlighting; correct flag is --highlight-style
        example18a = final.buildPandocDemo {
          name = "example18a";
          outputFile = "example18a.html";
          cmd = [
            "${final.demoCodeText}"
            "-s"
            "--highlight-style=pygments"
            "-o"
            "example18a.html"
          ];
        };

        example18b = final.buildPandocDemo {
          name = "example18b";
          outputFile = "example18b.html";
          cmd = [
            "${final.demoCodeText}"
            "-s"
            "--highlight-style=kate"
            "-o"
            "example18b.html"
          ];
        };

        example18c = final.buildPandocDemo {
          name = "example18c";
          outputFile = "example18c.html";
          cmd = [
            "${final.demoCodeText}"
            "-s"
            "--highlight-style=monochrome"
            "-o"
            "example18c.html"
          ];
        };

        example18d = final.buildPandocDemo {
          name = "example18d";
          outputFile = "example18d.html";
          cmd = [
            "${final.demoCodeText}"
            "-s"
            "--highlight-style=espresso"
            "-o"
            "example18d.html"
          ];
        };

        example18e = final.buildPandocDemo {
          name = "example18e";
          outputFile = "example18e.html";
          cmd = [
            "${final.demoCodeText}"
            "-s"
            "--highlight-style=haddock"
            "-o"
            "example18e.html"
          ];
        };

        example18f = final.buildPandocDemo {
          name = "example18f";
          outputFile = "example18f.html";
          cmd = [
            "${final.demoCodeText}"
            "-s"
            "--highlight-style=tango"
            "-o"
            "example18f.html"
          ];
        };

        example18g = final.buildPandocDemo {
          name = "example18g";
          outputFile = "example18g.html";
          cmd = [
            "${final.demoCodeText}"
            "-s"
            "--highlight-style=zenburn"
            "-o"
            "example18g.html"
          ];
        };

        example19 = final.buildPandocDemo {
          name = "example19";
          outputFile = "example19.texi";
          cmd = [ "${final.demoManualTxt}" "-s" "-o" "example19.texi" ];
        };

        example20 = final.buildPandocDemo {
          name = "example20";
          outputFile = "example20.xml";
          cmd = [ "${final.demoManualTxt}" "-s" "-t" "opendocument" "-o" "example20.xml" ];
        };

        example21 = final.buildPandocDemo {
          name = "example21";
          outputFile = "example21.odt";
          cmd = [ "${final.demoManualTxt}" "-o" "example21.odt" ];
        };

        example22 = final.buildPandocDemo {
          name = "example22";
          outputFile = "example22.wiki";
          cmd = [
            "-s"
            "-t"
            "mediawiki"
            "--toc"
            "${final.demoManualTxt}"
            "-o"
            "example22.wiki"
          ];
        };

        example23 = final.buildPandocDemo {
          name = "example23";
          outputFile = "MANUAL.epub";
          cmd = [ "${final.demoManualTxt}" "-o" "MANUAL.epub" ];
        };

        example24a = final.buildPandocDemo {
          name = "example24a";
          outputFile = "example24a.html";
          extraFiles = {
            "biblio.bib" = final.demoBiblioBib;
            "CITATIONS" = final.demoCitations;
          };
          cmd = [
            "-s"
            "--bibliography=biblio.bib"
            "--citeproc"
            "CITATIONS"
            "-o"
            "example24a.html"
          ];
        };

        example24b = final.buildPandocDemo {
          name = "example24b";
          outputFile = "example24b.html";
          extraFiles = {
            "biblio.json" = final.demoBiblioJson;
            "CITATIONS" = final.demoCitations;
            "chicago-fullnote-bibliography.csl" = final.demoChicagoCsl;
          };
          cmd = [
            "-s"
            "--bibliography=biblio.json"
            "--citeproc"
            "--csl=chicago-fullnote-bibliography.csl"
            "CITATIONS"
            "-o"
            "example24b.html"
          ];
        };

        example24c = final.buildPandocDemo {
          name = "example24c";
          outputFile = "example24c.1";
          extraFiles = {
            "biblio.yaml" = final.demoBiblioYaml;
            "CITATIONS" = final.demoCitations;
            "ieee.csl" = final.demoIeeCsl;
          };
          cmd = [
            "-s"
            "--bibliography=biblio.yaml"
            "--citeproc"
            "--csl=ieee.csl"
            "CITATIONS"
            "-t"
            "man"
            "-o"
            "example24c.1"
          ];
        };

        example25 = final.buildPandocDemo {
          name = "example25";
          outputFile = "example25.textile";
          cmd = [
            "-s"
            "${final.demoManualTxt}"
            "-t"
            "textile"
            "-o"
            "example25.textile"
          ];
        };

        # Depends on example25 output
        example26 = final.buildPandocDemo {
          name = "example26";
          outputFile = "example26.html";
          cmd = [
            "-s"
            "${final.example25}/example25.textile"
            "-f"
            "textile"
            "-t"
            "html"
            "-o"
            "example26.html"
          ];
        };

        example27 = final.buildPandocDemo {
          name = "example27";
          outputFile = "example27.org";
          cmd = [ "-s" "${final.demoManualTxt}" "-o" "example27.org" ];
        };

        example28 = final.buildPandocDemo {
          name = "example28";
          outputFile = "example28.txt";
          cmd = [ "-s" "${final.demoManualTxt}" "-t" "asciidoc" "-o" "example28.txt" ];
        };

        example29 = final.buildPandocDemo {
          name = "example29";
          outputFile = "example29.docx";
          cmd = [ "-s" "${final.demoManualTxt}" "-o" "example29.docx" ];
        };

        example30 = final.buildPandocDemo {
          name = "example30";
          outputFile = "example30.docx";
          cmd = [ "-s" "${final.demoMathTex}" "-o" "example30.docx" ];
        };

        example31 = final.buildPandocDemo {
          name = "example31";
          outputFile = "example31.text";
          cmd = [
            "-f"
            "docbook"
            "-t"
            "markdown"
            "-s"
            "${final.demoHowtoXml}"
            "-o"
            "example31.text"
          ];
        };

        example32 = final.buildPandocDemo {
          name = "example32";
          outputFile = "example32.html";
          cmd = [
            "-f"
            "mediawiki"
            "-t"
            "html5"
            "-s"
            "${final.demoHaskellWiki}"
            "-o"
            "example32.html"
          ];
        };

        # isDirectory = true: pandoc creates $out as a directory directly
        example33 = final.buildPandocDemo {
          name = "example33";
          outputFile = "";
          isDirectory = true;
          cmd = [
            "-t"
            "chunkedhtml"
            "--split-level=2"
            "--toc"
            "--toc-depth=2"
            "--number-sections"
            "${final.demoManualTxt}"
          ];
        };

        example34 = final.buildPandocDemo {
          name = "example34";
          outputFile = "UsersGuide.docx";
          extraFiles = { "twocolumns.docx" = final.demoTwocolumns; };
          cmd = [
            "--reference-doc=twocolumns.docx"
            "-o"
            "UsersGuide.docx"
            "${final.demoManualTxt}"
          ];
        };

        # Depends on example30 output
        example35 = final.buildPandocDemo {
          name = "example35";
          outputFile = "example35.md";
          cmd = [
            "-s"
            "${final.example30}/example30.docx"
            "-t"
            "markdown"
            "-o"
            "example35.md"
          ];
        };

        # Depends on example23 output
        example36 = final.buildPandocDemo {
          name = "example36";
          outputFile = "example36.text";
          cmd = [ "${final.example23}/MANUAL.epub" "-t" "plain" "-o" "example36.text" ];
        };

        example37 = final.buildPandocDemo {
          name = "example37";
          outputFile = "fish.rst";
          extraFiles = {
            "fishwatch.yaml" = final.demoFishwatch;
            "fishtable.rst" = final.demoFishtable;
            "species.rst" = final.demoSpecies;
          };
          cmd = [ "fishwatch.yaml" "-t" "rst" "--template=fishtable.rst" "-o" "fish.rst" ];
        };

        example38 = final.buildPandocDemo {
          name = "example38";
          outputFile = "biblio2.json";
          extraFiles = { "biblio.bib" = final.demoBiblioBib; };
          cmd = [ "biblio.bib" "-t" "csljson" "-o" "biblio2.json" ];
        };

        example39 = final.buildPandocDemo {
          name = "example39";
          outputFile = "biblio.html";
          extraFiles = {
            "biblio.bib" = final.demoBiblioBib;
            "ieee.csl" = final.demoIeeCsl;
          };
          cmd = [ "biblio.bib" "--citeproc" "--csl=ieee.csl" "-s" "-o" "biblio.html" ];
        };

        allTests =
          let name = "all-tests"; in
          final.writeShellApplication
            {
              name = name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show --all-systems '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example1' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example2' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example3' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example4' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example5' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example6' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example7' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example8' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example9' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example10' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example11' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example12' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example13' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example14' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example15' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example16a' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example16b' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example16d' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example17a' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example17b' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example17c' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example17d' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example17e' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example18a' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example18b' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example18c' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example18d' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example18e' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example18f' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example18g' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example19' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example20' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example21' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example22' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example23' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example24a' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example24b' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example24c' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example25' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example26' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example27' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example28' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example29' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example30' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example31' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example32' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example33' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example34' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example35' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example36' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example37' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example38' \
                && nix build --no-link --print-build-logs --print-out-paths '.#example39' \
                && nix develop '.#' --command sh -c 'true' \
                && nix flake check --all-systems --verbose '.#'
              '';
            } // { meta.mainProgram = name; };

      };
    } //
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs {
            overlays = [ self.overlays.default ];
            system = suportedSystem;
            config.allowUnfree = true;
          };

          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {
          packages = {
            inherit (pkgsAllowUnfree)
              allTests
              example1 example2 example3 example4 example5 example6 example7
              example8 example9 example10 example11 example12 example13 example14
              example15 example16a example16b example16d
              example17a example17b example17c example17d example17e
              example18a example18b example18c example18d example18e example18f example18g
              example19 example20 example21 example22 example23
              example24a example24b example24c
              example25 example26 example27 example28 example29 example30
              example31 example32 example33 example34 example35 example36
              example37 example38 example39
              ;
            default = pkgsAllowUnfree.example1;
          };

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          apps = {
            allTests = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.allTests}";
              meta.description = "Build all 53 pandoc demo outputs";
            };
            default = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.allTests}";
              meta.description = "Build all 53 pandoc demo outputs";
            };
          };

          checks = {
            inherit (pkgsAllowUnfree)
              allTests
              example1 example2 example3 example4 example5 example6 example7
              example8 example9 example10 example11 example12 example13 example14
              example15 example16a example16b example16d
              example17a example17b example17c example17d example17e
              example18a example18b example18c example18d example18e example18f example18g
              example19 example20 example21 example22 example23
              example24a example24b example24c
              example25 example26 example27 example28 example29 example30
              example31 example32 example33 example34 example35 example36
              example37 example38 example39
              ;
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [ ];
            shellHook = ''
              test -d .profiles || mkdir -v .profiles
              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true
              test -L .profiles/dev-shell-default \
              || nix build --impure $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default
            '';
          };
        }
      )
    // {
      #
    };
}
