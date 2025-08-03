{
  #                 ↓ deconstructed function args
  outputs = inputs@{ self, nixpkgs, ... }: {

    # To test it:
    # nix eval .#foo
    foo = "bar";

  };
}
