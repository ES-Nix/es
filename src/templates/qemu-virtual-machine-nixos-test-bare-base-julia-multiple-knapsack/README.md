

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
github:NixOS/nixpkgs/107d5ef05c0b1119749e381451389eded30fb0d5 \
nixpkgs#bashInteractive \
nixpkgs#coreutils \
nixpkgs#julia-bin \
--command \
bash <<'COMMANDS'
julia --eval "$(cat <<'EOF'
import Pkg

# Pkg.add([
#     "GLPK",
#     "JuMP",
#   ])

using JuMP, GLPK

# Sample data: Items with (value, weight)
values = [6, 10, 12, 15, 14]
weights = [10, 20, 23, 24, 22]

# Multiple knapsacks with different capacities
capacities = [347]

# Create the model
model = Model(GLPK.Optimizer)

# Number of items and knapsacks
num_items = length(values)
num_knapsacks = length(capacities)

# Define decision variables: x[i, j] is the number of times item i is placed in knapsack j
@variable(model, x[1:num_items, 1:num_knapsacks] >= 0, Int)

# Weighting factors for the objectives
alpha = 0.8  # Weighting factor for value
beta = 0.3   # Weighting factor for weight

# Objective: Maximize total value and minimize total weight
@objective(model, Max, alpha * sum(values[i] * x[i, j] for i in 1:num_items, j in 1:num_knapsacks) - 
                          beta * sum(weights[i] * x[i, j] for i in 1:num_items, j in 1:num_knapsacks))

# Add capacity constraints for each knapsack
for j in 1:num_knapsacks
    @constraint(model, sum(weights[i] * x[i, j] for i in 1:num_items) <= capacities[j])
end

# Solve the model
optimize!(model)

# Display results
println("Optimal objective value: ", objective_value(model))

# Find and print selected items for each knapsack
for j in 1:num_knapsacks
    println("Knapsack ", j, " selected items (item: quantity):")
    for i in 1:num_items
        if value(x[i, j]) > 0
            println("Item ", i, " selected ", value(x[i, j]), " times.")
        end
    end
end
EOF
)"
COMMANDS
```
