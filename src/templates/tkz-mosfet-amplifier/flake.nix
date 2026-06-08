{
  description = "A Nix flake for building the MOSFET amplifier example from texample.net";

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

        # Creates the MOSFET amplifier LaTeX source
        # Source: https://texample.net/mosfet/
        # Author: Ramón Jaramillo
        mosfetAmplifier = final.writeTextDir "mosfet-amplifier.tex" ''
          % 18W MOSFET amplifier, with npn transistor.
          % Author: Ramón Jaramillo.
          \documentclass[margin=10pt]{standalone}
          \usepackage[siunitx]{circuitikz}
          \begin{document}
          \begin{tikzpicture}[scale=2]
            \draw[color=black, thick]
              (0,0) to [short,o-] (6,0){} % Baseline for connection to ground
              % Input and ground
              (0,1) node[]{\large{\textbf{INPUT}}}
              % Connection of passive components
              (5,0) node[ground]{} node[circ](4.5,0){}
              (0,2) to [pC, l=$C_1$, o-] (0.5,2)
              to [R,l=$R_1$,](1.5,2)
              to node[short]{}(2.6,2)
              (1.5,2) to [C, l=$C_2$, *-] (1.5,3) -| (5,3)
              (2.2,2) to [R, l=$R_2$, *-*] (2.2,3)
              (2.2,3) to [pC, l=$C_3$, *-] (2.2,5) -| (3,5)
              % Transistor Bipolar Q1
              (3,0) to [R,l=$R_5$,-*] (3,1.5)
              to [Tnpn,n=npn1] (3,2.5)
              (npn1.E) node[right=3mm, above=5mm]{$Q_1$}
              (4,0) to [pC, l_=$C_4$, *-] (4, 1.5)--(3,1.5)
              (2.2,0) to [vR, l=$R_3$, *-*] (2.2,2)
              (3,2.5) to node[short]{}(3,3)
              (3,5) to [pR, n=pot1, l_=$R_4$, *-] (3,3)
              (3,5) to [R, l=$R_6$, *-] (5,5)
              to [short,*-o](5,5.5) node[right]{$V_S=40 V$}
              % Mosfet Transistors
              (5,3) to [Tnigfetd,n=mos1] (5,5)
              (mos1.B) node[anchor=west]{$Q_2$}
              (pot1.wiper) to [R, l=$R_7$] (4.5,4) -| (mos1.G)
              (5,1.5) to [Tpigfetd,n=mos2] (5,2.5)
              (5,0) to (mos2.S)
              (3,2.5) to [R, l=$R_8$, *-] (4.5,2.5)
              -| (mos2.G)
              (mos2.B) node[anchor=west]{$Q_3$}
              % Output
              (6,3) to [pC, l=$C_5$,-*](5,3)
              (6,3) to [short,-o] (6,2){}
              (mos1.S)--(mos2.D)
              (6,0) to [short,-o] (6,1){} node[above=7mm]{\large{\textbf{SPEAKER}}}
              ;
          \end{tikzpicture}
          \end{document}
        '';

        tex = final.texlive.combine {
          inherit (final.texlive) scheme-full standalone circuitikz siunitx;
        };

        mosfetAmplifierPDF = final.stdenvNoCC.mkDerivation {
          name = "mosfet-amplifier";
          src = final.mosfetAmplifier;
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

            machine.execute("okular ${final.mosfetAmplifierPDF}/${final.mosfetAmplifierPDF.name}.pdf >&2 &")
            machine.screenshot("okular1")
            machine.wait_for_window("okular")
            machine.succeed("${prev.xdotool}/bin/xdotool mousemove 0 0")
            machine.screenshot("okular2")
          '';
        };

        scriptShowInFirefox = prev.writeShellApplication {
          name = "script-firefox";
          runtimeInputs = with final; [ bash firefox mosfetAmplifierPDF ];
          text = ''
            firefox "${final.mosfetAmplifierPDF}"/"${final.mosfetAmplifierPDF.name}".pdf
          '';
        };

        scriptShowInOkular = prev.writeShellApplication {
          name = "script-show-in-okular";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.mosfetAmplifierPDF}"/"${final.mosfetAmplifierPDF.name}".pdf
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
              mosfetAmplifier
              mosfetAmplifierPDF
              scriptShowInFirefox
              scriptShowInOkular
              scriptShowPrintInOkular
              testNixos
              ;
            default = pkgsAllowUnfree.mosfetAmplifierPDF;
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
              meta.description = "Show the MOSFET amplifier PDF in Okular";
            };
            scriptShowInFirefox = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInFirefox}";
              meta.description = "Show the MOSFET amplifier PDF in Firefox";
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
              mosfetAmplifier
              mosfetAmplifierPDF
              testNixos
              scriptShowInFirefox
              ;
            default = pkgsAllowUnfree.mosfetAmplifierPDF;
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
            ];
            shellHook = ''
              test -d .profiles || mkdir -v .profiles
              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true
              test -L .profiles/dev-shell-${suportedSystem}-default \
              || nix build --impure $(nix eval --impure --raw .#devShells."${suportedSystem}".default.drvPath) --out-link .profiles/dev-shell-${suportedSystem}-default
            '';
          };
        }
      )
    // {
      #
    };
}
