{
  description = "Pandoc MANUAL.txt converted to PDF via xelatex";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        pandoc-manual-xelatex = pkgs.stdenvNoCC.mkDerivation {
          name = "pandoc-manual-xelatex";
          src = pkgs.haskellPackages.pandoc.src;
          nativeBuildInputs = [
            pkgs.pandoc
            (pkgs.texlive.combine {
              inherit (pkgs.texlive) scheme-medium xetex;
            })
          ];
          buildPhase = ''
            pandoc MANUAL.txt --pdf-engine=xelatex -o example13.pdf
          '';
          installPhase = ''
            mkdir -p $out
            cp example13.pdf $out/
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
        packages.default = pandoc-manual-xelatex;
        packages.allTests = allTests;

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${pandoc-manual-xelatex}/example13.pdf"
          '');
          meta.description = "pandoc-manual-xelatex — Firefox";
        };
        apps.firefox = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${pandoc-manual-xelatex}/example13.pdf"
          '');
          meta.description = "pandoc-manual-xelatex — Firefox";
        };
        apps.okular = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-okular" ''
            ${pkgs.kdePackages.okular}/bin/okular "${pandoc-manual-xelatex}/example13.pdf"
          '');
          meta.description = "pandoc-manual-xelatex — Okular";
        };
        apps.chromium = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-chromium" ''
            ${pkgs.chromium}/bin/chromium "${pandoc-manual-xelatex}/example13.pdf"
          '');
          meta.description = "pandoc-manual-xelatex — Chromium";
        };

        apps.allTests = {
          type = "app";
          program = pkgs.lib.getExe allTests;
          meta.description = "Run all tests for this flake";
        };

        checks.default = pandoc-manual-xelatex;
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
