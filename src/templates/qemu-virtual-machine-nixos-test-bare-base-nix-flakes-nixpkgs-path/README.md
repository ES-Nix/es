

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash
nix fmt . \ 
&& nix flake show '.#' \
&& nix flake metadata '.#' \
&& nix build --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop '.#' --command sh -c 'true' \
&& nix flake check --verbose '.#'
```


```bash
nix \
build \
--no-link \
--print-build-logs \
--expr \
"$(cat <<- 'EOF'
let
  flake-registry = (builtins.fetchGit {
    url = "https://github.com/NixOS/flake-registry.git";
      ref = "master";
      rev = "02fe640c9e117dd9d6a34efc7bcb8bd09c08111d";
    }
  ); 
  nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0")
  // { hostPlatform = { config = "x86_64-unknown-linux-gnu"; qemuArch = "aarch64"; }; };

  pkgs = import nixpkgs { system = "x86_64-linux"; };
in
    pkgs.testers.runNixOSTest { name = "test-nix-flakes-command-line";
                                nodes = { 
                                  machineA = { config, pkgs, ... }: { 
                                    environment.systemPackages = with pkgs; [ nix ];
                                    nix.extraOptions = "experimental-features = nix-command flakes";
                                    nix.registry.nixpkgs.flake = nixpkgs;
                                    nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
                                    nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
                                    # boot.readOnlyNixStore = false;
                                  };
                                };
                                testScript = { nodes, ... }: ''
                                    machineA.succeed("nix --version")
                                    machineA.succeed("nix flake --version")
                                    machineA.succeed("nix profile list")
                                    machineA.succeed("nix registry list >&2")
                                    machineA.succeed("nix flake metadata nixpkgs")
                                    machineA.succeed("nix eval nixpkgs#hostPlatform.qemuArch >&2")
                                    
                                    machineA.succeed("nix repl --file '<nixpkgs>' <<<'1 + 2'")
                                    machineA.succeed("nix eval --impure --expr '<nixpkgs>' <<<'1 + 2'")
                                    machineA.succeed("nix-instantiate --eval --expr '<nixpkgs>' >&2")

                                    machineA.succeed("nix eval nixpkgs#path >&2")
                                    machineA.succeed("echo \"$NIX_PATH\" >&2")
                                '';
                              }
EOF
)"
```


TODO
```nix
# https://github.com/NixOS/nix/issues/2259#issuecomment-1144323965
nix-instantiate --eval --expr '<nixpkgs>'
nix-instantiate --eval --attr 'pkgs.path' '<nixpkgs>'
nix-instantiate --eval --expr '(builtins.getFlake "nixpkgs").shortRev'
nix-instantiate --eval --expr '(builtins.getFlake "nixpkgs").rev'
nix-instantiate --eval --expr '(builtins.getFlake "nixpkgs").outPath'
nix-instantiate --eval --expr '(builtins.getFlake "nixpkgs").sourceInfo.outPath'

nix-instantiate --eval --expr '( import (builtins.getFlake "nixpkgs") {} ).lib.version'
```


TODO:
```bash
building Nix...
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels/nixos' does not exist, ignoring
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
error: file 'nixpkgs/nixos' was not found in the Nix search path (add it using $NIX_PATH or -I)
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels/nixos' does not exist, ignoring
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
error: file 'nixpkgs' was not found in the Nix search path (add it using $NIX_PATH or -I)
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels/nixos' does not exist, ignoring
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
error: file 'nixpkgs/nixos/modules/installer/tools/nix-fallback-paths.nix' was not found in the Nix search path (add it using $NIX_PATH or -I)
/tmp/nixos-rebuild.pClwTX/nix
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels/nixos' does not exist, ignoring
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
error: file 'nixpkgs' was not found in the Nix search path (add it using $NIX_PATH or -I)
building the system configuration...
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels/nixos' does not exist, ignoring
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
error: file 'nixpkgs/nixos' was not found in the Nix search path (add it using $NIX_PATH or -I)
```