


https://nixos.wiki/wiki/Nixpkgs/Reviewing_changes#Testing_the_cross-compilation_of_modules

```bash
nix \ 
build \ 
'.#nixosConfigurations.nixos.config.services.xserver.displayManager.sessionData.desktops'
```

```bash
$(ldd  $(which id) | tail -n1 | cut -d ' ' -f3)
```


```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.pkgsReview.url = "github:Artturin/nixpkgs/pipewirejackldpath";
  #inputs.pkgsReview.url = "/home/artturin/nixgits/my-nixpkgs";

  outputs = inputs@{ self, nixpkgs, pkgsReview }: {

    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ({ pkgs, ... }: {
          disabledModules = [ "services/desktops/pipewire/pipewire.nix" ];
          imports = [
            "${inputs.pkgsReview}/nixos/modules/services/desktops/pipewire/pipewire.nix"

            # For virtualisation settings
            "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
          ];

          services.pipewire.enable = true;

          # Documentation for these is in nixos/modules/virtualisation/qemu-vm.nix
          virtualisation = {
            memorySize = 1024 * 3;
            diskSize = 1024 * 3;
            cores = 4;
            msize = 104857600;
          };

          users.mutableUsers = false;
          users.users.root = {
            password = "root";
          };
          users.users.user = {
            password = "user";
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        })
      ];
    };
    # So that we can just run 'nix run' instead of
    # 'nix build ".#nixosConfigurations.vm.config.system.build.vm" && ./result/bin/run-nixos-vm'
    defaultPackage.x86_64-linux = self.nixosConfigurations.vm.config.system.build.vm;
    defaultApp.x86_64-linux = {
      type = "app";
      program = "${self.defaultPackage.x86_64-linux}/bin/run-nixos-vm";
    };
  };
}
```


```nix
{
  inputs = {
    nixpkgs.url = "github:ju1m/nixpkgs/display-managers";
  };

  outputs = inputs@{ self, nixpkgs }: {

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, lib, config, ... }: {
          nixpkgs.crossSystem = lib.systems.examples.aarch64-multiplatform;
          services.xserver = {
            enable = true;
            desktopManager.session = [
              { name = "home-manager";
                start = ''
                  ${pkgs.runtimeShell} $HOME/.hm-xsession &
                  waitPID=$!
                '';
                bgSupport = true;
              }
            ];
          };
        })
      ];
    };
  };
}
```
