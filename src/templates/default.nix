{

  # TODO: better name it.
  startConfig = {
    description = "Base configuration";
    path = ./start-config;
  };

  QEMUVirtualMachineXfceCopyPaste = {
    description = "QEMU Virtual Machine with xfce and copy/paste working";
    path = ./qemu-virtual-machine-xfce-copy-paste;
    welcomeText = ''
      # A
      ## B
      C
        ## More D
      - [Rust on the NixOS Wiki](https://nixos.wiki/wiki/Rust)
      - ...
    '';
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
