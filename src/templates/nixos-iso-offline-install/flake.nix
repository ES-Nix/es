{
  description = "This is nix flake to make an NixOS self offiline install ISO in .qcow2";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c505ebf777526041d792a49d5f6dd4095ea391a' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/107d5ef05c0b1119749e381451389eded30fb0d5' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'    
  */
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        nixos-offline-install-iso-in-qcow2 = nixpkgs.lib.nixosSystem {
          system = prev.system;
          modules = [
            ./custom-self-install-iso.nix
          ];
          specialArgs = { inherit nixpkgs; };
        };

        iso-nixos-offline-install-in-qcow2 = final.nixos-offline-install-iso-in-qcow2.config.system.build.isoImage;

        run-nixos-offline-install-iso-in-qcow2 = prev.stdenv.mkDerivation rec {
          name = "run-nixos-offline-install-iso-in-qcow2";
          buildInputs = with prev; [ stdenv ];
          nativeBuildInputs = with prev; [ makeWrapper ];
          propagatedNativeBuildInputs = with prev; [
            bashInteractive
            # coreutils
            qemu
            final.iso-nixos-offline-install-in-qcow2
          ];

          src = builtins.path { path = ./.; inherit name; };
          phases = [ "installPhase" ];

          unpackPhase = ":";

          installPhase = ''
            mkdir -p $out/bin
            ls -al "${src}/"

            cp -r "${src}/${name}.sh" $out

            install \
            -m0755 \
            $out/${name}.sh \
            -D \
            $out/bin/${name}

            patchShebangs $out/bin/${name}

            substituteInPlace \
            $out/bin/${name} \
            --replace-fail 'VM_DISK_SIZE="''${DISK_SIZE:-12G}"' 'VM_DISK_SIZE="''${DISK_SIZE:-16G}"'

            substituteInPlace \
            $out/bin/${name} \
            --replace-fail 'VM_OVMF_FULL_PATH_TO_OVMF="''${OVMF_FULL_PATH_TO_OVMF:-OVMF.fd}"' 'VM_OVMF_FULL_PATH_TO_OVMF="''${OVMF_FULL_PATH_TO_OVMF:-${final.OVMF.fd}/FV/OVMF.fd}"'

            substituteInPlace \
            $out/bin/${name} \
            --replace-fail 'VM_ISO_FULL_PATH="''${ISO_FULL_PATH:-result/iso/*.iso}"' 'VM_ISO_FULL_PATH="''${ISO_FULL_PATH:-${final.iso-nixos-offline-install-in-qcow2}/iso/${final.iso-nixos-offline-install-in-qcow2.name}}"'


            wrapProgram $out/bin/${name} \
              --prefix PATH : "${prev.lib.makeBinPath propagatedNativeBuildInputs }"
          '';

          meta.mainProgram = name;
        };


        run-qemu-nixos = prev.stdenv.mkDerivation rec {
          name = "run-qemu-nixos";
          buildInputs = with prev; [ stdenv ];
          nativeBuildInputs = with prev; [ makeWrapper ];
          propagatedNativeBuildInputs = with prev; [
            bashInteractive
            # coreutils
            qemu
          ];

          src = builtins.path { path = ./.; inherit name; };
          phases = [ "installPhase" ];

          unpackPhase = ":";

          installPhase = ''
            mkdir -p $out/bin

            cp -r "${src}/${name}.sh" $out

            install \
            -m0755 \
            $out/${name}.sh \
            -D \
            $out/bin/${name}

            patchShebangs $out/bin/${name}

            wrapProgram $out/bin/${name} \
              --prefix PATH : "${prev.lib.makeBinPath propagatedNativeBuildInputs }"
          '';

          meta.mainProgram = name;
        };


      })
    ];
  } // (
    let
      # nix flake show --allow-import-from-derivation --impure --refresh .#
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
      rec {
        packages = { inherit (pkgs) iso-nixos-offline-install-in-qcow2; };
        packages.default = pkgs.iso-nixos-offline-install-in-qcow2;

        packages.run-nixos-offline-install-iso-in-qcow2 = pkgs.run-nixos-offline-install-iso-in-qcow2;

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.run-nixos-offline-install-iso-in-qcow2}";
        };

        apps.run = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.run-qemu-nixos}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          iso-nixos-offline-install-in-qcow2 = pkgs.iso-nixos-offline-install-in-qcow2;

          #  testISOIntall = pkgs.testers.runNixOSTest {
          #    name = "test-";
          #    nodes.machineWithDocker =
          #      { config, pkgs, lib, ... }:
          #      {
          #        config.environment.systemPackages = with pkgs; [
          #          foo-bar
          #          run-qemu-nixos
          #        ];
          #      };
          #
          #    enableOCR = true;
          #
          #    testScript = ''
          #      start_all()
          #
          #      machineWithDocker.succeed("hello")
          #      # machineWithDocker.succeed("run-nixos-offline-install-iso-in-qcow2")
          #    '';
          #  };
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
            # myapp
            # poetry
            # python3Custom
          ];

          shellHook = ''
          '';
        };

      }
    )
  );
  #  // {
  #    nixosConfigurations.vm = pkgs.nixos-vm;
  #  };
}
