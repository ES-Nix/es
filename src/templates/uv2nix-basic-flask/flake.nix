{
  description = "Application packaged using uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix/ad83f1ead0e78e57b188f35cb57298affb06fc5f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix/0497ccef038da091002be7c05263a7f27820974f";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs/7bff980f37fc24e09dbc986643719900c139bf12";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, pyproject-nix, uv2nix, pyproject-build-systems }:
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
        pkgs = nixpkgs.legacyPackages.${system};
        nixos-lib = import (nixpkgs + "/nixos/lib") { };

        python = pkgs.python311;
        workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
        overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
        pythonSet = (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope (
          nixpkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.wheel
            overlay
          ]
        );

        myapp = (pythonSet.mkVirtualEnv "myapp-env" workspace.deps.default)
          // { meta.mainProgram = "start"; };

        nonRootShadowSetup = { user, uid, group, gid }: with pkgs; [
          (
            writeTextDir "etc/shadow" ''
              ${user}:!:::::::
            ''
          )
          (
            writeTextDir "etc/passwd" ''
              ${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}
            ''
          )
          (
            writeTextDir "etc/group" ''
              ${group}:x:${toString gid}:
            ''
          )
          (
            writeTextDir "etc/gshadow" ''
              ${group}:x::
            ''
          )
        ];

        myappOCIImage = pkgs.dockerTools.buildLayeredImage {
          name = "myapp-oci-image";
          tag = "0.0.1";
          contents = [
            myapp
            pkgs.busybox
          ]
          ++ (nonRootShadowSetup { user = "app_user"; uid = 12345; group = "app_group"; gid = 6789; });

          config = {
            Cmd = [ "start" ];
          };
        };
      in
      {
        packages = {
          allTests = let name = "all-tests"; in pkgs.writeShellApplication
            {
              name = name;
              runtimeInputs = [ ];
              text = ''
                nix fmt . \
                && nix flake show --all-systems '.#' \
                && nix flake metadata '.#' \
                && nix build --no-link --print-build-logs --print-out-paths '.#' \
                && nix develop '.#' --command sh -c 'true' \
                && nix flake check --all-systems --verbose '.#' \
                && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#'
              '';
            } // { meta.mainProgram = name; };

          inherit myapp myappOCIImage;
          default = myapp;
        };

        formatter = pkgs.nixpkgs-fmt;

        apps = {
          default = {
            program = "${pkgs.lib.getExe myapp}";
            type = "app";
            meta.description = "Run the myapp application";
          };
        };

        checks = {
          test-nixos = nixos-lib.runTest {
            name = "myapp-as-oci-image";
            nodes.machine =
              { config, pkgs, lib, ... }:
              {
                config.virtualisation.docker.enable = true;
                config.virtualisation.podman.enable = true;
              };
            globalTimeout = 3 * 60;
            testScript = ''
              start_all()

              machine.succeed("docker load < ${myappOCIImage}")
              machine.succeed("podman load < ${myappOCIImage}")

              print(machine.succeed("docker images"))
              print(machine.succeed("podman images"))

              machine.succeed("docker run -d --name=container-app --publish=5000:5000 --rm=true myapp-oci-image:0.0.1")
              machine.wait_for_open_port(5000)
              print(machine.succeed("docker ps"))
              expected = 'Hello world!!'
              result = machine.wait_until_succeeds("curl http://localhost:5000")
              assert expected == result, f"expected = {expected}, result = {result}"

              machine.succeed("docker stop container-app")
              result = machine.wait_until_succeeds("! curl http://127.0.0.1:5000")
            '';
            hostPkgs = pkgs;
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.python311
            pkgs.uv
          ];

          env = {
            UV_PYTHON = pkgs.python311.interpreter;
            UV_PYTHON_DOWNLOADS = "never";
          };

          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true
            unset PYTHONPATH
          '';
        };
      }
    );
}
