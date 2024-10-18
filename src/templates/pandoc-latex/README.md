
```bash
mkdir -pv pandocLaTeX \
&& cd pandocLaTeX \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#pandocLaTeX

(direnv allow || true)

# nix build --impure --print-out-paths '.#'
# nix run '.#'
# nix build --print-build-logs --print-out-paths '.#checks.x86_64-linux.test-nixos'
nix flake check '.#' --verbose
```
Refs.:
- 


```bash
nix run '.#checks.x86_64-linux.test-nixos.driverInteractive'
```

```bash
start_all(); machine.shell_interact()
```


TODO: try to create this file to reduce calls to xdotool
```bash
~/.config/okularrc
```
Refs.:
- https://unix.stackexchange.com/a/578409


## gif if images differ with python

```bash
cd $(mktemp -d)

test -f left.jpg || curl -fsvSL https://i.stack.imgur.com/lWUlB.jpg -o left.jpg
test -f right.jpg || curl -fsvSL https://i.stack.imgur.com/gz9Kf.jpg -o right.jpg

cat << 'EOF' > script.py
import os
import cv2

import imageio.v2 as imageio
import numpy as np

from skimage.metrics import structural_similarity


def create_gif_if_images_differ(image1, image2,
    png_dir = '.',
    gif_name = 'shows-diff.gif',
    magic_number = 3):
    
    # Load images
    before = cv2.imread(image1)
    after = cv2.imread(image2)

    # Convert images to grayscale
    before_gray = cv2.cvtColor(before, cv2.COLOR_BGR2GRAY)
    after_gray = cv2.cvtColor(after, cv2.COLOR_BGR2GRAY)
    
    # Compute SSIM between the two images
    (score, diff) = structural_similarity(before_gray, after_gray, full=True)
    if score == 1.0:
        return True
    else:
        print("Image Similarity: {:.4f}%".format(score * 100))
        
        # The diff image contains the actual image differences between the two images
        # and is represented as a floating point data type in the range [0, 1] 
        # so we must convert the array to 8-bit unsigned integers in the range
        # [0, 255] before we can use it with OpenCV
        diff = (diff * 255).astype("uint8")
        diff_box = cv2.merge([diff, diff, diff])
        
        # Threshold the difference image, followed by finding contours to
        # obtain the regions of the two input images that differ
        thresh = cv2.threshold(diff, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
        contours = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        contours = contours[0] if len(contours) == 2 else contours[1]
        
        mask = np.zeros(before.shape, dtype='uint8')
        filled_after = after.copy()
        
        for c in contours:
        
            area = cv2.contourArea(c)
            if area > 40:
                x,y,w,h = cv2.boundingRect(c)
                cv2.rectangle(before, (x, y), (x + w, y + h), (36,255,12), 2)
                cv2.rectangle(after, (x, y), (x + w, y + h), (36,255,12), 2)
                cv2.rectangle(diff_box, (x, y), (x + w, y + h), (36,255,12), 2)
                cv2.drawContours(mask, [c], 0, (255,255,255), -1)
                cv2.drawContours(filled_after, [c], 0, (0,255,0), -1)
    
        cv2.imwrite('before.jpg', before)
        cv2.imwrite('after.jpg', after)
        # cv2.imwrite('diff.jpg', diff)
        # cv2.imwrite('diff_box.jpg', diff_box)
        # cv2.imwrite('mask.jpg', mask)
        # cv2.imwrite('filled_after.jpg', filled_after)
        
        images = []
        for file_name in sorted(os.listdir(png_dir)):
            if file_name.endswith('.jpg'):
               file_path = os.path.join(png_dir, file_name)
               images.append(imageio.imread(file_path))
         
        # Make it pause at the end so that the viewers can ponder
        for i in magic_number*list(images):
            images.append(i)
    
        imageio.mimsave(gif_name, images, loop=2)
        return False


image1 = 'left.jpg'
image2 = 'right.jpg'

create_gif_if_images_differ(image1, image2)

EOF

nix \
shell \
--expr \
'(                               
with builtins.getFlake "github:NixOS/nixpkgs/a5e4bbcb4780c63c79c87d29ea409abf097de3f7";
with legacyPackages.x86_64-linux;   
[
  bashInteractive
  curl
  coreutils
  (python3.withPackages (ps: with ps; [
                                        imageio
                                        scikitimage 
                                        opencv4
                                        numpy
                                      ]
                         )
  )
]
)' \
--command \
python3 \
script.py
```
Refs.:
- https://stackoverflow.com/questions/56183201/detect-and-visualize-differences-between-two-images-with-opencv-python
- https://github.com/NixOS/nixpkgs/issues/64363#issuecomment-508935677
- https://codereview.stackexchange.com/a/263497
- https://stackoverflow.com/a/72159410
- https://stackoverflow.com/a/55014800



