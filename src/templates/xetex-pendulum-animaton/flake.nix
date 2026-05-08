{
  description = "A Nix flake for generating a simple LaTeX document and viewing it with Firefox or Okular";

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

        # Creates a XeLaTeX test for font
        pendulumAnimation = final.writeTextDir "pendulum-animation.tex" ''
          \documentclass[border=10pt]{standalone}
          \usepackage{animate}
          \usepackage{tikz}
    
          \pgfmathsetmacro{\pendulumswing}{40}
          \pgfmathsetmacro{\pendulumlength}{5}
    
          \begin{document}
              \begin{animateinline}[controls, palindrome]{45}
                  \multiframe{45}{rt=0+4}{%
                      \begin{tikzpicture}[line width=1pt]
                          \draw[dashed] (0:0) -- (90:{-\pendulumlength}) coordinate (o);
                          \draw[dashed] ({90-\pendulumswing}:{-\pendulumlength}) coordinate (a)
                              arc[start angle={90-\pendulumswing}, end angle={90+\pendulumswing}, radius={-\pendulumlength}] coordinate (b);
                          \draw[dashed, red] (a) -- (a |- o) coordinate (c) node[below] {$-x_m$};
                          \draw[dashed, red] (b) -- (b |- o) coordinate (d) node[below] {$x_m$};
                          \draw[-stealth, red] ([xshift=-1cm]c) -- ([xshift=1cm]d);
                    
                          % variable \rt goes from 0 to 180
                          % cos(\rt) returns a value between -1 and 1 following a (co)sine curve
                          \pgfmathsetmacro{\pendulumangle}{cos(\rt)*\pendulumswing}
                          \draw (0:0) -- ({90+\pendulumangle}:{-\pendulumlength})
                                node[circle, fill=blue, text=white] {$\mathbf{m}$};
                      \end{tikzpicture}%
                  }%
              \end{animateinline}
          \end{document}
        '';

        tex = final.texlive.combine {
          inherit (final.texlive) scheme-full xetex fontspec euenc;
        };

        XeLaTeXPendulumAnimation = final.stdenvNoCC.mkDerivation {
          name = "pendulum-animation";
          src = final.pendulumAnimation;
          buildInputs = with final; [ coreutils tex ];
          FONTCONFIG_FILE = final.makeFontsConf { fontDirectories = [ final.lmodern ]; };

          buildPhase = ''
            export PATH="${ with final; lib.makeBinPath [ coreutils tex ] }";
            export HOME="$TEMPDIR"; # Fontconfig error: No writable cache directories

            xelatex $name.tex 
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
              # test-support.displayManager.auto.user = user.name;
              # services.xserver.displayManager.autoLogin.enable = true;
              # services.xserver.displayManager.autoLogin.user = user.name;
              # services.xserver.desktopManager.gnome.enable = true;
              # services.xserver.displayManager.sessionCommands = ''
              #    # okular --presentation ''${pkgs.XeLaTeXPendulumAnimation}/XeLaTeXPendulumAnimation.pdf
              #    ${pkgs.vscodium}/bin/codium
              # '';
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

            # machine.screenshot("firefox1")
            # machine.execute("firefox >&2 &")
            # machine.wait_for_text(r"(Mozilla Firefox|Directory listing for)")
            # machine.screenshot("firefox2")

            machine.execute("okular --presentation ${final.XeLaTeXPendulumAnimation}/${final.XeLaTeXPendulumAnimation.name}.pdf >&2 &")
            machine.screenshot("okular1")
            machine.wait_for_text("There are two ways of exiting")
            machine.send_key("esc")
            # Move the mouse out of the way
            machine.succeed("${prev.xdotool}/bin/xdotool mousemove 0 0")
            # machine.wait_for_text(r"(Start A)")
            machine.screenshot("okular2")
          '';
        };

        scriptShowInFirefox = prev.writeShellApplication {
          name = "script-firefox";
          runtimeInputs = with final; [ bash firefox XeLaTeXPendulumAnimation ];
          text = ''
            firefox "${final.XeLaTeXPendulumAnimation}"/"${final.XeLaTeXPendulumAnimation.name}".pdf
          '';
        };

        scriptShowInOkular = prev.writeShellApplication {
          name = "script-show-print-screen-firefox";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.XeLaTeXPendulumAnimation}"/"${final.XeLaTeXPendulumAnimation.name}".pdf
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
              pendulumAnimation
              scriptShowInFirefox
              scriptShowInOkular
              scriptShowPrintInOkular
              testNixos
              XeLaTeXPendulumAnimation
              ;
            default = pkgsAllowUnfree.XeLaTeXPendulumAnimation;
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
              meta.description = "Test NixOS with Firefox showing a PDF generated with LaTeX";
            };
            scriptShowInFirefox = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInFirefox}";
              meta.description = "Script showing a PDF generated with LaTeX";
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
              pendulumAnimation
              testNixos
              XeLaTeXPendulumAnimation
              scriptShowInFirefox
              ;
            default = pkgsAllowUnfree.XeLaTeXPendulumAnimation;
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
