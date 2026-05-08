{
  description = "A minimal toybox sandbox shell and OCI image tested with NixOS test and docker";

  /*
    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c97c47f2bac4fa59e2cbdeba289686ae615f8ed4' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        minimalToybox = prev.toybox.overrideAttrs
          (oldAttrs:
            {
              hardeningDisable = [ "fortify" ];
              buildPhase = "make clean && make sh";
              installPhase = "rm -frv $out && mkdir -pv $out/bin && cp -v sh $out/bin";
            }
          );

        OCIImageToybox = prev.dockerTools.buildLayeredImage {
          name = "toybox";
          tag = "0.0.1";
          contents = with prev; [
            toybox
          ];
          config.Cmd = [ "/bin/sh" ];
        };

        testOCIImageToybox = prev.testers.runNixOSTest {
          name = "test-docker-and-toybox";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.environment.systemPackages = with pkgs; [
                minimalToybox
                file
              ];
            };

          globalTimeout = 1 * 60;

          testScript = { nodes, ... }: ''
            start_all()

            machine.wait_for_unit("docker.service")

            machine.succeed("docker load <${final.OCIImageToybox}")
            print(machine.succeed("docker images"))
            # result = machine.succeed("docker run -it --rm toybox:0.0.1 sh -c 'echo *'")
            # expected = 'aaaaaaaaaaaaa'
            # assert expected in result, f"expected = {expected}, result = {result}"
          '';
        };

        OCIImageMinimalToybox = prev.dockerTools.buildLayeredImage {
          name = "minimal-toybox";
          tag = "0.0.1";
          contents = with prev; [
            # fakeNss
            final.minimalToybox
            # toybox-sandbox-shell
          ];
          config.Cmd = [ "sh" ];
        };

        testOCIImageMinimalToybox = prev.testers.runNixOSTest
          {
            name = "test-docker-and-minimal-toybox";
            nodes.machine =
              { config, pkgs, lib, modulesPath, ... }:
              {
                config.virtualisation.docker.enable = true;
                config.environment.systemPackages = with pkgs; [
                  minimalToybox
                  file
                ];
              };

            globalTimeout = 1 * 60;

            testScript = { nodes, ... }: ''
              start_all()

              machine.wait_for_unit("docker.service")

              machine.succeed("docker load <${final.OCIImageMinimalToybox}")
              print(machine.succeed("docker images"))
              result = " ".join(sorted(machine.succeed("docker run -it --rm minimal-toybox:0.0.1 sh -c 'echo *'").split()))
              expected = " ".join(sorted('nix dev proc etc sys bin'.split()))
              assert result == expected, f"expected = {expected}, result = {result}"
            '';
          } // { meta.mainProgram = "${final.testOCIImageMinimalToybox.name}"; };

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
            # toybox
            fooBar
            minimalToybox
            OCIImageToybox
            OCIImageMinimalToybox
            testOCIImageToybox
            testOCIImageMinimalToybox
            ;
          default = pkgs.testOCIImageMinimalToybox;
        };

        formatter = pkgs.nixpkgs-fmt;

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testOCIImageMinimalToybox.driverInteractive}";
            meta.description = "Run the testOCIImageMinimalToybox NixOS test in an interactive mode";
          };

          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests for this flake";
          };
        };

        checks = {
          inherit (pkgs)
            toybox
            fooBar
            minimalToybox
            OCIImageToybox
            OCIImageMinimalToybox
            testOCIImageToybox
            testOCIImageMinimalToybox
            ;
          default = pkgs.testOCIImageMinimalToybox;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
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
