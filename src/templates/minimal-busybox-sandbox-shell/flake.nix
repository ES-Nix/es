{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a7' \
    --override-input flake-utils 'github:numtide/flake-utils/c1dfcf08411b08f6b8615f7d8971a2bfa81d5e8a'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        minimalBusyboxSandboxShell = prev.busybox.override {
          enableStatic = true;
          enableMinimal = true;
          extraConfig = ''
            CONFIG_FEATURE_FANCY_ECHO y
            CONFIG_FEATURE_SH_MATH y
            CONFIG_FEATURE_SH_MATH_64 y
            CONFIG_FEATURE_TEST_64 y

            CONFIG_ASH y
            CONFIG_ASH_OPTIMIZE_FOR_SIZE y

            CONFIG_ASH_ALIAS y
            CONFIG_ASH_BASH_COMPAT y
            CONFIG_ASH_CMDCMD y
            CONFIG_ASH_ECHO y
            CONFIG_ASH_GETOPTS y
            CONFIG_ASH_INTERNAL_GLOB y
            CONFIG_ASH_JOB_CONTROL y
            CONFIG_ASH_PRINTF y
            CONFIG_ASH_TEST y
          '';
        };

        OCIImageMinimalBusyboxSandboxShell = prev.dockerTools.buildLayeredImage {
          name = "minimal-busybox-sandbox-shell";
          tag = "0.0.1";
          contents = with prev; [
            # fakeNss
            # final.minimalBusyboxSandboxShell
            busybox-sandbox-shell
          ];
          config.Cmd = [ "sh" ];
        };

        testDockerAndMultiKernels = prev.testers.runNixOSTest {
          name = "test-docker-and-busybox-sandbox-shell";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.environment.systemPackages = with pkgs; [
                minimalBusyboxSandboxShell
                file
              ];
            };

          globalTimeout = 1 * 60;

          testScript = { nodes, ... }: ''
            start_all()

            machine.wait_for_unit("default.target")
            machine.succeed("docker load <${final.OCIImageMinimalBusyboxSandboxShell}")
            print(machine.succeed("docker images"))
            result = machine.succeed("docker run -it minimal-busybox-sandbox-shell:0.0.1 sh -c 'echo *'")
            expected = 'bin default.script dev etc nix proc sys'
            assert expected in result, f"expected = {expected}, result = {result}"
          '';
        };

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
      rec {
        packages = {
          inherit (pkgs)
            testDockerAndMultiKernels
            minimalBusyboxSandboxShell
            ;

          default = pkgs.testDockerAndMultiKernels;
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
             minimalBusyboxSandboxShell
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
          ];
        };

      }
    )
  );
}
