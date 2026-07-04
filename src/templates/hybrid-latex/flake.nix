{
  description = "leo-brewin/hybrid-latex — Python-inside-LaTeX document builder";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        pythonEnv = pkgs.python3.withPackages (ps: [
          ps.sympy
          ps.matplotlib
          ps.mpmath
          ps.scipy
        ]);

        texEnv = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-small amsmath listings;
        };

        hybrid-latex = pkgs.stdenvNoCC.mkDerivation {
          pname = "hybrid-latex";
          version = "0.3";

          src = pkgs.fetchFromGitHub {
            owner = "leo-brewin";
            repo = "hybrid-latex";
            rev = "751aebee2cbde13a6593860bef90fec9575b4df4";
            hash = "sha256-q27oItlOHSvYlmRqT7yXhMERj0sNslJNrtUPcceyXEM=";
          };

          nativeBuildInputs = [ pkgs.makeWrapper pythonEnv ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/lib $out/tex

            install -m 0755 python/scripts/pylatex.sh    $out/bin/
            install -m 0755 python/scripts/pypreproc.py  $out/bin/
            install -m 0755 python/scripts/pypostproc.py $out/bin/
            install -m 0755 python/scripts/pycopy.py     $out/bin/
            install -m 0755 python/scripts/merge-src.py  $out/bin/
            install -m 0755 python/scripts/pyclean.sh    $out/bin/
            install -m 0644 python/scripts/pylatex.sed   $out/bin/.pylatex.sed

            substituteInPlace $out/bin/pylatex.sh \
              --replace-fail '/opt/homebrew/bin/gsed' 'sed'

            install -m 0644 python/python/writecode.py   $out/lib/
            install -m 0644 python/python/cdblib.py      $out/lib/

            install -m 0644 python/latex/pylatex.cls     $out/tex/
            install -m 0644 python/latex/pylatex.sty     $out/tex/
            install -m 0644 python/latex/pymacros.sty    $out/tex/

            patchShebangs $out/bin/

            runHook postInstall
          '';

          postInstall = ''
            wrapProgram $out/bin/pylatex.sh \
              --prefix PATH : "${pythonEnv}/bin:${texEnv}/bin:$out/bin" \
              --set    TEXINPUTS "$out/tex/:" \
              --prefix PYTHONPATH : "$out/lib"
          '';

          meta = {
            description = "Embed and execute Python code inside LaTeX documents";
            homepage = "https://github.com/leo-brewin/hybrid-latex";
            license = pkgs.lib.licenses.mit;
            mainProgram = "pylatex.sh";
          };
        };

        sampleDoc = pkgs.stdenvNoCC.mkDerivation {
          name = "hybrid-latex-sample";
          src = ./sample;

          nativeBuildInputs = [ hybrid-latex pythonEnv texEnv ];

          buildPhase = ''
            export HOME=$TMPDIR
            pylatex.sh -s -i main
          '';

          installPhase = ''
            mkdir -p $out
            cp main.pdf $out/
          '';

          dontFixup = true;
        };

        allTests = pkgs.writeShellApplication {
          name = "all-tests";
          runtimeInputs = [ ];
          text = ''
            set -e
            nix fmt .
            nix flake show --all-systems
            nix build --no-link --print-build-logs .#hybrid-latex
            nix build --no-link --print-build-logs .#sampleDoc
            nix flake check --all-systems --verbose
          '';
        };

      in
      {
        packages = {
          inherit hybrid-latex sampleDoc allTests;
          default = sampleDoc;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe' hybrid-latex "pylatex.sh"}";
            meta.description = "Compile LaTeX document with Python preprocessing";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe allTests}";
            meta.description = "Run all tests for hybrid-latex template";
          };
        };

        checks = {
          sample = sampleDoc;
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          packages = [ hybrid-latex pythonEnv texEnv pkgs.nixpkgs-fmt ];
          shellHook = ''
            echo "hybrid-latex dev shell"
            echo "  pylatex.sh -s -i <basename>   run the hybrid-latex pipeline"
          '';
        };
      }
    );
}
