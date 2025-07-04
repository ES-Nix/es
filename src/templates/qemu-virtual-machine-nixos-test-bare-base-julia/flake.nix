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

        testNixOSBare = final.testers.runNixOSTest {
          name = "test-bare-base";
          nodes = {
            machineABCZ = { config, pkgs, ... }: {

              environment.systemPackages = with pkgs; [

                ((julia.withPackages.override {
                  precompile = false; # Turn off precompilation
                }) [
                  /*
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

                        # MIT 
                        # "Juniper" # (MI)SOCP, (MI)NLP
                        # "SCS" # LP, QP, SOCP, SDP
                        # "DAQP" # (Mixed-binary) QP
                   */
                  # "KNITRO"
                  # "AmplNLWriter"
                  # "PolyJuMP"
                  # "SCS"
                  # "CDDLib"
                  # "MosekTools"
                  # "EAGO_jll"
                  # "PATHSolver.jl"
                  "DAQP"
                  /*
                          # Other tools
                          "ArgParse" 
                          # "Arpack"          
                          "BenchmarkProfiles"
                          "BenchmarkTools"
                          "Catalyst"
                          "CategoricalArrays"
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
                          "Gurobi"          
                          "HDF5"            
                          "IJulia"
                          "ImageShow"
                          "IndexFunArrays"
                          "InteractiveUtils"
                          "IterativeSolvers"
                          "JuliaFormatter"
                          "Juno"            
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
                          "VegaLite"  # to make some nice plots
                          "XLSX"
                          "ZipFile"
                          */
                  # "Atom"            
                  # "Flux.Losses"
                  # "Flux"
                  # "GraphViz"
                  # "ImageMagick"
                  # "IntervalArithmetic"
                  # "JLD"             
                  # "JLD2"
                  # "MathOptInterface"
                  # "UnicodePlots"
                ])
              ];

            };
          };
          testScript = { nodes, ... }: ''
            machineABCZ.succeed("julia --version")
          '';
        };

        testNixOSBareDriverInteractive = final.testNixOSBare.driverInteractive
          // { virtualisation.vmVariant.virtualisation.graphics = false; };
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
            testNixOSBare
            ;
          default = pkgs.testNixOSBareDriverInteractive;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.testNixOSBareDriverInteractive}";
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
