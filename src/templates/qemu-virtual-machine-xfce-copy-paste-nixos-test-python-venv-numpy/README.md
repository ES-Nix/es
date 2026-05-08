

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#testNixOSBareDriverInteractive
```


```bash
nix run '.#allTests'
```


### 

```bash
python3 --version \
&& python3 -m venv .venv \
&& which python3 \
&& which .venv/bin/python \
&& .venv/bin/python -m pip install numpy==2.4.4 \
&& .venv/bin/python -c 'import numpy as np'

python3 -c 'import numpy as np; print(np.show_runtime()), np.equal((-39+22j), np.dot([2+3j, 2+4j], [5j, 6j]))'
```

```bash
bash -c '
python3 -m venv .venv \
&& source .venv/bin/activate \
&& pip install numpy==2.4.4 \
&& python -c "import numpy as np"
'
```
