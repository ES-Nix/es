{
  description = "Bare OCI image with only a statically linked Nix, tested with NixOS test and docker";

  /*
    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c97c47f2bac4fa59e2cbdeba289686ae615f8ed4' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {

        OCIImageNixStaticBare = prev.dockerTools.buildImage {
          name = "nix-static-bare";
          tag = "0.0.1";
          copyToRoot = [
            prev.nixStatic
          ];
          config = {
            Cmd = [ "/bin/nix" "--version" ];
            Env = [
              "PATH=/bin"
              # A user is required by nix
              # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
              "USER=root"
            ];
          };
        };

        testOCIImageNixStaticBare = prev.testers.runNixOSTest
          {
            name = "test-oci-image-nix-static-bare";
            nodes.machine =
              { config, pkgs, lib, modulesPath, ... }:
              {
                config.virtualisation.docker.enable = true;
              };

            globalTimeout = 3 * 60;

            testScript = { nodes, ... }: ''
              start_all()

              machine.wait_for_unit("docker.service")

              machine.succeed("docker load <${final.OCIImageNixStaticBare}")
              print(machine.succeed("docker images"))

              result = machine.succeed("docker run --rm nix-static-bare:0.0.1")
              expected = 'nix (Nix) ${prev.nixStatic.version}'
              assert expected in result, f"expected = {expected}, result = {result}"
            '';
          } // { meta.mainProgram = "${final.testOCIImageNixStaticBare.name}"; };

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems --impure '.#' \
              && nix flake metadata --impure '.#' \
              && nix build --impure --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --impure --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop --impure '.#' --command sh -c 'true' \
              && nix flake check --all-systems --impure --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

      })
    ];
  } // (
    let
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
            nixStatic
            OCIImageNixStaticBare
            testOCIImageNixStaticBare
            ;
          default = pkgs.testOCIImageNixStaticBare;
        };

        formatter = pkgs.nixpkgs-fmt;

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testOCIImageNixStaticBare.driverInteractive}";
            meta.description = "Run the testOCIImageNixStaticBare NixOS test in an interactive mode";
          };

          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests for this flake";
          };
        };

        checks = {
          inherit (pkgs)
            nixStatic
            OCIImageNixStaticBare
            testOCIImageNixStaticBare
            ;
          default = pkgs.testOCIImageNixStaticBare;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
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
