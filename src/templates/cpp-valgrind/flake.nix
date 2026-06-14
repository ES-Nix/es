{
  description = "A C++ hello world compiled with Nix, with OCI image and NixOS test.";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5882' \
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

        myapp = prev.stdenv.mkDerivation {
          pname = "hello-cpp";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ prev.clang ];
          buildPhase = ''
            clang++ -g src/main.cpp -o hello-cpp
          '';
          installPhase = ''
            install -Dm755 hello-cpp $out/bin/hello-cpp
          '';
          meta.mainProgram = "hello-cpp";
        };

        myHttpServer = prev.stdenv.mkDerivation {
          pname = "http-server-cpp";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ prev.clang ];
          buildInputs = [ prev.httplib ];
          buildPhase = ''
            clang++ -std=c++17 src/http_server.cpp -o http-server-cpp \
              -I${prev.httplib}/include \
              -lpthread
          '';
          installPhase = ''
            install -Dm755 http-server-cpp $out/bin/http-server-cpp
          '';
          meta.mainProgram = "http-server-cpp";
        };

        httpServerOCIImage =
          let
            nonRootShadowSetupHttp = { user, uid, group, gid }: with prev; [
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
          in
          prev.dockerTools.buildLayeredImage {
            name = "http-server-cpp-oci-image";
            tag = "0.0.1";
            contents = [
              final.myHttpServer
              final.busybox
            ]
            ++ (nonRootShadowSetupHttp { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; });

            config = {
              Cmd = [ "${final.lib.getExe final.myHttpServer}" ];
              ExposedPorts = { "8080/tcp" = { }; };
            };
          };

        testHttpServerOCIImage = prev.testers.runNixOSTest {
          name = "http-server-cpp-as-oci-image";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.virtualisation.docker.enable = true;

              config.systemd.services.docker-load-http-server-cpp = {
                description = "Load http-server-cpp OCI image into Docker";
                wantedBy = [ "multi-user.target" ];
                after = [ "docker.service" ];
                path = with pkgs; [ docker ];
                script = ''
                  docker load <"${final.httpServerOCIImage}"
                '';
                serviceConfig.Type = "oneshot";
              };
            };
          globalTimeout = 2 * 60;
          testScript = ''
            start_all()

            machine.wait_until_succeeds("docker images | grep http-server-cpp")

            machine.succeed("docker run -d --name=http-server --publish=8080:8080 http-server-cpp-oci-image:0.0.1")
            machine.wait_for_open_port(8080)

            expected = "Hello world!"
            result = machine.succeed("curl -s http://localhost:8080/")
            assert expected in result, f"expected={expected!r}, result={result!r}"

            machine.succeed("docker stop http-server")
          '';
        };

        testHttpServerOCIImageDriverInteractive = final.testHttpServerOCIImage.driverInteractive;

        myappOCIImage =
          let
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
          in
          prev.dockerTools.buildLayeredImage {
            name = "hello-cpp-oci-image";
            tag = "0.0.1";
            contents = [
              final.myapp
              final.busybox
            ]
            ++ (nonRootShadowSetup { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; });

            config = {
              Cmd = [ "${final.lib.getExe final.myapp}" ];
            };
          };

        testMyappOCIImage = prev.testers.runNixOSTest {
          name = "hello-cpp-as-oci-image";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.virtualisation.docker.enable = true;

              config.systemd.services.docker-load-hello-cpp = {
                description = "Load hello-cpp OCI image into Docker";
                wantedBy = [ "multi-user.target" ];
                after = [ "docker.service" ];
                path = with pkgs; [ docker ];
                script = ''
                  docker load <"${final.myappOCIImage}"
                '';
                serviceConfig.Type = "oneshot";
              };
            };
          globalTimeout = 2 * 60;
          testScript = ''
            start_all()

            machine.wait_until_succeeds("docker images | grep hello-cpp")

            result = machine.succeed("docker run --rm hello-cpp-oci-image:0.0.1")
            expected = "Hello world!"
            assert expected in result, f"expected = {expected!r}, result = {result!r}"
          '';
        };

        testMyappOCIImageDriverInteractive = final.testMyappOCIImage.driverInteractive;

        testValgrind = prev.runCommand "test-valgrind-hello-cpp"
          {
            nativeBuildInputs = [ prev.valgrind ];
          }
          ''
            valgrind \
              --error-exitcode=1 \
              --leak-check=full \
              --track-origins=yes \
              --show-leak-kinds=all \
              ${final.lib.getExe final.myapp} 2>&1
            touch $out
          '';

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = [ ];
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
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
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
            myapp
            myappOCIImage
            testMyappOCIImage
            testMyappOCIImageDriverInteractive
            myHttpServer
            httpServerOCIImage
            testHttpServerOCIImage
            testHttpServerOCIImageDriverInteractive
            testValgrind
            ;
          default = pkgs.myapp;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.myapp}";
            meta.description = "Run the hello-cpp binary.";
          };
          myHttpServer = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.myHttpServer}";
            meta.description = "Run the C++ HTTP server on port 8080.";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests: formatting, build, develop, check.";
          };
          testMyappOCIImageDriverInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testMyappOCIImageDriverInteractive}";
            meta.description = "Run the NixOS test interactively.";
          };
          testHttpServerOCIImageDriverInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testHttpServerOCIImageDriverInteractive}";
            meta.description = "Run the HTTP server NixOS test interactively.";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            myapp
            myappOCIImage
            testMyappOCIImage
            testMyappOCIImageDriverInteractive
            myHttpServer
            httpServerOCIImage
            testHttpServerOCIImage
            testHttpServerOCIImageDriverInteractive
            testValgrind
            ;
          default = pkgs.testMyappOCIImage;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            clang
            cmake
            ninja
            gdb
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