## In nix shell

```bash
nix \
shell \
--ignore-environment \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/ebe6e807793e7c9cc59cf81225fdee1a03413811 \
nixpkgs#bashInteractive \
nixpkgs#okular \
nixpkgs#texlive.combined.scheme-small \
nixpkgs#pandoc \
--command \
bash \
-c \
'
echo hi > minimal.md

pandoc \
--from markdown \
--output minimal.pdf \
--pdf-engine pdflatex \
--verbose \
minimal.md
'

nix run nixpkgs#okular minimal.pdf 
nix run nixpkgs#firefox minimal.pdf 
```
Refs.:
- https://discourse.nixos.org/t/pandoc-and-latex-via-xelatex-unknown-option-error/9193



```bash
curl -sL https://raw.githubusercontent.com/thephpleague/commonmark/latest/tests/benchmark/sample.md \
> example.md

nix \
shell \
--ignore-environment \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/ebe6e807793e7c9cc59cf81225fdee1a03413811 \
nixpkgs#bashInteractive \
nixpkgs#texlive.combined.scheme-small \
nixpkgs#pandoc \
--command \
bash \
-c \
'
pandoc example.md -o example.pdf
'

nix run nixpkgs#okular example.pdf 
nix run nixpkgs#firefox example.pdf 
```
Refs.:
- https://discourse.nixos.org/t/what-are-the-best-practices-regarding-pandoc-when-one-simply-wants-a-conversion-to-pdf/11889/2


TODO:
```bash
curl https://raw.githubusercontent.com/jgm/pandoc/12de77958fc4bb97707f63cb9d9194f3b050a6f6/MANUAL.txt -o MANUAL.txt

pandoc MANUAL.txt --pdf-engine=xelatex -o example13.pdf
```


TODO: Broken!
```bash
cat << 'EOF' > fontspec-test.tex
\documentclass{minimal}
\begin{document}
Hello
\end{document}
EOF

nix \
shell \
--ignore-environment \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/ebe6e807793e7c9cc59cf81225fdee1a03413811 \
nixpkgs#bashInteractive \
nixpkgs#okular \
nixpkgs#texlive.combined.scheme-full \
nixpkgs#tetex \
--command \
bash \
-c \
'
xetex fontspec-test.tex
'
```
Refs.:
- 




## jupyter nbconvert


```bash
git clone https://github.com/jupyter/nbconvert-examples.git \
&& cd nbconvert-examples/latex_cell_style \
&& jupyter nbconvert --to pdf test.ipynb 
```

```bash
jupyter \
nbconvert \
--to latex \
--template use_cell_style.tplx \
--post pdf \
test.ipynb
```


```bash
jupyter \
nbconvert \
test.ipynb \
--to slides \
--reveal-prefix reveal.js \
--post serve
```
Refs.:
- https://nbconvert.readthedocs.io/en/latest/usage.html#serving-slides-with-an-https-server-post-serve



## reveal.js

```bash
git clone https://github.com/hakimel/reveal.js.git \
&& cd reveal.js \
&& git checkout 6b8c64ffa8fddd9ed4bcd92bcfd37b67ba410244
```



## jupyter nbconvert


```bash
git clone https://github.com/jupyter/nbconvert-examples.git \
&& cd nbconvert-examples \
&& git checkout 039724f4251cc8183f85534785fbee14809248ac

cat << 'EOF' > fix-jinja2-templete.patch
diff --git a/citations/citations.tplx b/citations/citations.tplx
index 2bb2f45..277157c 100644
--- a/citations/citations.tplx
+++ b/citations/citations.tplx
@@ -1,4 +1,4 @@
-((*- extends 'article.tplx' -*))
+((*- extends 'latex/base.tex.j2' -*))
 
 ((* block author *))
 \author{Fernando Perez and Brian E. Granger}
EOF

git apply fix-jinja2-templete.patch \
&& rm -v fix-jinja2-templete.patch

cd citations
```


