{
  description = "A Nix flake for generating a simple LaTeX document and viewing it with Firefox or Okular";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/c1dfcf08411b08f6b8615f7d8971a2bfa81d5e8a'

    # Last commit from github:NixOS/nixpkgs/nixos-24.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/50ab793786d9de88ee30ec4e4c24fb4236fc2674' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' 

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'    

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
        fontspecTest = final.writeTextDir "fontspec-test.tex" ''
          \documentclass{beamer}
    
          \usetheme{Madrid}
          \usepackage{tikz}
          \usetikzlibrary{positioning}
          \setbeamercovered{dynamic}
          \usetikzlibrary{shapes,arrows, positioning, calc}  
          \usetikzlibrary{overlay-beamer-styles}
        
          \begin{document}
    
          \newcommand{\myani}{1-}
    
          \begin{frame}[label=foo]
          \transduration<\myani>{1}
          \begin{center}
          \begin{tikzpicture}[auto]
              \draw(-2.7,1.5) node[sloped,above] {Start A};
        
              \draw[->,thick] (-2,0.5)  -- node[below] {T} (4,0.5) ;
        
              \draw[visible on=<1>,gray,-,thick,dashed] (-1.7,1.7)  -- (3.7,1.7);
              \draw[visible on=<1>] (1,1.8) node[sloped,above] {text};
        
              \draw[visible on=<2>,gray,-,thick,dashed] (-1.7,1.7)  -- (-0.3,1.7);
              \draw[visible on=<2>,gray,-,thick,dashed] (2.3,1.7)  -- (3.7,1.7); 
              \draw[visible on=<2>](3,2.5) node[sloped,above] {text};
              \draw[visible on=<2>](1,1.68) node[sloped,above] {Point};
              \draw[visible on=<2>](1,1.18) node[sloped,above] {C};
        
              \draw(4.7,1.90) node[sloped,above] {Point};
              \draw(4.7,1.45) node[sloped,above] {B};
          \end{tikzpicture}
          \end{center}
          \end{frame}
    
          \foreach \x in {0,...,10}{
          \againframe{foo}
          }
    
          \renewcommand{\myani}{1}
          \againframe{foo}
    
          \begin{frame}
          content
          \end{frame}
          \end{document}
        '';

        fontspecTest2 = final.writeTextDir "fontspec-test.tex" ''
          \documentclass{beamer}
          \usetheme{Madrid}

          \usepackage{tikz}
          \usetikzlibrary{overlay-beamer-styles}

          \begin{document}

          \begin{frame}{}
          \begin{center}
          \begin{tikzpicture}

              % --- Static elements ---
              \node at (-2.7,1.5) {Start A};
              \draw[->, thick] (-2,0.5) -- node[below] {T} (4,0.5);

              \node at (4.7,1.9) {Point};
              \node at (4.7,1.45) {B};

              % --- Step 1 ---
              \draw<1->[gray, thick, dashed] (-1.7,1.7) -- (3.7,1.7);
              \node<1-> at (1,1.8) {text};

              % --- Step 2 additions ---
              \draw<2->[gray, thick, dashed] (-1.7,1.7) -- (-0.3,1.7);
              \draw<2->[gray, thick, dashed] (2.3,1.7) -- (3.7,1.7);
              \node<2-> at (3,2.5) {text};
              \node<2-> at (1,1.68) {Point};
              \node<2-> at (1,1.18) {C};

          \end{tikzpicture}
          \end{center}
          \end{frame}

          \begin{frame}
          content
          \end{frame}

          \end{document}
        '';

        tex = final.texlive.combine {
          inherit (final.texlive) scheme-full xetex fontspec euenc;
        };

        XeLaTeXFontspecExample = final.stdenvNoCC.mkDerivation {
          name = "xelatex-fontspec-example";
          src = final.fontspecTest2;
          buildInputs = [ final.coreutils final.tex ];
          FONTCONFIG_FILE = final.makeFontsConf { fontDirectories = [ final.lmodern ]; };

          buildPhase = ''
            export PATH="${final.lib.makeBinPath [ final.coreutils final.tex ] }";
            export HOME="$TEMPDIR"; # Fontconfig error: No writable cache directories

            xelatex fontspec-test.tex 
          '';
          installPhase = ''
            mkdir -p $out
            cp -v fontspec-test.pdf $out/$name.pdf
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
              #    # okular --presentation ''${pkgs.XeLaTeXFontspecExample}/XeLaTeXFontspecExample.pdf
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

            machine.execute("okular --presentation ${final.XeLaTeXFontspecExample}/fontspec-test.pdf >&2 &")
            machine.screenshot("okular1")
            machine.wait_for_text("There are two ways of exiting")
            machine.send_key("esc")
            # Move the mouse out of the way
            machine.succeed("${prev.xdotool}/bin/xdotool mousemove 0 0")
            # machine.wait_for_text(r"(Start A)")
            machine.screenshot("okular2")
          '';
        };

        scriptFirefox = prev.writeShellApplication {
          name = "script-firefox";
          runtimeInputs = with final; [ bash firefox XeLaTeXFontspecExample ];
          text = ''
            echo "${final.XeLaTeXFontspecExample}"
            firefox "${final.XeLaTeXFontspecExample}"/xelatex-fontspec-example.pdf
          '';
        };

        scriptShowPrintScreenFirefox = prev.writeShellApplication {
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
              XeLaTeXFontspecExample
              scriptFirefox
              testNixos
              ;
            default = pkgsAllowUnfree.XeLaTeXFontspecExample;
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
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptFirefox}";
              meta.description = "Test NixOS with Firefox showing a PDF generated with LaTeX";
            };
            scriptShowPrintScreenFirefox = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowPrintScreenFirefox}";
              meta.description = "Script showing a PDF generated with LaTeX";
            };
          };

          checks = {
            inherit (pkgsAllowUnfree)
              allTests
              XeLaTeXFontspecExample
              scriptFirefox
              ;
            default = pkgsAllowUnfree.XeLaTeXFontspecExample;
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
