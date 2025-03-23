{
  description = " ";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/c1dfcf08411b08f6b8615f7d8971a2bfa81d5e8a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'    
  */
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

    in
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        foo-bar = prev.hello;
        latex-demo-document = final.stdenvNoCC.mkDerivation {
          name = "latex-demo-document";
          src = prev.writeTextDir "latex-demo-document.tex" ''
            \documentclass[a4paper]{article}

            \begin{document}
              {\huge Hello, World!}
            \end{document}
          '';
          buildInputs = [
            final.coreutils
            (final.texlive.combine {
              inherit (final.texlive) scheme-minimal latex-bin latexmk;
            })
          ];
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            export PATH="${final.lib.makeBinPath [
                final.coreutils
                (final.texlive.combine {
                  inherit (final.texlive) scheme-minimal latex-bin latexmk;
                })
              ]
            }";

            mkdir -pv .cache/texmf-var

            env \
              TEXMFHOME=.cache \
              TEXMFVAR=.cache/texmf-var \
              latexmk \
              -f \
              -interaction=nonstopmode \
              -outdir=/build \
              -pdf \
              -lualatex \
              $src/latex-demo-document.tex
          '';
          installPhase = ''
            mkdir -p $out
            # ls -alh /build
            cp -rv /build/{*.pdf,*.log,*.fls,*.fdb_latexmk,*.aux} $out/
          '';
          # dontUnpack = true;
          # dontPatchELF = true;
          # dontFixup = true;
        };
      };
    } //
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs {
            overlays = [ self.overlays.default ];
            system = suportedSystem;
            config.allowUnfree = true;
          };

          # TODO: double check it
          nixos-lib = import (nixpkgs + "/nixos/lib") { };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          packages.default = pkgsAllowUnfree.latex-demo-document;

          packages.scriptFirefox = pkgsAllowUnfree.writeShellApplication {
            name = "script-firefox";
            runtimeInputs = with pkgsAllowUnfree; [ bash firefox latex-demo-document ];
            text = ''
              firefox "${pkgsAllowUnfree.latex-demo-document}"/latex-demo-document.pdf
            '';
          };

          packages.scriptShowPrintScreenFirefox = pkgsAllowUnfree.writeShellApplication {
            name = "script-show-print-screen-firefox";
            runtimeInputs = with pkgsAllowUnfree; [ okular ];
            text = ''
              okular "${self.packages."${suportedSystem}".test-nixos}"/okular2.png
            '';
          };

          packages.test-nixos = nixos-lib.runTest {
            name = "ocr-from-pdf";
            nodes.machine = { config, pkgs, ... }:
              let user = config.users.users.alice;
              in {
                imports = [
                  "${pkgsAllowUnfree.path}/nixos/tests/common/x11.nix"
                  "${pkgsAllowUnfree.path}/nixos/tests/common/user-account.nix"
                ];
                services.xserver.enable = true;
                services.xserver.displayManager.startx.enable = true;
                # test-support.displayManager.auto.user = user.name;

                # services.xserver.displayManager.autoLogin.enable = true;
                # services.xserver.displayManager.autoLogin.user = user.name;
                # services.xserver.desktopManager.gnome.enable = true;
                # services.xserver.displayManager.sessionCommands = ''
                #    # okular --presentation ''${pkgsAllowUnfree.latex-demo-document}/latex-demo-document.pdf
                #    ${pkgs.vscodium}/bin/codium
                # '';

                environment.systemPackages = with pkgsAllowUnfree; [
                  firefox
                  okular
                ];
              };
            hostPkgs = pkgsAllowUnfree;
            enableOCR = true;
            # Disable linting for simpler debugging of the testScript
            skipLint = true;
            skipTypeCheck = true;

            testScript = ''
              start_all()

              machine.wait_for_unit('graphical.target')

              # machine.screenshot("firefox1")
              # machine.execute("firefox >&2 &")
              # machine.wait_for_text(r"(Mozilla Firefox|Directory listing for)")
              # machine.screenshot("firefox2")

              machine.execute("okular --presentation ${pkgsAllowUnfree.latex-demo-document}/latex-demo-document.pdf >&2 &")
              machine.screenshot("okular1")
              machine.wait_for_text("There are two ways of exiting")
              machine.send_key("esc")
              # Move the mouse out of the way
              machine.succeed("${pkgsAllowUnfree.xdotool}/bin/xdotool mousemove 0 0")
              machine.wait_for_text(r"(Hello, World!)")
              machine.screenshot("okular2")
            '';
          };

          apps = {
            default = {
              type = "app";
              program = "${self.packages."${suportedSystem}".scriptFirefox}/bin/script-firefox";
            };

            show-print = {
              type = "app";
              program = "${self.packages."${suportedSystem}".scriptShowPrintScreenFirefox}/bin/script-show-print-screen-firefox";
            };
          };

          checks = {
            test-nixos = self.packages."${suportedSystem}".test-nixos;
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [

            ];

            shellHook = ''
              export TMPDIR=/tmp

              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop .# --impure --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build --impure $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default
            '';
          };
        }
      )

    // {
      #
    };
}
