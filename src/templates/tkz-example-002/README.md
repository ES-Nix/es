
```bash
nix run '.#allTests' 
```
Refs.:
- 



```bash
EXPR=$(cat <<-'EOF'
(
let
   nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b"); 
   pkgs = import nixpkgs {};

  # Creates a XeLaTeX test for font
  pendulumAnimation = pkgs.writeTextDir "pendulum-animation.tex" ''
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
  tex = pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-full xetex fontspec euenc;
  };
in 
  pkgs.stdenvNoCC.mkDerivation {
          name = "pendulum-animation";
          src = pendulumAnimation;
          buildInputs = [ pkgs.coreutils tex ];
          FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.lmodern ]; };

          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath [ pkgs.coreutils tex ] }";
            export HOME="$TEMPDIR"; # Fontconfig error: No writable cache directories

            xelatex pendulum-animation.tex 
          '';
          installPhase = ''
            mkdir -p $out
            cp -v pendulum-animation.pdf $out/
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

```
Refs.:
- https://tex.stackexchange.com/a/660779
