{
  description = "A flake for testing nix-serve in a NixOS virtual machine using QEMU. It includes a test that starts a NixOS VM with nix-serve enabled and checks if it serves the expected cache info. It also provides an interactive driver for manual testing and a shell with the necessary tools to run the tests.";

  /*
    # 25.11
    # Broken
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c97c47f2bac4fa59e2cbdeba289686ae615f8ed4' \
    --override-input flake-registry 'github:NixOS/flake-registry/02fe640c9e117dd9d6a34efc7bcb8bd09c08111d' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-registry 'github:NixOS/flake-registry/02fe640c9e117dd9d6a34efc7bcb8bd09c08111d' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    flake-registry.url = "github:NixOS/flake-registry";
    flake-registry.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, flake-registry }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        flake-registry = flake-registry;

        OCIImageAlpine320Amd64 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3";
          imageDigest = "sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-jGOIwPKVsjIbmLCS3w0AiAuex3YSey43n/+CtTeG+Ds=";
          os = "linux";
          arch = "amd64";
        };

        testNixOSNixServe = final.testers.runNixOSTest {
          name = "test-nix-serve";
          nodes = {
            # pkgsCross.aarch64-multiplatform.pkgsStatic.nix
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = (with pkgs; [ hello pkgsStatic.nix ]);
              system.extraDependencies = with pkgs; [ hello.inputDerivation ];

              virtualisation.docker.enable = true;

              # journalctl --unit docker-custom-bootstrap.service -b -f
              systemd.services.docker-custom-bootstrap = {
                description = "Docker Custom Bootstrap";
                wantedBy = [ "multi-user.target" ];
                after = [ "docker.service" ];
                path = with pkgs; [ docker ];
                script = ''
                  echo "Loading OCI Image in docker..."
                  docker load <"${final.OCIImageAlpine320Amd64}"
                '';
                serviceConfig = {
                  Type = "oneshot";
                };
              };

              nix.extraOptions = "experimental-features = nix-command flakes";
              nix.registry.nixpkgs.flake = nixpkgs;
              nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
              /*
                  To test it:
                  curl http://localhost:5000/nix-cache-info
                  nix store info --store http://localhost:5000
              */
              services.nix-serve.enable = true;
            };
          };
          testScript = { nodes, ... }: ''
            # machineABCZ.wait_for_unit("nix-serve.target")
            machineABCZ.wait_for_open_port(5000)

            result = machineABCZ.succeed("curl http://localhost:5000/nix-cache-info")
            expected1 = 'StoreDir: /nix/store'
            expected2 = 'WantMassQuery: 1'
            expected3 = 'Priority: 30'

            assert expected1 in result, f"expected {expected1}= , result = {result}"
            assert expected2 in result, f"expected {expected2}= , result = {result}"
            assert expected3 in result, f"expected {expected3}= , result = {result}"

            result = machineABCZ.succeed("nix store info --store http://localhost:5000 2>&1")
            expected = 'Store URL: http://localhost:5000'
            assert expected in result, f"expected = {expected}, result = {result}"

            machineABCZ.succeed("systemctl is-active docker.socket")
            machineABCZ.succeed("docker images 1>&2")
            machineABCZ.wait_until_succeeds("docker images | grep alpine 1>&2")
            # machineABCZ.succeed("docker run -it --rm alpine:3.20.3 uname -a")
            expected = PRETTY_NAME="Alpine Linux v3.20"
            result = machineABCZ.succeed("""
              docker \
              run \
              --interactive=true \
              --name=container-alpine \
              --privileged=true \
              --tty=true \
              --rm=true \
              alpine:3.20.3 \
              sh -c "cat /etc/os-release"
            """)
            assert expected in result, f"expected = {expected}, result = {result}"

            machineABCZ.succeed("nix flake --version")
            machineABCZ.succeed("""
              cp -v $(which nix) . \
              && stat ./nix \
              && ./nix --version

              cp -v "${flake-registry}/flake-registry.json" .
            """)

            result = machineABCZ.succeed("./nix store info --store http://localhost:5000 2>&1")
            expected = 'Store URL: http://localhost:5000'
            assert expected in result, f"expected = {expected}, result = {result}"

            expected = PRETTY_NAME="Alpine Linux v3.20"
            result = machineABCZ.succeed("""
              docker \
              run \
              --interactive=true \
              --name=container-alpine \
              --network=host \
              --privileged=true \
              --tty=true \
              --rm=true \
              --volume="$(pwd)":/home/abcuser/code:ro \
              alpine:3.20.3 \
              sh \
              -c \
              '
              cat /etc/os-release
              addgroup abcgroup \
              && adduser abcuser --home /home/abcuser --disabled-password --gecos "" --shell /bin/sh
              su -l abcuser -c sh -c \
              "
              id
              ./code/nix \
              --extra-experimental-features nix-command \
              --extra-experimental-features flakes \
               store \
               info \
               --store http://localhost:5000

              ./code/nix \
              --extra-experimental-features nix-command \
              --extra-experimental-features flakes \
              build \
              --offline \
              --no-use-registries \
              --store http://localhost:5000 \
              /nix/store/2bcv91i8fahqghn8dmyr791iaycbsjdd-hello-2.12.2

              # ./code/nix \
              # --extra-experimental-features nix-command \
              # --extra-experimental-features flakes \
              # run \
              # --offline \
              # --no-use-registries \
              # --store http://localhost:5000 \
              # nixpkgs
              # github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852#hello.out
              "
              '
            """)
            assert expected in result, f"expected = {expected}, result = {result}"
          '';
        };

        testNixOSNixServeDriverInteractive = final.testNixOSNixServe.driverInteractive;

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'
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
          # config.allowUnfreePredicate = (_: true);
          # config.android_sdk.accept_license = true;
          config.allowUnfree = true;
          # config.cudaSupport = true;          
        };
      in
      {
        packages = {
          inherit (pkgs)
            fooBar
            testNixOSNixServe
            testNixOSNixServeDriverInteractive;
          default = pkgs.testNixOSNixServe;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSNixServeDriverInteractive}";
            meta.description = "Run the interactive test";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSNixServe
            testNixOSNixServeDriverInteractive
            OCIImageAlpine320Amd64
            ;
          default = pkgs.testNixOSNixServe;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            testNixOSNixServe
            testNixOSNixServeDriverInteractive
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