```bash
jupyter \
nbconvert \
LifecycleTools.ipynb \
--to latex \
--template latex \
--template-file citations.tplx

pdflatex LifecycleTools.tex \
&& bibtex LifecycleTools.aux \
&& pdflatex LifecycleTools.tex \
&& pdflatex LifecycleTools.tex \
&& pdflatex LifecycleTools.tex
```
Refs.:
- https://discourse.jupyter.org/t/custom-latex-template-code-is-missing/8135
- https://github.com/jupyter/nbconvert-examples/issues/11#issuecomment-141898514
- https://tex.stackexchange.com/a/463408
- https://github.com/jupyter/nbconvert/issues/1528#issuecomment-789506113
- https://github.com/jupyter/nbconvert/issues/1451#issuecomment-709391371
- https://github.com/TwistedHardware/mltutorial/blob/master/notebooks/jupyter/BibTex/Compile%20Article.ipynb


```bash
okular LifecycleTools.pdf
```



```bash
pandoc \
LifecycleTools.ipynb \
--from=ipynb+citations \
--bibliography=ipython.bib \
--standalone \
--to=revealjs \
--output=xxx.html
```
Refs.:
- https://github.com/jgm/pandoc/issues/6408#issuecomment-635800092



```bash
git reset --hard
git clean -dfx
git status
```

```bash
JUPYTER_PATH

```
Refs.:
- https://github.com/jupyter/nbconvert/issues/1773#issuecomment-1283852572


TODO: really ASAP help in there
https://github.com/jupyter/nbconvert-examples/issues/11

https://github.com/jupyter/nbconvert-examples/blob/master/citations/LifecycleTools.pdf
Even the versioned pdf is missing the citations [?]


TODO: help in there
https://github.com/jupyter/nbconvert/issues/1465#issuecomment-729004735


TODO: how to update this doc?
https://nbviewer.org/github/ipython/nbconvert-examples/blob/master/citations/Tutorial.ipynb


TODO: https://stackoverflow.com/a/74030343
```bash
cat << 'EOF' > index.tex.j2
((=- Default to the notebook output style -=))
((*- if not cell_style is defined -*))
    ((* set cell_style = 'style_jupyter.tex.j2' *))
((*- endif -*))

((=- Inherit from the specified cell style. -=))
((* extends cell_style *))


%===============================================================================
% Latex Article
%===============================================================================

((*- block docclass -*))
\documentclass[11pt]{article}

((*- endblock docclass -*))

((*- block packages -*))
((( super() )))
\usepackage{droid}
\usepackage{polyglossia}
\setdefaultlanguage{english}
\setotherlanguage{russian}
\newfontfamily{\cyrillicfont}{DroidSerif}
\newfontfamily{\cyrillicfonttt}{DroidSansMono}
\AtBeginDocument{
\setmainfont{DroidSerif-Regular.ttf}
\setsansfont{DroidSans.ttf}
\setmonofont{DroidSansMono.ttf}
}

((*- endblock packages -*))
EOF
```





## pandoc citeproc



```bash
git clone https://github.com/jgm/pandoc-website.git \
&& cd pandoc-website \
&& git checkout 30b949e3ca6b719a0512271e3ca4bc5218b26eae
```

```bash
pandoc \
--standalone \
--bibliography biblio.bib \
--citeproc CITATIONS \
--to revealjs \
--output example24a.html
```
Refs.:
- https://github.com/jgm/pandoc/issues/8136

It worked. TODO: make nixosTests
```bash
firefox example24a.html
```


Broken:
```bash
pandoc \
--number-sections \
--variable "geometry=margin=1.2in" \
--variable mainfont="Palatino" \
--variable sansfont="Helvetica" \
--variable monofont="Menlo" \
--variable fontsize=12pt \
--variable version=2.0 MANUAL.txt \
--include-in-header fancyheaders.tex \
--pdf-engine=lualatex \
--table-of-contents \
--output example14.pdf
```

TODO: 
```bash
gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=clean.pdf -dBATCH dirty.pdf
```
Refs.:
- https://tex.stackexchange.com/a/481609




TODOs:
- https://github.com/jgm/citeproc/issues/57
- https://github.com/jgm/citeproc/issues/133#issuecomment-1533588728
- https://github.com/jupyter-book/jupyter-book/issues/274#issuecomment-540672801
- https://chrisholdgraf.com/blog/2019/2019-11-11-ipynb_pandoc/

