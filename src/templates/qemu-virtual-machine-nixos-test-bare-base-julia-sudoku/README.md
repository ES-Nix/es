

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash

```



```bash
nix \
shell \
--ignore-environment \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/05bbf675397d5366259409139039af8077d695ce \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#julia-bin \
--command \
bash <<'COMMANDS'

julia --eval "$(cat <<'EOF'
import Pkg

Pkg.add([
    "GLPK",
    "JuMP",
  ])

using JuMP, GLPK

# Function to create the Sudoku solver
function sudoku_solver(puzzle::Array{Int,2})
    n = 9
    model = Model(GLPK.Optimizer)

    # Define variables: 9x9 grid, each cell can have a value between 1 and 9
    @variable(model, x[1:n, 1:n, 1:n], Bin)  # Binary variable for each cell's possible values

    # Add constraints to enforce the Sudoku rules

    # Each cell must have exactly one value between 1 and 9
    for i in 1:n
        for j in 1:n
            @constraint(model, sum(x[i, j, k] for k in 1:n) == 1)
        end
    end

    # Each number 1-9 must appear exactly once in each row
    for i in 1:n
        for k in 1:n
            @constraint(model, sum(x[i, j, k] for j in 1:n) == 1)
        end
    end

    # Each number 1-9 must appear exactly once in each column
    for j in 1:n
        for k in 1:n
            @constraint(model, sum(x[i, j, k] for i in 1:n) == 1)
        end
    end

    # Each number 1-9 must appear exactly once in each 3x3 subgrid
    for k in 1:n
        for row in 1:3:n
            for col in 1:3:n
                @constraint(model, sum(x[i, j, k] for i in row:row+2, j in col:col+2) == 1)
            end
        end
    end

    # Incorporate the initial puzzle values
    for i in 1:n
        for j in 1:n
            if puzzle[i, j] != 0
                @constraint(model, x[i, j, puzzle[i, j]] == 1)
            end
        end
    end

    # Solve the model
    optimize!(model)

    # Extract the solution and print the result
    solution = Array{Int, 2}(undef, n, n)
    for i in 1:n
        for j in 1:n
            for k in 1:n
                if value(x[i, j, k]) > 0.5  # if this value is selected
                    solution[i, j] = k
                end
            end
        end
    end
    return solution
end

# Example Sudoku puzzle (0 represents empty cells)
puzzle = [
    5 3 0 0 7 0 0 0 0;
    6 0 0 1 9 5 0 0 0;
    0 9 8 0 0 0 0 6 0;
    8 0 0 0 6 0 0 0 3;
    4 0 0 8 0 3 0 0 1;
    7 0 0 0 2 0 0 0 6;
    0 6 0 0 0 0 2 8 0;
    0 0 0 4 1 9 0 0 5;
    0 0 0 0 8 0 0 7 9
]

# Solve the Sudoku puzzle
solution = sudoku_solver(puzzle)

# Display the solution
println("Solution:")
println(solution)
EOF
)"
COMMANDS
```


```bash
# nix-shell -p 'julia_19.withPackages ["Plots"]'
nix \
shell \
--ignore-environment \
--keep HOME \
--keep USER \
--impure \
--expr \
'
  (
      let
        nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/107d5ef05c0b1119749e381451389eded30fb0d5");
        pkgs = import nixpkgs { };    
      in
        with pkgs; [ 
                    (julia.withPackages [
                          "JuMP"
                          "GLPK"
                        ])
                    bash
                  ]
  )
' \
--command \
julia \
--eval \
"$(cat <<'EOF'
import Pkg

using JuMP, GLPK

# Function to create the Sudoku solver
function sudoku_solver(puzzle::Array{Int,2})
    n = 9
    model = Model(GLPK.Optimizer)

    # Define variables: 9x9 grid, each cell can have a value between 1 and 9
    @variable(model, x[1:n, 1:n, 1:n], Bin)  # Binary variable for each cell's possible values

    # Add constraints to enforce the Sudoku rules

    # Each cell must have exactly one value between 1 and 9
    for i in 1:n
        for j in 1:n
            @constraint(model, sum(x[i, j, k] for k in 1:n) == 1)
        end
    end

    # Each number 1-9 must appear exactly once in each row
    for i in 1:n
        for k in 1:n
            @constraint(model, sum(x[i, j, k] for j in 1:n) == 1)
        end
    end

    # Each number 1-9 must appear exactly once in each column
    for j in 1:n
        for k in 1:n
            @constraint(model, sum(x[i, j, k] for i in 1:n) == 1)
        end
    end

    # Each number 1-9 must appear exactly once in each 3x3 subgrid
    for k in 1:n
        for row in 1:3:n
            for col in 1:3:n
                @constraint(model, sum(x[i, j, k] for i in row:row+2, j in col:col+2) == 1)
            end
        end
    end

    # Incorporate the initial puzzle values
    for i in 1:n
        for j in 1:n
            if puzzle[i, j] != 0
                @constraint(model, x[i, j, puzzle[i, j]] == 1)
            end
        end
    end

    # Solve the model
    optimize!(model)

    # Extract the solution and print the result
    solution = Array{Int, 2}(undef, n, n)
    for i in 1:n
        for j in 1:n
            for k in 1:n
                if value(x[i, j, k]) > 0.5  # if this value is selected
                    solution[i, j] = k
                end
            end
        end
    end
    return solution
end

# Example Sudoku puzzle (0 represents empty cells)
puzzle = [
    5 3 0 0 7 0 0 0 0;
    6 0 0 1 9 5 0 0 0;
    0 9 8 0 0 0 0 6 0;
    8 0 0 0 6 0 0 0 3;
    4 0 0 8 0 3 0 0 1;
    7 0 0 0 2 0 0 0 6;
    0 6 0 0 0 0 2 8 0;
    0 0 0 4 1 9 0 0 5;
    0 0 0 0 8 0 0 7 9
]

# Solve the Sudoku puzzle
solution = sudoku_solver(puzzle)

# Display the solution
println("Solution:")
println(solution)
EOF
)"
```
Refs.:
- https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers
