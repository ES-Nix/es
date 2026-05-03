let
  pythonFlaskPoetry2nixTemplates = {
    pythonFlaskPoetry2nixHello = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-hello;
    };
    pythonFlaskPoetry2nixMmh3 = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-mmh3;
    };
    pythonFlaskPoetry2nixNumpy = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-numpy;
    };
    pythonFlaskPoetry2nixPandas = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-pandas;
    };
    pythonFlaskPoetry2nixGeopandas = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-geopandas;
    };
    pythonFlaskPoetry2nixPolars = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-polars;
    };
    pythonFlaskPoetry2nixScipy = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-scipy;
    };
    # pythonFlaskPoetry2nixBloated = {
    #   description = "";
    #   path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-flask-bloated;
    # };
  };

  pythonFastAPIPoetry2nixTemplates = {
    pythonFastAPIPoetry2nixHello = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-hello;
    };
    pythonFastAPIPoetry2nixMmh3 = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-mmh3;
    };
    pythonFastAPIPoetry2nixNumpy = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-numpy;
    };
    pythonFastAPIPoetry2nixPandas = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-pandas;
    };
    pythonFastAPIPoetry2nixGeopandas = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-geopandas;
    };
    pythonFastAPIPoetry2nixPolars = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-polars;
    };
    pythonFastAPIPoetry2nixScipy = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-scipy;
    };
    # pythonFastAPIPoetry2nixBloated = {
    #   description = "";
    #   path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-bloated;
    # };
  };

  python3Weirdos = {
    pythonFastAPIPoetry2nixScipy = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-fastapi-scipy;
    };
  };

  vagrantNixOSQEMUWithLibvirt = {
    vagrantNixOSQEMUWithLibvirtAlpine = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-alpine;
    };
  };

  otherTemplates = {
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
      path = ./nix-flakes-flake-utils-devshell;
    };

    devShellHomeManagerFlakeUtils = {
      description = "Example of: home-manager, devShell, and flake-utils to support multiple architectures";
      path = ./nix-flakes-flake-utils-devshell-home-manager;
    };

    devShellHomeManagerFlakeUtilsNixOSVM = {
      description = "Example of: home-manager, NixOS QEMU VM, devShell, and flake-utils to support multiple architectures";
      path = ./nix-flakes-flake-utils-devshell-home-manager-nixosvm;
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

    # flakesUtilsGodot4 = {
    #   description = "godot4 mult-arch flake";
    #   path = ./flake-utils-godot4;
    # };

    pandocLaTeX = {
      description = "pandoc markdown to PDF using LaTeX";
      path = ./pandoc-latex;
    };

    QEMUVirtualMachineXfceCopyPaste = {
      description = "QEMU Virtual Machine with xfce and copy/paste working";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker;
    };

    QEMUVirtualMachineXfceCopyPasteKubernetes = {
      description = "QEMU Virtual Machine with xfce and copy/paste and k8s";
      path = ./qemu-virtual-machine-xfce-copy-paste-kubernetes;
    };

    QEMUVirtualMachineDocker = {
      description = "QEMU Virtual Machine with docker";
      path = ./qemu-virtual-machine-docker;
    };
  };

  vagrantTemplates = {
    vagrantNixOSQEMUWithLibvirtAlmalinux = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-almalinux;
    };
    vagrantNixOSQEMUWithLibvirtAlpine = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-alpine;
    };
    vagrantNixOSQEMUWithLibvirtAlpineMinimal = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-alpine-minimal;
    };
    vagrantNixOSQEMUWithLibvirtAlpineUpdates = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-alpine-updated;
    };
    vagrantNixOSQEMUWithLibvirtArchlinux = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-archlinux;
    };
    vagrantNixOSQEMUWithLibvirtDebian = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-debian;
    };
    vagrantNixOSQEMUWithLibvirtFedora = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-fedora;
    };
    vagrantNixOSQEMUWithLibvirtNixOS = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-nixos;
    };
    vagrantNixOSQEMUWithLibvirtOpensuse = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-opensuse;
    };
    vagrantNixOSQEMUWithLibvirtUbuntu = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-libvirt-vagrant-ubuntu;
    };
  };

  staticCompiledTemplates = {
    staticMemcached = {
      description = "";
      path = ./static-memcached;
    };
    staticCrossMemcached = {
      description = "";
      path = ./static-cross-memcached;
    };
    staticMinimalBusyboxSandboxShell = {
      description = "";
      path = ./static-minimal-busybox-sandbox-shell;
    };
    staticNginx = {
      description = "";
      path = ./static-nginx;
    };
    # staticPodman = {
    #   description = "";
    #   path = ./static-podman;
    # };
    staticRedis = {
      description = "";
      path = ./static-redis;
    };
    staticValkey = {
      description = "";
      path = ./static-valkey;
    };
  };


in
{ }
//
otherTemplates
//
pythonFlaskPoetry2nixTemplates
//
pythonFastAPIPoetry2nixTemplates
//
vagrantTemplates
  //
staticCompiledTemplates
