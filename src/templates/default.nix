{
  # TODO: better name it.
  startConfigNixFlakesHomeManagerZsh = {
    description = "Base configuration: nix + flakes + home-manager + zsh + vscodium + neovim";
    path = ./start-config-nix-flakes-flake-utils-home-manager;
    welcomeText = ''
      # A
      It was created to be an start point with some batteries include.
      ## B
      C
        ## More D
      - [nixos.wiki](https://nixos.wiki/wiki/)
      - ...
    '';
  };

  devShellHello = {
    description = "It is an nix flake example of a devShell and uses flake-utils to support multiple architectures";
    path = ./nix-flakes-flake-utils-dev-shell;
  };

  devShellHomeManagerFlakeUtils = {
    description = "Example of a devShell, uses flake-utils to support multiple architectures";
    path = ./nix-flakes-flake-utils-devShell-home-manager;
  };

  poetry2nixBasic = {
    description = "Basic poetry2nix pure python3 script example";
    path = ./poetry2nix-basic;
  };

  nixFlakesHomeManagerZsh = {
    description = "Base: nix + flakes + home-manager + zsh + vscodium + neovim";
    path = ./nix-flakes-home-manager-zsh;
  };

  nixFlakesHomeManagerZshAdvanced = {
    description = "Base: nix + flakes + home-manager + zsh + vscodium + neovim";
    path = ./nix-flakes-home-manager-zsh-advanced;
  };

  flakesUtilsGodot4 = {
    description = "godot4 mult-arch flake";
    path = ./flake-utils-godot4;
  };

  pandocLaTeX = {
    description = "pandoc markdown to PDF using LaTeX";
    path = ./pandoc-latex;
  };

  # QEMUVirtualMachineXfceCopyPaste = {
  #   description = "QEMU Virtual Machine with xfce and copy/paste working";
  #   path = ./qemu-virtual-machine-xfce-copy-paste;
  # };

  QEMUVirtualMachineXfceCopyPasteK8s = {
    description = "QEMU Virtual Machine with xfce and copy/paste and k8s";
    path = ./qemu-virtual-machine-xfce-copy-paste-k8s;
  };

  # QEMUVirtualMachineDocker = {
  #   description = "QEMU Virtual Machine with docker";
  #   path = ./qemu-virtual-machine-docker;
  # };

}
