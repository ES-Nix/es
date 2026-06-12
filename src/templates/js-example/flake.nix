{
  description = "JavaScript examples as Nix derivations.";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/nixos-25.11' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {

        # 1. npm install uglify-es
        uglifyEsExample = prev.buildNpmPackage {
          name = "uglify-es-example";
          src = ./examples/uglify-es;
          npmDepsHash = "sha256-PlQbbYQdN7SH3pPVras84sNLHIXMS0zR4K08Hz5OgGw=";
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -r node_modules $out/lib/
            cat > $out/bin/uglifyjs << EOF
            #!/bin/sh
            exec ${prev.nodejs}/bin/node $out/lib/node_modules/uglify-es/bin/uglifyjs "\$@"
            EOF
            chmod +x $out/bin/uglifyjs
          '';
          meta.mainProgram = "uglifyjs";
        };

        # 2. bun create vue (interactive scaffolding — wrapped as runnable script)
        bunCreateVueScript = prev.writeShellApplication {
          name = "bun-create-vue";
          runtimeInputs = [ prev.bun ];
          text = ''
            echo "Run one of the following (interactive, requires network):"
            echo "  bun create vue@latest"
            echo "  bun create vue@latest -- --template vue"
            echo "  bun create vue@latest -- --template vue-ts"
            bun create vue@latest "$@"
          '';
        };

        # 3. bunx create-vite --template vue (JavaScript)
        vueJs = prev.buildNpmPackage {
          name = "vue-js";
          src = ./examples/vue-js;
          npmDepsHash = "sha256-f4zQb9bUWWgLNotv9RXnGy2+/D3drAq03+0Kc4rNAiE=";
          buildPhase = ''
            npm run build
          '';
          installPhase = ''
            mkdir -p $out/lib
            mv dist $out/lib/
          '';
        };

        # 4. bunx create-vite --template vue-ts (TypeScript)
        vueTs = prev.buildNpmPackage {
          name = "vue-ts";
          src = ./examples/vue-ts;
          npmDepsHash = "sha256-ov9jZrGmftWAlcMsqD749b5Z2sYp88qOoBFcDmHRW+U=";
          buildPhase = ''
            npm run build
          '';
          installPhase = ''
            mkdir -p $out/lib
            mv dist $out/lib/
          '';
        };

        # 5a. yarn add bcrypt — installs bcrypt with native bindings
        bcryptExample = prev.buildNpmPackage {
          name = "bcrypt-example";
          src = ./examples/bcrypt;
          npmDepsHash = "sha256-q0LQBgi70FVN56qslxWgwPY/qgr34KqlC3SwcXTavJk=";
          nativeBuildInputs = with prev; [ python3 pkg-config nodePackages.node-gyp ];
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -r node_modules $out/lib/
            cp test.js $out/lib/
            cat > $out/bin/bcrypt-test << EOF
            #!/bin/sh
            exec ${prev.nodejs}/bin/node $out/lib/test.js "\$@"
            EOF
            chmod +x $out/bin/bcrypt-test
          '';
        };

        # 5b. NixOS test: runs bcrypt-test and asserts output contains "Hashed password:"
        testBcrypt = prev.testers.runNixOSTest {
          name = "bcrypt-test";
          nodes.machine = { pkgs, ... }: {
            environment.systemPackages = [ final.bcryptExample ];
          };
          testScript = ''
            start_all()
            result = machine.succeed("bcrypt-test")
            assert "Hashed password:" in result, f"expected 'Hashed password:' in output, got: {result}"
          '';
        };

        # 6. yarn add sqlite3 argon2 sharp node-sass (native modules)
        nativeModules = prev.buildNpmPackage {
          name = "native-modules-example";
          src = ./examples/native-modules;
          npmDepsHash = "sha256-ciCAI91zpEODnaNLXadU8Ci+pZ5EwZ897dl9ir34MDY=";
          nativeBuildInputs = with prev; [
            (python3.withPackages (ps: [ ps.setuptools ]))
            pkg-config
            nodePackages.node-gyp
            vips
            libsass
          ];
          buildInputs = with prev; [
            sqlite
            libsass
            vips
          ];
          env.CXXFLAGS = "-std=c++17";
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib
            cp -r node_modules $out/lib/
          '';
        };

        # 7. yarn add ffi-napi
        # ffi-napi 4.x native binding is incompatible with Node.js 22 (node_api_basic_finalize rename).
        # --ignore-scripts skips gyp compilation; demonstrates the npm/Nix integration pattern.
        ffiNapi = prev.buildNpmPackage {
          name = "ffi-napi-example";
          src = ./examples/ffi-napi;
          npmDepsHash = "sha256-CibMEJZtBY3SJQrOBxtozrMwiPopnW67uiPElDMimfA=";
          npmFlags = "--ignore-scripts";
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib
            cp -r node_modules $out/lib/
          '';
        };

        # 8. nest new project-name — NestJS HTTP application
        nestjsApp = prev.buildNpmPackage {
          name = "nestjs-example";
          src = ./examples/nestjs;
          npmDepsHash = "sha256-tNUty3oQAtlTdoX/mgiqK9/j6rRbRmLEG/ctHPUmWZE=";
          buildPhase = ''
            ./node_modules/.bin/nest build
          '';
          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -r dist $out/lib/
            cp -r node_modules $out/lib/
            cat > $out/bin/nestjs-example << EOF
            #!/bin/sh
            exec ${prev.nodejs}/bin/node $out/lib/dist/main "\$@"
            EOF
            chmod +x $out/bin/nestjs-example
          '';
          meta.mainProgram = "nestjs-example";
        };

        # 9a. yarn-nix: node_modules via mkYarnPackage
        yarnNixNodeModules = prev.mkYarnPackage {
          name = "yarn-nix-node-modules";
          src = ./examples/yarn-nix;
        };

        # 9b. yarn-nix: TypeScript frontend built with tsc
        yarnNixFrontend = prev.stdenv.mkDerivation {
          name = "yarn-nix-frontend";
          src = ./examples/yarn-nix;
          nativeBuildInputs = with prev; [ final.yarnNixNodeModules nodejs nodePackages.typescript ];
          buildPhase = ''
            ln -s ${final.yarnNixNodeModules}/libexec/yarn-nix-example/node_modules node_modules
            tsc --project tsconfig.json
          '';
          installPhase = ''
            mkdir -p $out/lib $out/bin
            mv dist $out/lib/
            cat > $out/bin/wui << EOF
            #!/bin/sh
            exec ${prev.nodejs}/bin/node $out/lib/dist/wui.js "\$@"
            EOF
            chmod +x $out/bin/wui
          '';
          meta.mainProgram = "wui";
        };

        # 10. Containerfile/Docker: Python 3.12 OCI image via dockerTools
        python312OciImage = prev.dockerTools.buildLayeredImage {
          name = "python312";
          tag = "latest";
          contents = [ prev.python312 prev.busybox ];
          config = {
            Entrypoint = [ "${prev.python312}/bin/python3" ];
            Cmd = [ "-c" "import this" ];
          };
        };

        # 11. docker run nix-flakes bash — wrapped as runnable shell application
        # docker must be available in PATH at runtime
        nixFlakesDockerShell = prev.writeShellApplication {
          name = "nix-flakes-docker-shell";
          runtimeInputs = [ ];
          text = ''
            docker \
              run \
              --env=PATH=/root/.nix-profile/bin:/usr/bin:/bin \
              --privileged=true \
              --device=/dev/fuse \
              --env="DISPLAY=''${DISPLAY:-:0.0}" \
              --interactive=true \
              --network=host \
              --mount=type=tmpfs,destination=/var/lib/containers \
              --tty=true \
              --rm=true \
              --user=0 \
              --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
              --volume=/etc/localtime:/etc/localtime:ro \
              --volume=/dev:/dev \
              docker.nix-community.org/nixpkgs/nix-flakes \
              bash \
              -c \
              "''${*:-id}"
          '';
        };

        allTests =
          let name = "all-tests"; in
          final.writeShellApplication
            {
              name = name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#' \
                && nix flake check --verbose '.#'
              '';
            } // { meta.mainProgram = name; };

      })
    ];
    templates = {
      default = { path = ./examples/uglify-es; description = "Default: uglify-es example"; };
      uglify-es = { path = ./examples/uglify-es; description = "npm install uglify-es"; };
      bun-create-vue = { path = ./examples/bun-create-vue; description = "bun create vue (interactive scaffold)"; };
      vue-js = { path = ./examples/vue-js; description = "Vite + Vue.js (JavaScript)"; };
      vue-ts = { path = ./examples/vue-ts; description = "Vite + Vue.js (TypeScript)"; };
      bcrypt = { path = ./examples/bcrypt; description = "bcrypt native binding + NixOS test"; };
      native-modules = { path = ./examples/native-modules; description = "sqlite3 argon2 sharp node-sass native modules"; };
      ffi-napi = { path = ./examples/ffi-napi; description = "ffi-napi native binding (--ignore-scripts for Node 22)"; };
      nestjs = { path = ./examples/nestjs; description = "NestJS HTTP application"; };
      yarn-nix = { path = ./examples/yarn-nix; description = "TypeScript + Lodash via mkYarnPackage"; };
      python312-oci-image = { path = ./examples/python312-oci-image; description = "Python 3.12 OCI image via dockerTools"; };
      nix-flakes-docker = { path = ./examples/nix-flakes-docker; description = "Run nix-flakes Docker container"; };
    };

  } // (
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
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
            uglifyEsExample
            bunCreateVueScript
            vueJs
            vueTs
            bcryptExample
            testBcrypt
            nativeModules
            ffiNapi
            nestjsApp
            python312OciImage
            nixFlakesDockerShell
            ;
          default = pkgs.uglifyEsExample;
        } // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) yarnNixNodeModules yarnNixFrontend;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          bunCreateVueScript = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.bunCreateVueScript}";
            meta.description = "Interactive: bun create vue scaffold";
          };
          nestjsApp = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.nestjsApp}";
            meta.description = "Run the NestJS HTTP server";
          };
          nixFlakesDockerShell = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.nixFlakesDockerShell}";
            meta.description = "Run docker.nix-community.org/nixpkgs/nix-flakes bash shell";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.uglifyEsExample}";
            meta.description = "Run uglifyjs";
          };
        } // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          wui = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.yarnNixFrontend}";
            meta.description = "Run the yarn-nix TypeScript example";
          };
        };

        checks = {
          inherit (pkgs)
            uglifyEsExample
            vueJs
            vueTs
            bcryptExample
            testBcrypt
            nestjsApp
            python312OciImage
            ;
          default = pkgs.testBcrypt;
        } // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) yarnNixFrontend;
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells.default = with pkgs; mkShell {
          packages = [
            nodejs
            nodePackages.yarn
            bun
            nodePackages.typescript
          ];
        };
      }
    )
  );
}
