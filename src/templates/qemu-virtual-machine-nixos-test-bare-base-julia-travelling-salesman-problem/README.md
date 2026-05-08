

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```


```bash

```



Spoiler, it gave an broken python "solution".
ollama run deepseek-r1:14b <<<'Need an MINLP global solver solution written in Julia to the TSP problem.'


```bash
nix \
shell \
--ignore-environment \
--override-flake \
nixpkgs \
github:NixOS/nixpkgs/107d5ef05c0b1119749e381451389eded30fb0d5 \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#julia-bin \
--command \
bash <<'COMMANDS'
julia --eval "$(cat <<'EOF'
using Pkg
Pkg.add("JuMP")
Pkg.add("GLPK")  # For nonlinear optimization

using JuMP
using GLPK

# travelling salesman problem
# Number of cities
n = 20

# Distance matrix (example, you can replace it with your own data)
dist = [
     0    83    86    77    15    93    35    86    92    49    21    62    27    90    59    63    26    40    26    72;
    83     0    36    11    68    67    29    82    30    62    23    67    35    29     2    22    58    69    67    93;
    86    36     0    56    11    42    29    73    21    19    84    37    98    24    15    70    13    26    91    80;
    77    11    56     0    56    73    62    70    96    81     5    25    84    27    36     5    46    29    13    57;
    15    68    11    56     0    24    95    82    45    14    67    34    64    43    50    87     8    76    78    88;
    93    67    42    73    24     0    84     3    51    54    99    32    60    76    68    39    12    26    86    94;
    35    29    29    62    95    84     0    39    95    70    34    78    67     1    97     2    17    92    52    56;
    86    82    73    70    82     3    39     0     1    80    86    41    65    89    44    19    40    29    31    17;
    92    30    21    96    45    51    95     1     0    97    71    81    75     9    27    67    56    97    53    86;
    49    62    19    81    14    54    70    80    97     0    65     6    83    19    24    28    71    32    29     3;
    21    23    84     5    67    99    34    86    71    65     0    19    70    68     8    15    40    49    96    23;
    62    67    37    25    34    32    78    41    81     6    19     0    18    45    46    51    21    55    79    88;
    27    35    98    84    64    60    67    65    75    83    70    18     0    64    28    41    50    93     0    34;
    90    29    24    27    43    76     1    89     9    19    68    45    64     0    64    24    14    87    56    43;
    59     2    15    36    50    68    97    44    27    24     8    46    28    64     0    91    27    65    59    36;
    63    22    70     5    87    39     2    19    67    28    15    51    41    24    91     0    32    51    37    28;
    26    58    13    46     8    12    17    40    56    71    40    21    50    14    27    32     0    75     7    74;
    40    69    26    29    76    26    92    29    97    32    49    55    93    87    65    51    75     0    21    58;
    26    67    91    13    78    86    52    31    53    29    96    79     0    56    59    37     7    21     0    95;
    72    93    80    57    88    94    56    17    86     3    23    88    34    43    36    28    74    58    95     0
        ]

# Create a JuMP model using the GLPK solver
model = Model(GLPK.Optimizer)

# Binary decision variables for the routes (0 or 1)
@variable(model, x[1:n, 1:n], Bin)

# Continuous decision variables for the tour length
@variable(model, d[1:n, 1:n] >= 0)

# Objective: Minimize total distance traveled
@objective(model, Min, sum(dist[i, j] * x[i, j] for i = 1:n, j = 1:n))

# Constraints

# Ensure each city is visited exactly once
@constraint(model, [i=1:n], sum(x[i, j] for j=1:n if i != j) == 1)   # Outbound
@constraint(model, [j=1:n], sum(x[i, j] for i=1:n if i != j) == 1)   # Inbound

# Optional: Remove the MTZ constraint temporarily to test feasibility
# Subtour elimination constraint (Miller-Tucker-Zemlin formulation)
#@constraint(model, [i=2:n, j=2:n, k=1:n-1], d[i,j] - d[i,k] + n*x[i,j] <= n-1)

# Solve the model
optimize!(model)

# Check if the solver found a solution
status = termination_status(model)

if status == MOI.OPTIMAL
    println("Optimal solution found!")
    println("Total travel distance: ", objective_value(model))

    # Extract the tour from the variable x
    tour = []
    for i = 1:n
        for j = 1:n
            if value(x[i, j]) > 0.5
                push!(tour, (i, j))
            end
        end
    end

    println("Tour: ", tour)
else
    println("No optimal solution found. Solver status: ", status)
end
EOF
)"
COMMANDS
```
