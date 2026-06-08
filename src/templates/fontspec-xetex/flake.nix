{
  description = "Minimal xetex document with fontspec — PDF build test";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        texDoc = pkgs.writeText "fontspec-test.tex" ''
          \documentclass{minimal}
          \begin{document}
          Hello
          \end{document}
        '';
        fontspec-xetex = pkgs.stdenvNoCC.mkDerivation {
          name = "fontspec-xetex";
          dontUnpack = true;
          nativeBuildInputs = [
            (pkgs.texlive.combine {
              inherit (pkgs.texlive) scheme-small xetex;
            })
          ];
          buildPhase = ''
            cp ${texDoc} fontspec-test.tex
            xelatex fontspec-test.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp fontspec-test.pdf $out/
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
        packages.default = fontspec-xetex;
        packages.allTests = allTests;

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${fontspec-xetex}/fontspec-test.pdf"
          '');
          meta.description = "fontspec-xetex — Firefox";
        };
        apps.firefox = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${fontspec-xetex}/fontspec-test.pdf"
          '');
          meta.description = "fontspec-xetex — Firefox";
        };
        apps.okular = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-okular" ''
            ${pkgs.kdePackages.okular}/bin/okular "${fontspec-xetex}/fontspec-test.pdf"
          '');
          meta.description = "fontspec-xetex — Okular";
        };
        apps.chromium = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-chromium" ''
            ${pkgs.chromium}/bin/chromium "${fontspec-xetex}/fontspec-test.pdf"
          '');
          meta.description = "fontspec-xetex — Chromium";
        };

        apps.allTests = {
          type = "app";
          program = pkgs.lib.getExe allTests;
          meta.description = "Run all tests for this flake";
        };

        checks.default = fontspec-xetex;
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
