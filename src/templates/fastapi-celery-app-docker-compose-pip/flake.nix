{
  description = "A QEMU virtual machine with XFCE, copy/paste, Docker, poetry2nix, FastAPI, mmh3";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/3c92540611f42d3fb2d0d084a6c694cd6544b609'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/f554d27c1544d9c56e5f1f8e2b8aff399803674e'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/11415c7ae8539d6292f2928317ee7a8410b28bb9' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/f554d27c1544d9c56e5f1f8e2b8aff399803674e'
      
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/b9a98080beff0903a5e5fe431f42cde1e3e50d6b'  

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/25e53aa156d47bad5082ff7618f5feb1f5e02d01' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b' \
    --override-input poetry2nix 'github:nix-community/poetry2nix/b9a98080beff0903a5e5fe431f42cde1e3e50d6b'

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

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

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

              # && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
            '';
          } // { meta.mainProgram = name; };

      })
    ];
  } // (
    let
      # nix flake show --allow-import-from-derivation --impure --refresh .#
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

    in
    flake-utils.lib.eachSystem suportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            # myapp
            # myappOCIImage
            # testMyappOCIImage
            # myvm
            # automaticVm
            ;
          default = pkgs.fooBar;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests for this flake";
          };
          # default = {
          #   type = "app";
          #   program = "${pkgs.lib.getExe pkgs.myapp}";
          #   meta.description = "";
          # };
        };

        formatter = pkgs.nixpkgs-fmt;

        # checks = {
        #   inherit (pkgs)
        #     allTests
        #     myapp
        #     ;
        #   default = pkgs.testMyappOCIImage;
        # };

        devShells.default = with pkgs; mkShell {
          packages = [
            # poetry
            # uv
            python311
            python311Packages.pip

            fooBar
            # myapp
          ];

          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true             
          '';
        };
      }
    )
  );
}
