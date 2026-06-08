{
  description = "A Nix flake for building the Legrand Orange Book LaTeX template";

  /*
    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
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
      overlays.default = final: prev: {
        inherit self final prev;

        legrandSrc = prev.runCommand "legrand-orange-book-src"
          {
            nativeBuildInputs = [ prev.unzip ];
            src = prev.fetchurl {
              name = "legrand-orange-book.zip";
              url = "https://www.latextemplates.com/actions/action_download_template?template=legrand-orange-book";
              hash = "sha256-TAVJGlcTnE7A8Rzt98lDBBG4Bh1fDk95Zi/LxsYYSf0=";
            };
          } ''
          mkdir -p $out
          cd $out
          unzip $src
        '';

        tex = final.texlive.combine {
          inherit (final.texlive) scheme-full;
        };

        buildLegrandExample = { texFile ? "main.tex" }:
          let
            baseName = prev.lib.removeSuffix ".tex" texFile;
          in
          final.stdenvNoCC.mkDerivation {
            name = baseName;
            src = final.legrandSrc;

            buildInputs = [ final.coreutils final.tex ];

            buildPhase = ''
              export PATH="${prev.lib.makeBinPath [ final.coreutils final.tex ]}"
              export HOME="$TMPDIR"

              pdflatex ${texFile}
              makeindex ${baseName}.idx -s indexstyle.ist
              biber ${baseName}
              pdflatex ${texFile}
              pdflatex ${texFile}
            '';

            installPhase = ''
              mkdir -p $out
              cp -v ${baseName}.pdf $out/
            '';

            dontPatchELF = true;
            dontFixup = true;
          };

        legrandOrangeBook = final.buildLegrandExample { texFile = "main.tex"; };

        testNixos = prev.testers.runNixOSTest {
          name = "legrand-orange-book-render-test";
          nodes.machine = { config, pkgs, lib, modulesPath, ... }:
            {
              imports = [
                "${dirOf modulesPath}/tests/common/x11.nix"
                "${dirOf modulesPath}/tests/common/user-account.nix"
              ];
              services.xserver.enable = true;
              services.xserver.displayManager.startx.enable = true;
              environment.systemPackages = with pkgs; [
                firefox
                kdePackages.okular
              ];
            };
          enableOCR = true;
          skipLint = false;
          skipTypeCheck = true;
          globalTimeout = 10 * 60;
          testScript = ''
            start_all()
            machine.wait_for_unit('graphical.target')

            machine.execute("okular ${final.legrandOrangeBook}/main.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("legrand_orange_book")
          '';
        };

        scriptShowInFirefox = prev.writeShellApplication {
          name = "script-firefox";
          runtimeInputs = with prev; [ bash firefox ];
          text = ''
            firefox "${final.legrandOrangeBook}/main.pdf"
          '';
        };

        scriptShowInOkular = prev.writeShellApplication {
          name = "script-show-in-okular";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.legrandOrangeBook}/main.pdf"
          '';
        };

        scriptShowPrintInOkular = prev.writeShellApplication {
          name = "script-show-print-screen-okular";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.testNixos}"/legrand_orange_book.png
          '';
        };

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#legrandOrangeBook' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

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

          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {
          packages = {
            inherit (pkgsAllowUnfree)
              allTests
              legrandOrangeBook
              scriptShowInFirefox
              scriptShowInOkular
              scriptShowPrintInOkular
              testNixos
              ;
            default = pkgsAllowUnfree.legrandOrangeBook;
          };

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          apps = {
            allTests = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.allTests}";
              meta.description = "Run all tests for this flake";
            };
            default = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInOkular}";
              meta.description = "Open the Legrand Orange Book PDF in Okular";
            };
            scriptShowInFirefox = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInFirefox}";
              meta.description = "Open the Legrand Orange Book PDF in Firefox";
            };
            scriptShowPrintInOkular = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowPrintInOkular}";
              meta.description = "Show the NixOS test screenshot in Okular";
            };
          };

          checks = {
            inherit (pkgsAllowUnfree)
              allTests
              legrandOrangeBook
              testNixos
              ;
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
            ];
            shellHook = ''
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
