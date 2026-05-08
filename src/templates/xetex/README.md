
```bash
nix run '.#allTests'
```
Refs.:
- 



```bash
EXPR=$(cat <<-'EOF'
(
let
   nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852"); 
   pkgs = import nixpkgs {};

  # Creates a XeLaTeX test for font
  fontspecTest = pkgs.writeTextDir "fontspec-test.tex" ''
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
  tex = pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-full xetex fontspec euenc;
  };
in 
  pkgs.stdenvNoCC.mkDerivation {
          name = "xelatex-fontspec-test";
          src = fontspecTest;
          buildInputs = [ pkgs.coreutils tex ];
          FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.lmodern ]; };

          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath [ pkgs.coreutils tex ] }";
            export HOME="$TEMPDIR"; # Fontconfig error: No writable cache directories

            xelatex fontspec-test.tex 
          '';
          installPhase = ''
            mkdir -p $out
            cp -v fontspec-test.pdf $out/
          '';
          dontPatchELF = true;
          dontFixup = true;
      }
)
EOF
)

nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--impure \
--expr \
"$EXPR"


file $(
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--impure \
--expr \
"$EXPR"
)/fontspec-test.pdf
```
Refs.:
- https://stackoverflow.com/q/67824609
