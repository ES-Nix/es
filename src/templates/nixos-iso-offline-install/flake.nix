{
  description = "This is nix flake to make an NixOS self offline install ISO in .qcow2";

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
    --override-input nixpkgs 'github:NixOS/nixpkgs/11415c7ae8539d6292f2928317ee7a8410b28bb9' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/50ab793786d9de88ee30ec4e4c24fb4236fc2674' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'          
  */
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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

        ISONixOSSelfOfflineInstallISOInQcow2 = final.nixos-offline-install-iso-in-qcow2.config.system.build.isoImage;

        run-nixos-offline-install-iso-in-qcow2 = prev.stdenv.mkDerivation rec {
          name = "run-nixos-offline-install-iso-in-qcow2";
          buildInputs = with prev; [ stdenv ];
          nativeBuildInputs = with prev; [ makeWrapper ];
          propagatedNativeBuildInputs = with prev; [
            bashInteractive
            # coreutils
            qemu
            final.ISONixOSSelfOfflineInstallISOInQcow2
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
            --replace-fail 'VM_ISO_FULL_PATH="''${ISO_FULL_PATH:-result/iso/*.iso}"' 'VM_ISO_FULL_PATH="''${ISO_FULL_PATH:-${final.ISONixOSSelfOfflineInstallISOInQcow2}/iso/${final.ISONixOSSelfOfflineInstallISOInQcow2.name}}"'


            wrapProgram $out/bin/${name} \
              --prefix PATH : "${prev.lib.makeBinPath propagatedNativeBuildInputs }"
          '';

          meta.mainProgram = name;
        };


        runQEMUNixOS = prev.stdenv.mkDerivation rec {
          name = "runQEMUNixOS";
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

        testISOIntall = final.testers.runNixOSTest {
          name = "test-";
          nodes.machine =
            { config, pkgs, lib, ... }:
            {
              config.virtualisation.memorySize = 1024 * 12;
              config.virtualisation.diskSize = 1024 * 18;
              config.boot.extraModprobeConfig = "options kvm_intel nested=1";
              config.boot.kernelModules = [
                "kvm-intel"
              ];

              config.environment.systemPackages = with pkgs; [
                foo-bar
                run-nixos-offline-install-iso-in-qcow2
              ];
            };
          globalTimeout = 2 * 60;
          testScript = ''
            start_all()
          
            machine.succeed("hello")
            machine.succeed("run-nixos-offline-install-iso-in-qcow2")
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
            ISONixOSSelfOfflineInstallISOInQcow2
            run-nixos-offline-install-iso-in-qcow2
            testISOIntall
            ;
          # default = pkgs.testISOIntall;
          default = pkgs.ISONixOSSelfOfflineInstallISOInQcow2;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.run-nixos-offline-install-iso-in-qcow2}";
          meta.description = "Run NixOS self offline install ISO in .qcow2 in QEMU";
        };

        apps.run = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.runQEMUNixOS}";
          meta.description = "Run a NixOS in QEMU";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            ISONixOSSelfOfflineInstallISOInQcow2
            run-nixos-offline-install-iso-in-qcow2
            runQEMUNixOS
            # testISOIntall
            ;
          default = pkgs.runQEMUNixOS;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            foo-bar
            # ISONixOSSelfOfflineInstallISOInQcow2
            # run-nixos-offline-install-iso-in-qcow2
            # runQEMUNixOS
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
  #  // {
  #    nixosConfigurations.vm = pkgs.nixos-vm;
  #  };
}
