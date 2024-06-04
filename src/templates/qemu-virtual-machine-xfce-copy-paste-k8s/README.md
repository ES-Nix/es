


```bash
mkdir -v k8s \
&& cd $_ \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#QEMUVirtualMachineXfceCopyPasteK8s
(direnv allow &> /dev/null ) || true

nix profile install nixpkgs#git

git init && git add .

rm -fv nixos.qcow2; 
nix \
run \
--impure \
--verbose \
'.#'
```
Refs.:
- 


22.05
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/380be19fbd2d9079f677978361792cb25e8a3635 \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
````

22.11
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
````

23.05
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/70bdadeb94ffc8806c0570eb5c2695ad29f0e421 \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
````

23.11
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/a5e4bbcb4780c63c79c87d29ea409abf097de3f7 \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
```

24.05
805a384895c696f802a9bf5bf4720f37385df547
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8 \
--override-input flake-utils github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a
```

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


### 


```nix
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
    nixPath = [ "nixpkgs=${pkgs.path}" ];
  };
  environment.etc."channels/nixpkgs".source = "${pkgs.path}";
```



TODO:
```nix
   environment.etc."containers/registries.conf" = {
     mode = "0644";
     text = ''
       [registries.search]
       registries = ['docker.io', 'localhost', 'us-docker.pkg.dev', 'gcr.io']
     '';
   };
   # nix eval --impure --json \
   # '.#nixosConfigurations.vm.config.services.kubernetes.kubelet.seedDockerImages'
   services.kubernetes.kubelet.seedDockerImages = (with pkgs; [
     cachedOCIImage1
     cachedOCIImage2
     cachedOCIImage3
     cachedOCIImage4
     cachedOCIImage5
   ]);
```
