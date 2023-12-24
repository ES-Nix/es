{

  # TODO: better name it.
  startConfig = {
    description = "Base configuration";
    path = ./start-config;
  };

  qemuVirtualMachineDocker = {
    description = "QEMU Virtual Machine with docker";
    path = ./qemu-virtual-machine-docker;
    welcomeText = ''
      # A
      ## B
      C
        ## More D
      - [Rust language](https://www.rust-lang.org/)
      - [Rust on the NixOS Wiki](https://nixos.wiki/wiki/Rust)
      - ...
    '';
  };

}
