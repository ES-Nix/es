

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
    pkgs = import nixpkgs { 
      system = "x86_64-linux";
      config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };      
      # config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [    "example-unfree-package" ];
    };
in
    pkgs.testers.runNixOSTest { name = "test-build-and-rebuild-hello-unfree";
                                nodes = { 
                                  machineA = { config, pkgs, nixpkgs, ... }: { 
                                    environment.systemPackages = with pkgs; [ hello-unfree nix ];
                                    environment.variables.NIXPKGS_ALLOW_UNFREE = "1";
                                    system.extraDependencies =  with pkgs; [ hello-unfree.inputDerivation  ];
                                    nix.extraOptions = ''
                                      experimental-features = nix-command flakes
                                    '';
                                    nix.settings = {
                                      pure-eval = false;
                                      flake-registry = "${flake-registry}/flake-registry.json";
                                    };
                                    nix.registry.nixpkgs.flake = nixpkgs;
                                    nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
                                    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "example-unfree-package" ];
                                  };
                                };
                                node.specialArgs = { inherit pkgs nixpkgs; };
                                testScript = { nodes, ... }: ''
                                    machineA.succeed("nix flake --version >&2")
                                    machineA.succeed("nix flake metadata nixpkgs >&2")
                                    machineA.succeed("echo $NIXPKGS_ALLOW_UNFREE >&2")
                                    machineA.succeed("nix show-config >&2")
                                    machineA.succeed("nix eval nixpkgs#config >&2")
                                    machineA.succeed("nix --option pure-eval false build --no-link --print-build-logs --print-out-paths nixpkgs#hello-unfree >&2")
                                    machineA.succeed("nix --option pure-eval false build --no-link --print-build-logs --print-out-paths --rebuild nixpkgs#hello-unfree >&2")
                                '';
                              }
EOF
)"
```

TODO:
```bash
[ "$(nix-shell -p hello which --run "which hello")" = "$(nix shell nixpkgs#hello nixpkgs#which -c which hello)" ]
```
Refs.:
- https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
- https://github.com/NixOS/nixpkgs/issues/62832#issuecomment-1406628331
- https://github.com/NixOS/nix/issues/3871
