# es


1)
```bash
command -v curl || (command -v apt && sudo apt-get update && sudo apt-get install -y curl)
command -v curl || (command -v apk && sudo apk add --no-cache -y curl)


NIX_RELEASE_VERSION=2.10.2 \
&& curl -L https://releases.nixos.org/nix/nix-"${NIX_RELEASE_VERSION}"/install | sh -s -- --no-daemon \
&& . "$HOME"/.nix-profile/etc/profile.d/nix.sh

export NIX_CONFIG='extra-experimental-features = nix-command flakes'
```




```bash
nix registry list
```

```bash
nix flake show templates
```


TODO: test all the templates!
```bash
nix flake show templates --json
```



```bash
mkdir -pv ~/sandbox/sandbox \
&& cd ~/sandbox/sandbox
```

```bash
nix flake init --template templates#full
```

```bash
nix flake show .#
```


### 

- nix flake init --template templates#full
- https://xeiaso.net/blog/nix-flakes-terraform
- https://juliu.is/tidying-your-home-with-nix/#ive-changed-my-mind-how-do-i-get-both-stable-and-unstable
- https://discourse.nixos.org/t/home-manager-flake-does-not-provide-attribute/24926
- https://discourse.nixos.org/t/fixing-error-attribute-currentsystem-missing-in-flake/22386/7




```bash
mkdir -pv ~/sandbox/sandbox \
&& cd ~/sandbox/sandbox
```


```bash
mkdir -pv ~/sandbox/sandbox \
&& cd ~/sandbox/sandbox
```

```bash
nix flake init --template github:ES-nix/es#startConfig
```

```bash
git init && git add .
```

nix --extra-experimental-features 'nix-command flakes' build -L --rebuild .#hello

checks.suportedSystem = self.packages.suportedSystem;


mkdir -pv hosts/minimal-example-nixos

