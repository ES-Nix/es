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
    --override-input nixpkgs 'github:NixOS/nixpkgs/afb2b21ba489196da32cd9f0072e0dce6588a20a' \
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

        OCIImageAlpineAmd64 = prev.dockerTools.pullImage {
          finalImageTag = "1.37.0-musl";
          finalImageName = "amd64/busybox";
          imageDigest = "sha256:e95352f7c5174c96ffc684150c9d08fc3ba26ac2f37c613c398fd369e15a0789";
          imageName = "docker.io/library/busybox";
          name = "docker.io/library/busybox";
          sha256 = "sha256-SI0VV3tw3pjqXR3azrW3vp8Cc2aS+MxZSHvxpy6IXW8=";
          os = "linux";
          arch = "amd64";
        };

        testDockerAndMultiKernels = prev.testers.runNixOSTest {
          name = "test-docker-and-multi-kernels";
          nodes.machine1 =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;
            };

          nodes.machine2 =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.boot.kernelPackages = pkgs.linuxPackages_latest;
            };

          nodes.machine3 =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.boot.kernelPackages = pkgs.linuxPackages_testing;
            };

          nodes.machine4 =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.virtualisation.docker.enable = true;
              config.boot.kernelPackages = pkgs.linuxKernel.packages.linux_hardened;
            };

          globalTimeout = 2 * 60;

          testScript = { nodes, ... }: ''
            start_all()

            machine1.wait_for_unit("default.target")
            machine1.succeed("docker load <${final.OCIImageAlpineAmd64}")
            with subtest("linux_6_6"):
                expected = '6.6.92'
                result_1 = machine1.succeed("uname -r")
                result_2 = machine1.succeed("""
                  docker run -it --rm --platform linux/amd64 amd64/busybox:1.37.0-musl sh -c 'uname -r'
                """)
                assert expected in result_1, f"expected = {expected}, result = {result_1}"
                assert expected in result_2, f"expected = {expected}, result = {result_2}"

            machine2.wait_for_unit("default.target")
            machine2.succeed("docker load <${final.OCIImageAlpineAmd64}")
            with subtest("linux_latest"):
                expected = '6.14.8'
                result_1 = machine2.succeed("uname -r")
                result_2 = machine2.succeed("""
                  docker run -it --rm --platform linux/amd64 amd64/busybox:1.37.0-musl sh -c 'uname -r'
                """)
                assert expected in result_1, f"expected = {expected}, result = {result_1}"
                assert expected in result_2, f"expected = {expected}, result = {result_2}"

            machine3.wait_for_unit("default.target")
            machine3.succeed("docker load <${final.OCIImageAlpineAmd64}")
            with subtest("linux_latest"):
                expected = '6.15.0-rc7'
                result_1 = machine3.succeed("uname -r")
                result_2 = machine3.succeed("""
                  docker run -it --rm --platform linux/amd64 amd64/busybox:1.37.0-musl sh -c 'uname -r'
                """)
                assert expected in result_1, f"expected = {expected}, result = {result_1}"
                assert expected in result_2, f"expected = {expected}, result = {result_2}"

            machine4.wait_for_unit("default.target")
            machine4.succeed("docker load <${final.OCIImageAlpineAmd64}")
            with subtest("linux_latest"):
                expected = '6.12.28-hardened1'
                result_1 = machine4.succeed("uname -r")
                result_2 = machine4.succeed("""
                  docker run -it --rm --platform linux/amd64 amd64/busybox:1.37.0-musl sh -c 'uname -r'
                """)
                assert expected in result_1, f"expected = {expected}, result = {result_1}"
                assert expected in result_2, f"expected = {expected}, result = {result_2}"
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
      {
        packages = {
          inherit (pkgs)
            testDockerAndMultiKernels
            ;
          default = pkgs.testDockerAndMultiKernels;
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testDockerAndMultiKernels
            ;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            testDockerAndMultiKernels
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
