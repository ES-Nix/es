{
  description = "Flutter web hello world — buildFlutterApplication (web) → nginx OCI image → NixOS test";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {

        flutterWebAssets = prev.flutter.buildFlutterApplication {
          pname = "flutter-web-hello";
          version = "1.0.0";
          src = ./.;
          targetFlutterPlatform = "web";
          autoPubspecLock = ./pubspec.lock;
        };

        flutterWebOCIImage =
          let
            nonRootShadowSetup = { user, uid, group, gid }: with prev; [
              (writeTextDir "etc/shadow" "${user}:!:::::::\n")
              (writeTextDir "etc/passwd" "${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}\n")
              (writeTextDir "etc/group" "${group}:x:${toString gid}:\n")
              (writeTextDir "etc/gshadow" "${group}:x::\n")
            ];
            nginxConf = prev.writeText "nginx.conf" ''
              pid /tmp/nginx.pid;
              error_log stderr;
              events { worker_connections 1024; }
              http {
                client_body_temp_path /tmp;
                fastcgi_temp_path /tmp;
                proxy_temp_path /tmp;
                include ${prev.nginx}/conf/mime.types;
                server {
                  listen 80;
                  root ${final.flutterWebAssets};
                  index index.html;
                  location / {
                    try_files $uri $uri/ /index.html;
                  }
                }
              }
            '';
            nginxConfDir = prev.runCommand "nginx-conf-dir" { } ''
              mkdir -p $out
              cp ${nginxConf} $out/nginx.conf
            '';
          in
          prev.dockerTools.buildLayeredImage {
            name = "flutter-web-hello";
            tag = "1.0.0";
            contents = [
              prev.nginx
              prev.busybox
              final.flutterWebAssets
              nginxConfDir
            ] ++ (nonRootShadowSetup { user = "nobody"; uid = 65534; group = "nobody"; gid = 65534; });
            config = {
              Cmd = [ "nginx" "-c" "${nginxConfDir}/nginx.conf" "-g" "daemon off;" ];
              ExposedPorts = { "80/tcp" = { }; };
            };
          };

        testFlutterWebHello = prev.testers.runNixOSTest {
          name = "flutter-web-hello";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.services.nginx = {
                enable = true;
                virtualHosts."localhost" = {
                  root = "${final.flutterWebAssets}";
                  locations."/".tryFiles = "$uri $uri/ /index.html";
                };
              };
            };
          globalTimeout = 5 * 60;
          testScript = ''
            start_all()
            machine.wait_for_unit("nginx.service")
            machine.wait_for_open_port(80)
            result = machine.succeed("curl http://localhost:80")
            assert "Flutter Demo" in result, f"Expected 'Flutter Demo' in response, got: {result[:200]}"
          '';
        };

        serveFlutterWeb = prev.writeShellApplication {
          name = "serve-flutter-web";
          runtimeInputs = with prev; [ nginx ];
          text = ''
            nginxConf="${prev.writeText "nginx-local.conf" ''
              pid /tmp/nginx-local.pid;
              error_log stderr;
              events { worker_connections 1024; }
              http {
                client_body_temp_path /tmp;
                include ${prev.nginx}/conf/mime.types;
                server {
                  listen 8080;
                  root ${final.flutterWebAssets};
                  index index.html;
                  location / { try_files $uri $uri/ /index.html; }
                }
              }
            ''}"
            echo "Serving Flutter web app at http://localhost:8080"
            nginx -c "$nginxConf" -g "daemon off;"
          '';
        };

        allTests =
          let name = "all-tests";
          in final.writeShellApplication
            {
              name = name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show --all-systems '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#' \
                && nix develop '.#' --command sh -c 'true' \
                && nix flake check --verbose '.#'
              '';
            } // { meta.mainProgram = name; };

      })
    ];
  } // (
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            flutterWebAssets
            flutterWebOCIImage
            testFlutterWebHello
            serveFlutterWeb
            allTests
            ;
          default = pkgs.flutterWebAssets;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.serveFlutterWeb}";
            meta.description = "Serve Flutter web app locally on port 8080";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          testInteractive = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testFlutterWebHello.driverInteractive}";
            meta.description = "Run NixOS test in interactive mode";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            flutterWebAssets
            flutterWebOCIImage
            testFlutterWebHello
            ;
          default = pkgs.testFlutterWebHello;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            flutter
            dart
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
