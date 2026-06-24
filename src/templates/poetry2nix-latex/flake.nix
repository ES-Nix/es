{
  description = "Python (poetry2nix) generates a LaTeX document compiled to PDF";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication cleanPythonSources;

        myapp = mkPoetryApplication {
          projectDir = cleanPythonSources { src = ./.; };
        } // { meta.mainProgram = "start"; };

        latex-report = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-report";
          phases = [ "buildPhase" "installPhase" ];
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath [
              pkgs.coreutils
              (pkgs.texlive.combine {
                inherit (pkgs.texlive) scheme-basic latexmk lm booktabs geometry lastpage;
              })
            ]}";
            export TEXMFHOME="$PWD/.cache"
            export TEXMFVAR="$PWD/.cache/texmf-var"
            mkdir -pv "$TEXMFVAR"
            ${myapp}/bin/start > report.tex
            latexmk \
              -f \
              -interaction=nonstopmode \
              -outdir=/build \
              -pdf \
              -lualatex \
              report.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp -rv /build/{*.pdf,*.log,*.fls,*.fdb_latexmk,*.aux} $out/
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
        packages.default = latex-report;
        packages.myapp = myapp;
        packages.allTests = allTests;

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${latex-report}/report.pdf"
          '');
          meta.description = "latex-report — Firefox";
        };
        apps.firefox = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-firefox" ''
            ${pkgs.firefox}/bin/firefox "${latex-report}/report.pdf"
          '');
          meta.description = "latex-report — Firefox";
        };
        apps.okular = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-okular" ''
            ${pkgs.kdePackages.okular}/bin/okular "${latex-report}/report.pdf"
          '');
          meta.description = "latex-report — Okular";
        };
        apps.chromium = {
          type = "app";
          program = toString (pkgs.writeShellScript "view-chromium" ''
            ${pkgs.chromium}/bin/chromium "${latex-report}/report.pdf"
          '');
          meta.description = "latex-report — Chromium";
        };
        apps.allTests = {
          type = "app";
          program = pkgs.lib.getExe allTests;
          meta.description = "Run all tests for this flake";
        };

        checks.default = latex-report;
        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          inputsFrom = [ myapp ];
          packages = [ pkgs.poetry ];
        };
      }
    );
}
