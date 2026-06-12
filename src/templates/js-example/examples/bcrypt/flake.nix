{
  description = "Example: yarn add bcrypt (native binding) + NixOS test";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        bcryptExample = pkgs.buildNpmPackage {
          name = "bcrypt-example";
          src = ./.;
          npmDepsHash = "sha256-q0LQBgi70FVN56qslxWgwPY/qgr34KqlC3SwcXTavJk=";
          nativeBuildInputs = with pkgs; [ python3 pkg-config nodePackages.node-gyp ];
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -r node_modules $out/lib/
            cp test.js $out/lib/
            cat > $out/bin/bcrypt-test << EOF
            #!/bin/sh
            exec ${pkgs.nodejs}/bin/node $out/lib/test.js "\$@"
            EOF
            chmod +x $out/bin/bcrypt-test
          '';
          meta.mainProgram = "bcrypt-test";
        };
        testBcrypt = pkgs.testers.runNixOSTest {
          name = "bcrypt-test";
          nodes.machine = { ... }: {
            environment.systemPackages = [ bcryptExample ];
          };
          testScript = ''
            start_all()
            result = machine.succeed("bcrypt-test")
            assert "Hashed password:" in result, f"expected 'Hashed password:' in output, got: {result}"
          '';
        };
        allTests = pkgs.writeShellApplication {
          name = "all-tests";
          text = ''
            nix fmt . \
            && nix flake show '.#' \
            && nix flake metadata '.#' \
            && nix build --no-link --print-build-logs --print-out-paths '.#' \
            && nix flake check --verbose '.#'
          '';
        } // { meta.mainProgram = "all-tests"; };
      in
      {
        packages = {
          default = bcryptExample;
          inherit testBcrypt allTests;
        };
        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe bcryptExample}";
          };
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe allTests}";
            meta.description = "Run all tests";
          };
        };
        checks = {
          inherit bcryptExample testBcrypt;
        };
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nodejs pkgs.nodePackages.yarn ];
        };
      }
    );
}
