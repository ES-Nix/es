

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash
nix flake show '.#' \
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
    #
    flake-registry = (builtins.fetchGit {
        url = "https://github.com/NixOS/flake-registry.git";
        ref = "master";
        rev = "02fe640c9e117dd9d6a34efc7bcb8bd09c08111d";
      }
    ); 
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/107d5ef05c0b1119749e381451389eded30fb0d5"); 
    pkgs = import nixpkgs { system = "x86_64-linux"; };
in
    pkgs.testers.runNixOSTest { name = "test-nix-flakes-command-line";
                                nodes = { 
                                  machineA = { config, pkgs, ... }: { 
                                    environment.systemPackages = with pkgs; [ hello nix ];
                                    system.extraDependencies =  with pkgs; [ hello.inputDerivation  ];
                                    nix.extraOptions = "experimental-features = nix-command flakes";
                                    nix.registry.nixpkgs.flake = nixpkgs;
                                    nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
                                    nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
                                  };
                                };
                                testScript = { nodes, ... }: ''
                                    machineA.succeed("nix --version")
                                    machineA.succeed("nix flake --version")
                                    machineA.succeed("nix profile list")
                                    machineA.succeed("nix registry list >&2")
                                    machineA.succeed("nix flake metadata nixpkgs")

                                    machineA.succeed("nix shell nixpkgs#hello --command hello")
                                    machineA.succeed("nix run nixpkgs#hello")
                                    machineA.succeed("nix build --no-link --print-build-logs --print-out-paths nixpkgs#hello >&2")
                                    machineA.succeed("nix build --no-link --print-build-logs --print-out-paths --rebuild nixpkgs#hello >&2")
                                '';
                              }
EOF
)"
```
