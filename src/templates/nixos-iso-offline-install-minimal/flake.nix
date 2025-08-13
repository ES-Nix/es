{
  description = "This is nix flake to make an NixOS self offline install ISO in .qcow2";

  /*
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

        nixOSSelfOfflineInstallISOInQcow2 = nixpkgs.lib.nixosSystem {
          system = prev.system;
          modules = [
            ./custom-self-install-iso.nix
          ];
          specialArgs = { inherit nixpkgs; };
        };

        ISONixOSSelfOfflineInstallISOInQcow2 = final.nixOSSelfOfflineInstallISOInQcow2.config.system.build.isoImage;

        runISONixOSSelfOfflineInstallISOInQcow2 = prev.stdenv.mkDerivation rec {
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

        testISOInstall = final.testers.runNixOSTest {
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
                runISONixOSSelfOfflineInstallISOInQcow2
              ];
            };

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
            runISONixOSSelfOfflineInstallISOInQcow2
            runQEMUNixOS
            testISOInstall
            ;
          # default = pkgs.testISOIntall;
          default = pkgs.ISONixOSSelfOfflineInstallISOInQcow2;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.runISONixOSSelfOfflineInstallISOInQcow2}";
        };

        apps.run = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.runQEMUNixOS}";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            ISONixOSSelfOfflineInstallISOInQcow2
            runISONixOSSelfOfflineInstallISOInQcow2
            runQEMUNixOS
            # testISOIntall
            ;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            foo-bar
            ISONixOSSelfOfflineInstallISOInQcow2
            runISONixOSSelfOfflineInstallISOInQcow2
            runQEMUNixOS
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
