{
  description = "OCI image with static Nix, uutils-coreutils, busybox-sandbox-shell, CA bundle, /etc/passwd, /etc/group and tmp, tested with NixOS test and docker";

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

        caBundleEtcPasswdEtcGroup =
          let
            nixbldUsers = builtins.concatStringsSep "\n" (
              builtins.genList
                (i:
                  let n = toString (i + 1); uid = toString (30000 + i + 1); in
                  "nixbld${n}:x:${uid}:30000:Nix build user ${n}:/var/empty:/noshell"
                ) 32
            );
            nixbldGroupMembers = builtins.concatStringsSep "," (
              builtins.genList (i: "nixbld${toString (i + 1)}") 32
            );
          in
          prev.stdenv.mkDerivation {
            name = "ca-bundle-etc-passwd-etc-group";
            phases = [ "installPhase" "fixupPhase" ];
            installPhase = ''
              mkdir --parent $out/etc/ssl/certs
              cp ${prev.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-bundle.crt

              mkdir --parent $out/home/nixuser/bin

              cat > $out/etc/passwd << 'EOF'
              root:x:0:0::/root:/bin/sh
              nixuser:x:12345:6789::/home/nixuser:/bin/sh
              ${nixbldUsers}
              EOF

              cat > $out/etc/group << 'EOF'
              root:x:0:
              nixgroup:x:6789:
              nixbld:x:30000:${nixbldGroupMembers}
              EOF

              mkdir --parent $out/home/nixuser/.config/nix
              echo 'experimental-features = nix-command flakes' > $out/home/nixuser/.config/nix/nix.conf

              mkdir --parent $out/root/.config/nix
              echo 'experimental-features = nix-command flakes' > $out/root/.config/nix/nix.conf
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

        OCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell = prev.dockerTools.buildImage {
          name = "nix-static-uutils-coreutils-busybox-sandbox-shell-ca-bundle-etc-passwd-etc-group-tmp";
          tag = "0.0.1";
          copyToRoot = [
            final.caBundleEtcPasswdEtcGroup
            prev.nixStatic
            # busybox must come before uutils-coreutils-noprefix so that uutils
            # binaries (e.g. /bin/ls) overwrite busybox's — last writer wins
            prev.pkgsStatic.busybox
            prev.uutils-coreutils-noprefix
            final.tmpDirs
          ];
          config = {
            Cmd = [ "/bin/sh" ];
            Env = [
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              # A user is required by nix
              # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
              "USER=nixuser"
              "PATH=/bin:/home/nixuser/bin"
              "TMPDIR=/home/nixuser/tmp"
            ];
          };
        };

        testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell = prev.testers.runNixOSTest
          {
            name = "test-oci-image-nix-static-uutils-coreutils-busybox-sandbox-shell";
            nodes.machine =
              { config, pkgs, lib, modulesPath, ... }:
              {
                config.virtualisation.docker.enable = true;
                config.virtualisation.diskSize = 4096;
                config.virtualisation.memorySize = 2048;
              };

            globalTimeout = 3 * 60;

            testScript = { nodes, ... }: ''
              start_all()

              machine.wait_for_unit("docker.service")

              machine.succeed("docker load <${final.OCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell}")
              print(machine.succeed("docker images"))

              image = "nix-static-uutils-coreutils-busybox-sandbox-shell-ca-bundle-etc-passwd-etc-group-tmp:0.0.1"

              result = machine.succeed(f"docker run --rm {image} sh -c 'nix --version'")
              expected = 'nix (Nix) ${prev.nixStatic.version}'
              assert expected in result, f"expected = {expected}, result = {result}"

              result = machine.succeed(f"docker run --rm {image} sh -c 'ls --version'")
              expected = 'uutils'
              assert expected in result, f"expected = {expected}, result = {result}"

              result = machine.succeed(f"docker run --rm {image} sh -c 'cat /etc/passwd'")
              for expected in ('nixuser:x:12345:6789:', 'nixbld1:x:30001:30000:', 'nixbld32:x:30032:30000:'):
                  assert expected in result, f"expected = {expected}, result = {result}"

              result = machine.succeed(f"docker run --rm {image} sh -c 'cat /etc/group'")
              for expected in ('nixgroup:x:6789:', 'nixbld:x:30000:nixbld1,'):
                  assert expected in result, f"expected = {expected}, result = {result}"

              result = machine.succeed(f"docker run --rm {image} sh -c 'echo $USER'")
              expected = 'nixuser'
              assert expected in result, f"expected = {expected}, result = {result}"
            '';
          } // { meta.mainProgram = "${final.testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell.name}"; };

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
            caBundleEtcPasswdEtcGroup
            tmpDirs
            OCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell
            testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell
            ;
          default = pkgs.testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell;
        };

        formatter = pkgs.nixpkgs-fmt;

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell.driverInteractive}";
            meta.description = "Run the testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell NixOS test in an interactive mode";
          };

          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests for this flake";
          };
        };

        checks = {
          inherit (pkgs)
            caBundleEtcPasswdEtcGroup
            tmpDirs
            OCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell
            testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell
            ;
          default = pkgs.testOCIImageNixStaticUutilsCoreutilsBusyboxSandboxShell;
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
