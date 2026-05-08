

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

Pkg.add([
    "GLPK",
    "JuMP",
  ])

using JuMP, GLPK

# Sample data: Items with (value, weight)
values = [60, 100, 120, 70, 90]
weights = [10, 20, 30, 21, 42]
capacity = 99

# Create a model
model = Model(GLPK.Optimizer)

# Define decision variables (x_i is binary)
@variable(model, x[1:3], Bin)

# Objective: Maximize total value
@objective(model, Max, sum(values[i] * x[i] for i in 1:3))

# Constraint: Total weight must not exceed capacity
@constraint(model, sum(weights[i] * x[i] for i in 1:3) <= capacity)

# Solve the model
optimize!(model)

# Display results
println("Optimal value: ", objective_value(model))
println("Selected items: ", [i for i in 1:3 if value(x[i]) > 0.5])
EOF
)"
COMMANDS
```
