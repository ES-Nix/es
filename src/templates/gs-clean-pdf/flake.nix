{
  description = "Ghostscript-compressed PDF (input: lualatex Hello World, rebuilt inline)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        latex-demo-document = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-demo-document";
          src = pkgs.writeTextDir "latex-demo-document.tex" ''
            \documentclass[a4paper]{article}

            \begin{document}
              \fontsize{72}{86}\selectfont Hello, World!
            \end{document}
          '';
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath [
                pkgs.coreutils
                (pkgs.texlive.combine {
                  inherit (pkgs.texlive) scheme-minimal latex-bin latexmk lm;
                })
              ]}";
            export TEXMFHOME="$PWD/.cache"
            export TEXMFVAR="$PWD/.cache/texmf-var"
            mkdir -pv "$TEXMFVAR"
            latexmk \
              -f \
              -interaction=nonstopmode \
              -outdir=/build \
              -pdf \
              -lualatex \
              $src/latex-demo-document.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp -rv /build/{*.pdf,*.log,*.fls,*.fdb_latexmk,*.aux} $out/
          '';
        };
        gs-clean-pdf = pkgs.stdenvNoCC.mkDerivation {
          name = "gs-clean-pdf";
          dontUnpack = true;
          nativeBuildInputs = [ pkgs.ghostscript ];
          buildPhase = ''
            gs -dNOPAUSE -sDEVICE=pdfwrite \
               -sOUTPUTFILE=clean.pdf -dBATCH \
               ${latex-demo-document}/latex-demo-document.pdf
          '';
          installPhase = ''
            mkdir -p $out
            cp clean.pdf $out/
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
        packages.default = gs-clean-pdf;
        packages.allTests = allTests;

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${gs-clean-pdf}/clean.pdf"
          '');
          meta.description = "gs-clean-pdf — Firefox";
        };
        apps.firefox = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${gs-clean-pdf}/clean.pdf"
          '');
          meta.description = "gs-clean-pdf — Firefox";
        };
        apps.okular = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-okular" ''
            ${pkgs.kdePackages.okular}/bin/okular "${gs-clean-pdf}/clean.pdf"
          '');
          meta.description = "gs-clean-pdf — Okular";
        };
        apps.chromium = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-chromium" ''
            ${pkgs.chromium}/bin/chromium "${gs-clean-pdf}/clean.pdf"
          '');
          meta.description = "gs-clean-pdf — Chromium";
        };

        apps.allTests = {
          type = "app";
          program = pkgs.lib.getExe allTests;
          meta.description = "Run all tests for this flake";
        };

        checks.default = gs-clean-pdf;
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
