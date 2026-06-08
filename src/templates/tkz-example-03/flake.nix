{
  description = "A Nix flake for building all official abntex2 example documents";

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

        abntex2Src = prev.fetchFromGitHub {
          owner = "abntex";
          repo = "abntex2";
          rev = "master";
          hash = "sha256-uFkZZu2rR/DUNvQMqdxGy6dhGQcRVZeIVoD3eeK21k8=";
        };

        tex = final.texlive.combine {
          inherit (final.texlive) scheme-full;
        };

        buildAbntex2Example = { texFile, needsBibtex ? true, needsMakeindex ? false, needsMakeglossaries ? false, preBuildCommands ? "" }:
          let
            baseName = prev.lib.removeSuffix ".tex" texFile;
            extraInputs = prev.lib.optional needsMakeglossaries final.perl
            ++ prev.lib.optional (preBuildCommands != "") final.gnused;
          in
          final.stdenvNoCC.mkDerivation {
            name = baseName;
            src = "${final.abntex2Src}/doc/latex/abntex2/examples";

            buildInputs = [ final.coreutils final.tex ] ++ extraInputs;

            buildPhase = ''
              export PATH="${prev.lib.makeBinPath ([ final.coreutils final.tex ] ++ extraInputs)}"
              export HOME="$TMPDIR"

              ${preBuildCommands}
              pdflatex ${texFile}
              ${prev.lib.optionalString needsBibtex        "bibtex ${baseName}"}
              ${prev.lib.optionalString needsMakeindex      "makeindex ${baseName}"}
              ${prev.lib.optionalString needsMakeglossaries "makeglossaries ${baseName}"}
              pdflatex ${texFile}
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

        artigo = final.buildAbntex2Example { texFile = "abntex2-modelo-artigo.tex"; };
        trabalhoAcademico = final.buildAbntex2Example { texFile = "abntex2-modelo-trabalho-academico.tex"; };
        livro = final.buildAbntex2Example {
          texFile = "abntex2-modelo-livro.tex";
          # Strip Minion Pro PUA glyphs (U+E0C9, U+E0BF) embedded before comment markers.
          # They appear outside \ifxetex so pdflatex hits them and fatally errors.
          preBuildCommands = ''
            sed -i "s/$(printf '\xee\x83\x89')//g; s/$(printf '\xee\x82\xbf')//g" abntex2-modelo-livro.tex
          '';
        };
        relatorioTecnico = final.buildAbntex2Example { texFile = "abntex2-modelo-relatorio-tecnico.tex"; needsMakeindex = true; };
        slides = final.buildAbntex2Example { texFile = "abntex2-modelo-slides.tex"; };
        glossarios = final.buildAbntex2Example { texFile = "abntex2-modelo-glossarios.tex"; needsMakeindex = true; needsMakeglossaries = true; };
        projetoPesquisa = final.buildAbntex2Example { texFile = "abntex2-modelo-projeto-pesquisa.tex"; needsMakeindex = true; };

        testNixos = prev.testers.runNixOSTest {
          name = "abntex2-render-test";
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

            machine.execute("okular ${final.artigo}/abntex2-modelo-artigo.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("artigo")

            machine.execute("okular ${final.trabalhoAcademico}/abntex2-modelo-trabalho-academico.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("trabalho_academico")

            machine.execute("okular ${final.livro}/abntex2-modelo-livro.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("livro")

            machine.execute("okular ${final.relatorioTecnico}/abntex2-modelo-relatorio-tecnico.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("relatorio_tecnico")

            machine.execute("okular ${final.slides}/abntex2-modelo-slides.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("slides")

            machine.execute("okular ${final.glossarios}/abntex2-modelo-glossarios.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("glossarios")

            machine.execute("okular ${final.projetoPesquisa}/abntex2-modelo-projeto-pesquisa.pdf >&2 &")
            machine.wait_for_window("okular")
            machine.screenshot("projeto_pesquisa")
          '';
        };

        scriptShowInFirefox = prev.writeShellApplication {
          name = "script-firefox";
          runtimeInputs = with prev; [ bash firefox ];
          text = ''
            firefox \
              "${final.artigo}/abntex2-modelo-artigo.pdf" \
              "${final.trabalhoAcademico}/abntex2-modelo-trabalho-academico.pdf" \
              "${final.livro}/abntex2-modelo-livro.pdf" \
              "${final.relatorioTecnico}/abntex2-modelo-relatorio-tecnico.pdf" \
              "${final.slides}/abntex2-modelo-slides.pdf" \
              "${final.glossarios}/abntex2-modelo-glossarios.pdf" \
              "${final.projetoPesquisa}/abntex2-modelo-projeto-pesquisa.pdf"
          '';
        };

        scriptShowInOkular = prev.writeShellApplication {
          name = "script-show-in-okular";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular \
              "${final.artigo}/abntex2-modelo-artigo.pdf" \
              "${final.trabalhoAcademico}/abntex2-modelo-trabalho-academico.pdf" \
              "${final.livro}/abntex2-modelo-livro.pdf" \
              "${final.relatorioTecnico}/abntex2-modelo-relatorio-tecnico.pdf" \
              "${final.slides}/abntex2-modelo-slides.pdf" \
              "${final.glossarios}/abntex2-modelo-glossarios.pdf" \
              "${final.projetoPesquisa}/abntex2-modelo-projeto-pesquisa.pdf"
          '';
        };

        scriptShowPrintInOkular = prev.writeShellApplication {
          name = "script-show-print-screen-okular";
          runtimeInputs = with prev; [ kdePackages.okular ];
          text = ''
            okular "${final.testNixos}"/artigo.png
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
              && nix build --no-link --print-build-logs --print-out-paths '.#artigo' \
              && nix build --no-link --print-build-logs --print-out-paths '.#trabalhoAcademico' \
              && nix build --no-link --print-build-logs --print-out-paths '.#livro' \
              && nix build --no-link --print-build-logs --print-out-paths '.#relatorioTecnico' \
              && nix build --no-link --print-build-logs --print-out-paths '.#slides' \
              && nix build --no-link --print-build-logs --print-out-paths '.#glossarios' \
              && nix build --no-link --print-build-logs --print-out-paths '.#projetoPesquisa' \
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
              artigo
              trabalhoAcademico
              livro
              relatorioTecnico
              slides
              glossarios
              projetoPesquisa
              scriptShowInFirefox
              scriptShowInOkular
              scriptShowPrintInOkular
              testNixos
              ;
            default = pkgsAllowUnfree.trabalhoAcademico;
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
              meta.description = "Open all abntex2 example PDFs in Okular";
            };
            scriptShowInFirefox = {
              type = "app";
              program = "${pkgsAllowUnfree.lib.getExe pkgsAllowUnfree.scriptShowInFirefox}";
              meta.description = "Open all abntex2 example PDFs in Firefox";
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
              artigo
              trabalhoAcademico
              livro
              relatorioTecnico
              slides
              glossarios
              projetoPesquisa
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
