{

  /*
    welcomeText = ''
      # A
      ## B
      C
        ## More D
      - [Rust on the NixOS Wiki](https://nixos.wiki/wiki/Rust)
      - ...
    '';
  */

  # TODO: better name it.
  startConfig = {
    description = "Base configuration";
    path = ./start-config;
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

  QEMUVirtualMachineXfceCopyPaste = {
    description = "QEMU Virtual Machine with xfce and copy/paste working";
    path = ./qemu-virtual-machine-xfce-copy-paste;
  };

  QEMUVirtualMachineXfceCopyPasteMinimal = {
    description = "Minimal QEMU Virtual Machine with xfce and copy/paste working";
    path = ./qemu-virtual-machine-xfce-copy-paste-minimal;
  };

  QEMUVirtualMachineXfceCopyPasteK8s = {
    description = "QEMU Virtual Machine with xfce and copy/paste and k8s";
    path = ./qemu-virtual-machine-xfce-copy-paste-k8s;
  };

  QEMUVirtualMachineDocker = {
    description = "QEMU Virtual Machine with docker";
    path = ./qemu-virtual-machine-docker;
  };

}
