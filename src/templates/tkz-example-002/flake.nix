{
  description = "A Nix flake for building the 1D Navigation block diagram from texample.net";

  /*

    # 25.11
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
      # inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        fooBar = prev.hello;

        # Creates the 1D Navigation LaTeX source
        # Source: https://texample.net/nav1d/
        # Author: Kjell Magne Fauske
        nav1dDiagram = final.writeTextDir "nav1d.tex" ''
          \documentclass{article}
          \usepackage{tikz}
          \usetikzlibrary{arrows}

          \begin{document}
          \pagestyle{empty}

          %
          \tikzstyle{int}=[draw, fill=blue!20, minimum size=2em]
          \tikzstyle{init} = [pin edge={to-,thin,black}]

          \begin{tikzpicture}[node distance=2.5cm,auto,>=latex']
              \node [int, pin={[init]above:$v_0$}] (a) {$\frac{1}{s}$};
              \node (b) [left of=a,node distance=2cm, coordinate] {a};
              \node [int, pin={[init]above:$p_0$}] (c) [right of=a] {$\frac{1}{s}$};
              \node [coordinate] (end) [right of=c, node distance=2cm]{};
              \path[->] (b) edge node {$a$} (a);
              \path[->] (a) edge node {$v$} (c);
              \draw[->] (c) edge node {$p$} (end) ;
          \end{tikzpicture}

          \end{document}
        '';

        tex = final.texlive.combine {
          inherit (final.texlive) scheme-full;
        };

        nav1dDiagramPDF = final.stdenvNoCC.mkDerivation {
          name = "nav1d";
          src = final.nav1dDiagram;
          buildInputs = with final; [ coreutils tex ];

          buildPhase = ''
            export PATH="${with final; lib.makeBinPath [ coreutils tex ]}";
            export HOME="$TEMPDIR"; # pdflatex needs a writable home for font cache

            pdflatex $name.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp -v $name.pdf $out/
          '';
          dontPatchELF = true;
          dontFixup = true;
        };

        testNixos = prev.testers.runNixOSTest {
          name = "ocr-from-pdf";
          nodes.machine = { config, pkgs, lib, modulesPath, ... }:
            {
              imports = [
                "${dirOf modulesPath}/tests/common/x11.nix"
                "${dirOf modulesPath}/tests/common/user-account.nix"
              ];
              services.xserver.enable = true;
              services.xserver.displayManager.startx.enable = true;
              environment.systemPackages = with pkgs; [
                firefox
                kdePackages.okular
              ];
            };
          enableOCR = true;
          skipLint = false;
          skipTypeCheck = true;
          globalTimeout = 2 * 60;
          testScript = ''
            start_all()

            machine.wait_for_unit('graphical.target')

            machine.execute("okular ${final.nav1dDiagramPDF}/${final.nav1dDiagramPDF.name}.pdf >&2 &")
            machine.screenshot("okular1")
            machine.wait_for_window("okular")
            machine.succeed("${prev.xdotool}/bin/xdotool mousemove 0 0")
            machine.screenshot("okular2")
          '';
        };

        scriptShowInFirefox = prev.writeShellApplication {
          name = "script-firefox";
          runtimeInputs = with final; [ bash firefox nav1dDiagramPDF ];
          text = ''
            firefox "${final.nav1dDiagramPDF}"/"${final.nav1dDiagramPDF.name}".pdf
          '';
        };

        scriptShowInOkular = prev.writeShellApplication {
          name = "script-show-in-okular";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.nav1dDiagramPDF}"/"${final.nav1dDiagramPDF.name}".pdf
          '';
        };

        scriptShowPrintInOkular = prev.writeShellApplication {
          name = "script-show-print-screen-okular";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.testNixos}"/okular2.png
          '';
        };

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'

              # TODO: it errors out "may not be deterministic"
              # && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
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

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {
          packages = {
            inherit (pkgsAllowUnfree)
              allTests
              nav1dDiagram
              nav1dDiagramPDF
              scriptShowInFirefox
              scriptShowInOkular
              scriptShowPrintInOkular
              testNixos
              ;
            default = pkgsAllowUnfree.nav1dDiagramPDF;
          };

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          apps = {
            allTests = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.allTests}";
              meta.description = "Run all tests for this flake";
            };
            default = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInOkular}";
              meta.description = "Show the 1D Navigation PDF in Okular";
            };
            scriptShowInFirefox = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInFirefox}";
              meta.description = "Show the 1D Navigation PDF in Firefox";
            };
            scriptShowPrintInOkular = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowPrintInOkular}";
              meta.description = "Show the NixOS test screenshot in Okular";
            };
          };

          checks = {
            inherit (pkgsAllowUnfree)
              allTests
              nav1dDiagram
              nav1dDiagramPDF
              testNixos
              scriptShowInFirefox
              ;
            default = pkgsAllowUnfree.nav1dDiagramPDF;
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
            ];
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
