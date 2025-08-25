{
  description = "";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/7c43f080a7f28b2774f3b3f43234ca11661bf334' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        juliaCustom = ((prev.julia.withPackages.override {
          precompile = false; # Turn off precompilation. TODO Why?
        }) [
          "JuMP" # ?
          "Juniper" # (MI)SOCP, (MI)NLP
          "SCS" # LP, QP, SOCP, SDP
          "DAQP" # (Mixed-binary) QP
        ]);

        juliaCustomBloated =
          let
            minplSolvers = [
              # Begin (MI)NLP Solvers
              "Alpine"
              "Couenne_jll"
              "GLPK"
              "HiGHS"
              "Ipopt"
              "JuMP"
              "Juniper"
              "Pajarito"
              "Pavito"
              "SCIP"
              # "EAGO"
              # "Minotaur"
              # "Octeract"
              # "SHOT"
              # End (MI)NLP Solvers
              # # MIT Solvers
              "Juniper" # (MI)SOCP, (MI)NLP
              "SCS" # LP, QP, SOCP, SDP
              "DAQP" # (Mixed-binary) QP
              # # MIT Solvers
            ];

            manyTools = [
              "ArgParse"
              "BenchmarkProfiles"
              "BenchmarkTools"
              "Catalyst"
              "CategoricalArrays"
              "CDDLib"
              "Chain"
              "Clustering"
              "Colors"
              "ComponentArrays"
              "Crayons" # Needed for OhMyREPL color scheme
              "CSV"
              "Dagitty"
              "DataFrames"
              "DataStructures"
              "Dates"
              "DiffEqFlux"
              "DifferentialEquations"
              "Distances"
              "Distributions"
              "FFTW"
              "FileIO"
              "FourierTools"
              "Graphs"
              "GraphViz"
              "Gurobi"
              "HDF5"
              "IJulia"
              "ImageMagick"
              "ImageShow"
              "IndexFunArrays"
              "InteractiveUtils"
              "IterativeSolvers"
              "JLD"
              "JLD2"
              "JuliaFormatter"
              "Juno"
              "KNITRO"
              "LanguageServer"
              "LaTeXStrings"
              "LazySets"
              "LightGraphs"
              "LinearAlgebra"
              "LinearMaps"
              "Markdown"
              "Measures"
              "Metaheuristics"
              "MethodOfLines"
              "ModelingToolkit"
              "NDTools"
              "NonlinearSolve"
              "OhMyREPL"
              "Optim"
              "Optimization"
              "OptimizationPolyalgorithms"
              "OrdinaryDiffEq"
              "Parameters"
              "Plots"
              "PlotThemes"
              "Pluto"
              "PlutoUI"
              "PolyJuMP"
              "PrettyTables"
              "Printf"
              "PyCall"
              "PyPlot"
              "Random"
              "Roots"
              "ScikitLearn"
              "SpecialFunctions"
              "SQLite"
              "StatsPlots"
              "TestImages"
              "TimeZones"
              "TypedPolynomials"
              "UrlDownload"
              "VegaLite" # to make some nice plots
              "XLSX"
              "ZipFile"

              # "AmplNLWriter"
              # "Arpack"
              # "Atom"
              # "EAGO_jll"
              # "Flux.Losses"
              # "Flux"
              # "IntervalArithmetic"
              # "MathOptInterface"
              # "MosekTools"
              # "PATHSolver.jl"
              # "UnicodePlots"
            ];
          in
          ((prev.julia.withPackages.override {
            precompile = false; # Turn off precompilation
          }) (
            minplSolvers
              ++
              manyTools
          ));

        testNixOSBare = final.testers.runNixOSTest {
          name = "test-bare-base";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {
              environment.systemPackages = with pkgs; [
                # juliaCustom
                juliaCustomBloated
              ];
            };
          };
          testScript = { nodes, ... }: ''
            # machineABCZ.succeed("julia --version")
            machineABCZ.succeed("""
              julia --version
              julia -e "using Pkg"
              # julia -e "import Pkg; using JuMP" 1>&2
            """)
          '';
        };

        testNixOSBareDriverInteractive = final.testNixOSBare.driverInteractive
          // {
          virtualisation.vmVariant.virtualisation.graphics = false;
          # meta.mainProgram = "${final.testNixOSBare.driverInteractive.name}";
        };
      })
    ];
  } // (
    let
      # nix flake show --allow-import-from-derivation --impure --refresh .#
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
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
            fooBar
            juliaCustom
            testNixOSBare
            ;
          default = pkgs.testNixOSBareDriverInteractive;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSBareDriverInteractive}";
            meta.mainProgram = "${pkgs.testNixOSBare.driverInteractive.name}";
            meta.description = "Test NixOS Bare Base with Julia";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testNixOSBareDriverInteractive
            ;
          default = pkgs.testNixOSBare;
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            fooBar
            testNixOSBare
            testNixOSBareDriverInteractive
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
}
