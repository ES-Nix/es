{
  description = "OCI image with static Nix, busybox and an unprivileged user, tested with NixOS test and docker";

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

        nonRootShadowSetup = { user, uid, group, gid }: with prev; [
          (writeTextDir "etc/shadow" ''
            ${user}:!:::::::
          '')
          (writeTextDir "etc/passwd" ''
            ${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}
          '')
          (writeTextDir "etc/group" ''
            ${group}:x:${toString gid}:
          '')
          (writeTextDir "etc/gshadow" ''
            ${group}:x::
          '')
        ];

        caBundle = prev.stdenv.mkDerivation {
          name = "ca-bundle";
          phases = [ "installPhase" "fixupPhase" ];
          installPhase = ''
            mkdir --parent $out/etc/ssl/certs
            cp ${prev.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-bundle.crt
          '';
        };

        tmpDirs = prev.stdenv.mkDerivation {
          name = "tmp";
          phases = [ "installPhase" "fixupPhase" ];
          installPhase = ''
            mkdir --parent $out/tmp
            mkdir --parent $out/home/nixuser/tmp
          '';
        };

        OCIImageNixUnprivileged = prev.dockerTools.buildImage {
          name = "nix-unprivileged";
          tag = "0.0.1";
          copyToRoot = [
            final.caBundle
            prev.nixStatic
            prev.busybox
            final.tmpDirs
          ]
          ++ (final.nonRootShadowSetup { user = "nixuser"; uid = 12345; group = "nixgroup"; gid = 6789; });

          config = {
            Cmd = [ "/bin/sh" ];
            Env = [
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              # A user is required by nix
              # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
              "USER=nixuser"
              "PATH=/bin"
            ];
            User = "nixuser:nixgroup";
          };
        };

        testOCIImageNixUnprivileged = prev.testers.runNixOSTest
          {
            name = "test-oci-image-nix-unprivileged";
            nodes.machine =
              { config, pkgs, lib, modulesPath, ... }:
              {
                config.virtualisation.docker.enable = true;
              };

            globalTimeout = 3 * 60;

            testScript = { nodes, ... }: ''
              start_all()

              machine.wait_for_unit("docker.service")

              machine.succeed("docker load <${final.OCIImageNixUnprivileged}")
              print(machine.succeed("docker images"))

              result = machine.succeed("docker run --rm nix-unprivileged:0.0.1 nix --version")
              expected = 'nix (Nix) ${prev.nixStatic.version}'
              assert expected in result, f"expected = {expected}, result = {result}"

              result = machine.succeed("docker run --rm nix-unprivileged:0.0.1 id -u")
              expected = '12345'
              assert expected in result, f"expected = {expected}, result = {result}"

              result = machine.succeed("docker run --rm nix-unprivileged:0.0.1 id -g")
              expected = '6789'
              assert expected in result, f"expected = {expected}, result = {result}"

              result = machine.succeed("docker run --rm nix-unprivileged:0.0.1 sh -c 'echo $USER'")
              expected = 'nixuser'
              assert expected in result, f"expected = {expected}, result = {result}"
            '';
          } // { meta.mainProgram = "${final.testOCIImageNixUnprivileged.name}"; };

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
            caBundle
            tmpDirs
            OCIImageNixUnprivileged
            testOCIImageNixUnprivileged
            ;
          default = pkgs.testOCIImageNixUnprivileged;
        };

        formatter = pkgs.nixpkgs-fmt;

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testOCIImageNixUnprivileged.driverInteractive}";
            meta.description = "Run the testOCIImageNixUnprivileged NixOS test in an interactive mode";
          };

          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests for this flake";
          };
        };

        checks = {
          inherit (pkgs)
            caBundle
            tmpDirs
            OCIImageNixUnprivileged
            testOCIImageNixUnprivileged
            ;
          default = pkgs.testOCIImageNixUnprivileged;
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
