OPTIONS=( 
    --option warn-dirty false
    --option abort-on-warn true
)

nix "${OPTIONS[@]}" fmt . \
&& nix "${OPTIONS[@]}" flake show '.#' \
&& nix "${OPTIONS[@]}" flake metadata '.#' \
&& nix "${OPTIONS[@]}" build --no-link --print-build-logs --print-out-paths '.#' \
&& nix "${OPTIONS[@]}" build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
&& nix "${OPTIONS[@]}" develop --ignore-environment '.#' --command sh -c 'true' \
&& nix "${OPTIONS[@]}" develop --ignore-environment '.#' --command sh -c 'source $stdenv/setup && phases="unpackPhase" genericBuild' \
&& nix "${OPTIONS[@]}" flake check --all-systems --impure --verbose '.#'
