{
  description = "A Nix flake for building the 3D Cone TikZ example from texample.net";

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

        # 3D Cone TikZ example from https://texample.net/3d-cone/
        # Author: Gene Ressler. Adapted to TikZ by Kjell Magne Fauske.
        threeDCone = final.writeTextDir "3d-cone.tex" ''
          % 3D Cone
          % Author: Gene Ressler. Adapted to TikZ by Kjell Magne Fauske.
          % See https://texample.net/3d-cone/ for more details.
          \documentclass{article}
          \usepackage{tikz}

          \begin{document}
          \pagestyle{empty}

          \begin{tikzpicture}[join=round]
              \tikzstyle{conefill} = [fill=blue!20,fill opacity=0.8]
              \tikzstyle{ann} = [fill=white,font=\footnotesize,inner sep=1pt]
              \tikzstyle{ghostfill} = [fill=white]
              \tikzstyle{ghostdraw} = [draw=black!50]
              \filldraw[conefill](-.775,1.922)--(-1.162,.283)--(-.274,.5)--(-.183,2.067)--cycle;
              \filldraw[conefill](-.183,2.067)--(-.274,.5)--(.775,.424)--(.516,2.016)--cycle;
              \filldraw[conefill](.516,2.016)--(.775,.424)--(1.369,.1)--(.913,1.8)--cycle;
              \filldraw[conefill](-.913,1.667)--(-1.369,-.1)--(-1.162,.283)--(-.775,1.922)--cycle;
              \draw(1.461,.107)--(1.734,.127);
              \draw[arrows=<->](1.643,1.853)--(1.643,.12);
              \filldraw[conefill](.913,1.8)--(1.369,.1)--(1.162,-.283)--(.775,1.545)--cycle;
              \draw[arrows=->,line width=.4pt](.274,-.5)--(0,0)--(0,2.86);
              \draw[arrows=-,line width=.4pt](0,0)--(-1.369,-.1);
              \draw[arrows=->,line width=.4pt](-1.369,-.1)--(-2.1,-.153);
              \filldraw[conefill](-.516,1.45)--(-.775,-.424)--(-1.369,-.1)--(-.913,1.667)--cycle;
              \draw(-1.369,.073)--(-1.369,2.76);
              \draw(1.004,1.807)--(1.734,1.86);
              \filldraw[conefill](.775,1.545)--(1.162,-.283)--(.274,-.5)--(.183,1.4)--cycle;
              \draw[arrows=<->](0,2.34)--(-.913,2.273);
              \draw(-.913,1.84)--(-.913,2.447);
              \draw[arrows=<->](0,2.687)--(-1.369,2.587);
              \filldraw[conefill](.183,1.4)--(.274,-.5)--(-.775,-.424)--(-.516,1.45)--cycle;
              \draw[arrows=<-,line width=.4pt](.42,-.767)--(.274,-.5);
              \node[ann] at (-.456,2.307) {$r_0$};
              \node[ann] at (-.685,2.637) {$r_1$};
              \node[ann] at (1.643,.987) {$h$};
              \path (.42,-.767) node[below] {$x$}
                  (0,2.86) node[above] {$y$}
                  (-2.1,-.153) node[left] {$z$};

              \begin{scope}[xshift=3.5cm]
              \filldraw[ghostdraw,ghostfill](-.775,1.922)--(-1.162,.283)--(-.274,.5)--(-.183,2.067)--cycle;
              \filldraw[ghostdraw,ghostfill](-.183,2.067)--(-.274,.5)--(.775,.424)--(.516,2.016)--cycle;
              \filldraw[ghostdraw,ghostfill](.516,2.016)--(.775,.424)--(1.369,.1)--(.913,1.8)--cycle;
              \filldraw[ghostdraw,ghostfill](-.913,1.667)--(-1.369,-.1)--(-1.162,.283)--(-.775,1.922)--cycle;
              \filldraw[ghostdraw,ghostfill](.913,1.8)--(1.369,.1)--(1.162,-.283)--(.775,1.545)--cycle;
              \filldraw[ghostdraw,ghostfill](-.516,1.45)--(-.775,-.424)--(-1.369,-.1)--(-.913,1.667)--cycle;
              \filldraw[ghostdraw,ghostfill](.775,1.545)--(1.162,-.283)--(.274,-.5)--(.183,1.4)--cycle;
              \filldraw[fill=red,fill opacity=0.5](-.516,1.45)--(-.775,-.424)--(.274,-.5)--(.183,1.4)--cycle;
              \fill(-.775,-.424) circle (2pt);
              \fill(.274,-.5) circle (2pt);
              \fill(-.516,1.45) circle (2pt);
              \fill(.183,1.4) circle (2pt);
              \path[font=\footnotesize]
                      (.913,1.8) node[right] {$i\hbox{$=$}0$}
                      (1.369,.1) node[right] {$i\hbox{$=$}1$};
              \path[font=\footnotesize]
                      (-.645,.513) node[left] {$j$}
                      (.228,.45) node[right] {$j\hbox{$+$}1$};
              \draw (-.209,.482)+(-60:.25) [yscale=1.3,->] arc(-60:240:.25);
              \fill[black,font=\footnotesize]
                              (-.516,1.45) node [above] {$P_{00}$}
                              (-.775,-.424) node [below] {$P_{10}$}
                              (.183,1.4) node [above] {$P_{01}$}
                              (.274,-.5) node [below] {$P_{11}$};
              \end{scope}
          \end{tikzpicture}

          \end{document}
        '';

        tex = final.texlive.combine {
          inherit (final.texlive) scheme-full;
        };

        pdfLaTeXThreeDCone = final.stdenvNoCC.mkDerivation {
          name = "3d-cone";
          src = final.threeDCone;
          buildInputs = with final; [ coreutils tex ];

          buildPhase = ''
            export PATH="${ with final; lib.makeBinPath [ coreutils tex ] }";

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
            let
              # user = config.users.users.alice;
            in
            {
              imports = [
                # "${pkgs.path}/nixos/tests/common/x11.nix"
                # "${pkgs.path}/nixos/tests/common/user-account.nix"
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
          # hostPkgs = pkgsAllowUnfree;
          enableOCR = true;
          skipLint = false; # Disable linting for simpler debugging of the testScript
          skipTypeCheck = true;
          globalTimeout = 2 * 60;
          testScript = ''
            start_all()

            machine.wait_for_unit('graphical.target')

            machine.execute("okular ${final.pdfLaTeXThreeDCone}/${final.pdfLaTeXThreeDCone.name}.pdf >&2 &")
            machine.screenshot("okular1")
            machine.wait_for_text(r"(Okular|3d-cone|cone)")
            machine.send_key("esc")
            # Move the mouse out of the way
            machine.succeed("${prev.xdotool}/bin/xdotool mousemove 0 0")
            machine.screenshot("okular2")
          '';
        };

        scriptShowInFirefox = prev.writeShellApplication {
          name = "script-firefox";
          runtimeInputs = with final; [ bash firefox pdfLaTeXThreeDCone ];
          text = ''
            firefox "${final.pdfLaTeXThreeDCone}"/"${final.pdfLaTeXThreeDCone.name}".pdf
          '';
        };

        scriptShowInOkular = prev.writeShellApplication {
          name = "script-show-print-screen-firefox";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.pdfLaTeXThreeDCone}"/"${final.pdfLaTeXThreeDCone.name}".pdf
          '';
        };

        scriptShowPrintInOkular = prev.writeShellApplication {
          name = "script-show-print-screen-firefox";
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
              threeDCone
              scriptShowInFirefox
              scriptShowInOkular
              scriptShowPrintInOkular
              testNixos
              pdfLaTeXThreeDCone
              ;
            default = pkgsAllowUnfree.pdfLaTeXThreeDCone;
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
              meta.description = "Test NixOS with Okular showing the 3D Cone PDF generated with LaTeX";
            };
            scriptShowInFirefox = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInFirefox}";
              meta.description = "Script showing the 3D Cone PDF generated with LaTeX";
            };
            scriptShowPrintInOkular = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowPrintInOkular}";
              meta.description = "Script showing the PDF print screen generated in the NixOS test";
            };
          };

          checks = {
            inherit (pkgsAllowUnfree)
              allTests
              threeDCone
              testNixos
              pdfLaTeXThreeDCone
              scriptShowInFirefox
              ;
            default = pkgsAllowUnfree.pdfLaTeXThreeDCone;
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
