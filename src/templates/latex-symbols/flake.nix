{
  description = "Comprehensive LaTeX Symbol List — multi-package symbol reference PDF";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

        texEnv = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-small
            latexmk
            # symbol packages
            wasysym
            wasy # font files required by wasysym
            marvosym
            psnfss
            stmaryrd
            ifsym
            # layout
            booktabs
            ;
        };

        latex-symbols = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-symbols";
          src = ./sample;
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath [ texEnv pkgs.coreutils ]}";
            export TEXMFHOME="$PWD/.cache"
            export TEXMFVAR="$PWD/.cache/texmf-var"
            mkdir -pv "$TEXMFVAR"
            latexmk \
              -f \
              -interaction=nonstopmode \
              -outdir=/build \
              -pdf \
              symbols.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp -v /build/symbols.pdf $out/
            cp -v /build/symbols.log $out/ 2>/dev/null || true
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
          buildInputs = [ texEnv ];
          shellHook = ''
            echo "latex-symbols dev shell"
            echo "  cd sample && pdflatex symbols.tex"
            echo "  cd sample && latexmk -pdf symbols.tex"
          '';
        };

        checks.default = latex-symbols;
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
