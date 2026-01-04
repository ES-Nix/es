{
  description = "This is an 'nix flake' :)";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
    --override-input flake-utils github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
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

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/9a094440e02a699be5c57453a092a8baf569bdad' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/25e53aa156d47bad5082ff7618f5feb1f5e02d01' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/c97c47f2bac4fa59e2cbdeba289686ae615f8ed4' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    # nixpkgs-darwin-stable.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    # nixpkgs-linux-unstable.url = "nixpkgs/nixos-unstable";
    # nixos-generators = {
    #   url = "github:nix-community/nixos-generators";
    #   inputs.nixpkgs.follows = "nixpkgs-linux-stable";
    # };
  };

  outputs =
    allAttrs@{ self
    , nixpkgs
    , flake-utils
    ,
    }:
    let
      name = "es";

      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
      ];

    in
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
      let
        pkgsAllowUnfree = import nixpkgs { system = suportedSystem; config = { allowUnfree = true; }; };

        # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
        pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
          (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
      in
      {

        devShells.default = pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            coreutils
            curl
            gh
            gnumake
            nixpkgs-fmt # find . -type f -iname '*.nix' -exec nixpkgs-fmt {} \;
            patchelf
            poetry
            python3
            tmate

            pleaseKeepMyInputs
          ];

          shellHook = ''
            echo -e 'Education' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat
            echo -e '       and' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat
            echo -e 'Science' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat

            test -d .profiles || mkdir -v .profiles

            test -L .profiles/dev \
            || nix develop .# --profile .profiles/dev --command true

            test -L .profiles/dev-shell-default \
            || nix build $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default
          '';
        };

        checks."${suportedSystem}" = self.packages."${suportedSystem}".hello;

        packages.default = self.packages."${suportedSystem}".hello;

        packages.hello = pkgsAllowUnfree.hello;
        packages.hello-unfree = pkgsAllowUnfree.hello-unfree;
        packages.python3WithPandas = pkgsAllowUnfree.python3Packages.pandas;

        packages.installStartConfigTemplate = (import ./src/pkgs/install-start-config-template { pkgs = pkgsAllowUnfree; });
        packages.installNixFlakesHomeManagerZshTemplate = (import ./src/pkgs/install-nix-flakes-home-manager-zsh-template { pkgs = pkgsAllowUnfree; });

        packages.installQEMUVirtualMachineDockerTemplate = (import ./src/pkgs/install-qemu-virtual-machine-docker-template { pkgs = pkgsAllowUnfree; });
        packages.installQEMUVirtualMachineXfceCopyPasteTemplate = (import ./src/pkgs/install-qemu-virtual-machine-xfce-copy-paste-template { pkgs = pkgsAllowUnfree; });
        packages.installQEMUVirtualMachineXfceCopyPasteMinimalTemplate = (import ./src/pkgs/install-qemu-virtual-machine-xfce-copy-paste-minimal-template { pkgs = pkgsAllowUnfree; });

        packages.sendToCacheInstallStartConfigTemplate = (import ./src/pkgs/send-to-cache-install-start-config-template { pkgs = pkgsAllowUnfree; });

        formatter = pkgsAllowUnfree.nixpkgs-fmt;

        apps = {
          # allTests = {
          #   type = "app";
          #   program = "${pkgs.lib.getExe pkgs.allTests}";
          #   meta.description = "Run all tests";
          # };

          installStartConfigTemplate = {
            type = "app";
            program = "${pkgsAllowUnfree.lib.getExe self.packages."${suportedSystem}".installStartConfigTemplate}";
            meta.description = "Run the ";
          };

          installTemplateNixFlakesHomeManagerZsh = {
            type = "app";
            program = "${pkgsAllowUnfree.lib.getExe self.packages."${suportedSystem}".installNixFlakesHomeManagerZshTemplate}";
            meta.description = "Run the ";
          };

          installQEMUVirtualMachineDockerTemplate = {
            type = "app";
            program = "${pkgsAllowUnfree.lib.getExe self.packages."${suportedSystem}".installQEMUVirtualMachineDockerTemplate}";
            meta.description = "Run the ";
          };

          installQEMUVirtualMachineXfceCopyPasteTemplate = {
            type = "app";
            program = "${pkgsAllowUnfree.lib.getExe self.packages."${suportedSystem}".installQEMUVirtualMachineXfceCopyPasteTemplate}";
            meta.description = "Run the ";
          };

          installQEMUVirtualMachineXfceCopyPasteMinimalTemplate = {
            type = "app";
            program = "${pkgsAllowUnfree.lib.getExe self.packages."${suportedSystem}".installQEMUVirtualMachineXfceCopyPasteMinimalTemplate}";
            meta.description = "Run the ";
          };

          # installQEMUVirtualMachineXfceCopyPasteMinimalTemplate =
          #   let
          #     p = self.packages."${suportedSystem}".installQEMUVirtualMachineXfceCopyPasteMinimalTemplate;
          #   in
          #   flake-utils.lib.mkApp {
          #     name = p.name;
          #     drv = p;
          #   };

        };
      }
      )
    //
    {
      templates = import ./src/templates;
    }
  ;
}

