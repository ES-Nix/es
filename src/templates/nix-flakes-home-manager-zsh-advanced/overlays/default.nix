# This file defines overlays
{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    allTests = let name = "all-tests"; in final.writeShellApplication
      {
        name = name;
        runtimeInputs = with final; [ ];
        text = ''
          nix fmt . \
          && nix flake show --all-systems --impure '.#' \
          && nix flake metadata --impure '.#' \
          && nix build --impure --no-link --print-build-logs --print-out-paths '.#' \
          && nix build --impure --no-link --print-build-logs --print-out-paths --rebuild '.#' \
          && nix develop --impure '.#' --command sh -c 'true' \
          && nix flake check --all-systems --impure --verbose '.#'
                
          nix build --no-link --print-build-logs --print-out-paths \
          '.#homeConfigurations.vagrant.activationPackage'
          nix build --no-link --print-build-logs --print-out-paths \
          '.#homeConfigurations.vagrant.activation-script'
        '';
      } // { meta.mainProgram = name; };

    f00Bar = prev.hello;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixos-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
