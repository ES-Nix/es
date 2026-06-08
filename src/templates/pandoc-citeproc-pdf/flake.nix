{
  description = "Pandoc bibliography pipeline — citeproc + xelatex to PDF";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        pandoc-citeproc-pdf = pkgs.stdenvNoCC.mkDerivation {
          name = "pandoc-citeproc-pdf";
          dontUnpack = true;
          nativeBuildInputs = [
            pkgs.pandoc
            (pkgs.texlive.combine {
              inherit (pkgs.texlive) scheme-small xetex;
            })
          ];
          buildPhase = ''
            printf '%s\n' '@article{foo,author={A},title={T},year={2020},journal={J}}' > biblio.bib
            printf '%s\n' '---' 'title: Test' '---' 'See @foo.' > citations.md
            pandoc --standalone --bibliography biblio.bib --citeproc \
              --pdf-engine=xelatex citations.md -o example24a.pdf
          '';
          installPhase = ''
            mkdir -p $out
            cp example24a.pdf $out/
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
        packages.default = pandoc-citeproc-pdf;
        packages.allTests = allTests;

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${pandoc-citeproc-pdf}/example24a.pdf"
          '');
          meta.description = "pandoc-citeproc-pdf — Firefox";
        };
        apps.firefox = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${pandoc-citeproc-pdf}/example24a.pdf"
          '');
          meta.description = "pandoc-citeproc-pdf — Firefox";
        };
        apps.okular = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-okular" ''
            ${pkgs.kdePackages.okular}/bin/okular "${pandoc-citeproc-pdf}/example24a.pdf"
          '');
          meta.description = "pandoc-citeproc-pdf — Okular";
        };
        apps.chromium = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-chromium" ''
            ${pkgs.chromium}/bin/chromium "${pandoc-citeproc-pdf}/example24a.pdf"
          '');
          meta.description = "pandoc-citeproc-pdf — Chromium";
        };

        apps.allTests = {
          type = "app";
          program = pkgs.lib.getExe allTests;
          meta.description = "Run all tests for this flake";
        };

        checks.default = pandoc-citeproc-pdf;
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
