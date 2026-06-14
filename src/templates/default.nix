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
    pythonFastAPIPoetry2nixDjangoRestFrameworkHello = {
      description = "";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-django-rest-framework-hello;
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

    devShellHomeManagerFlakeUtilsPython3HttpServer = {
      description = "Example of: home-manager, NixOS QEMU VM, devShell, and flake-utils to support multiple architectures";
      path = ./nix-flakes-flake-utils-devshell-home-manager-python-http-server;
    };

    devShellFlakeUtilsPythonTools = {
      description = "devShell with flake-utils and python tools";
      path = ./nix-flakes-flake-utils-devshell-python-tools;
    };

    poetry2nixBasic = {
      description = "Basic poetry2nix pure python3 script example";
      path = ./poetry2nix-basic;
    };

    poetry2nixBasicFlask = {
      description = "Basic poetry2nix flask example";
      path = ./poetry2nix-basic-flask;
    };

    nixFlakesHomeManagerZsh = {
      description = "Base: nix + flakes + home-manager + zsh + vscodium + neovim";
      path = ./nix-flakes-home-manager-zsh;
    };

    nixFlakesHomeManagerZshAdvanced = {
      description = "Base: nix + flakes + home-manager + zsh + vscodium + neovim";
      path = ./nix-flakes-home-manager-zsh-advanced;
    };

    homeManagerBloated = {
      description = "Bloated home-manager example";
      path = ./home-manager-bloated;
    };

    # flakesUtilsGodot4 = {
    #   description = "godot4 mult-arch flake";
    #   path = ./flake-utils-godot4;
    # };

    pandocLaTeX = {
      description = "pandoc markdown to PDF using LaTeX";
      path = ./pandoc-latex;
    };

    xetex = {
      description = "XeTeX example";
      path = ./xetex;
    };

    xetexPendulumAnimaton = {
      description = "XeTeX pendulum animation example";
      path = ./xetex-pendulum-animaton;
    };

    QEMUVirtualMachineXfceCopyPaste = {
      description = "QEMU Virtual Machine with xfce and copy/paste working";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker;
    };

    QEMUVirtualMachineXfceCopyPasteDev = {
      description = "QEMU Virtual Machine with xfce and copy/paste (dev)";
      path = ./qemu-virtual-machine-xfce-copy-paste-dev;
    };

    QEMUVirtualMachineXfceCopyPasteDevBloated = {
      description = "QEMU Virtual Machine with xfce and copy/paste (dev bloated)";
      path = ./qemu-virtual-machine-xfce-copy-paste-dev-bloated;
    };

    QEMUVirtualMachineXfceCopyPasteKubernetes = {
      description = "QEMU Virtual Machine with xfce and copy/paste and k8s";
      path = ./qemu-virtual-machine-xfce-copy-paste-kubernetes;
    };

    QEMUVirtualMachineXfceCopyPasteSocat = {
      description = "QEMU Virtual Machine with xfce and socat";
      path = ./qemu-virtual-machine-xfce-copy-paste-socat;
    };

    QEMUVirtualMachineXfceCopyPasteSsh = {
      description = "QEMU Virtual Machine with xfce and SSH";
      path = ./qemu-virtual-machine-xfce-copy-paste-ssh;
    };

    QEMUVirtualMachineXfceCopyPasteSshPasswdBash = {
      description = "QEMU Virtual Machine with xfce, SSH, passwd and bash";
      path = ./qemu-virtual-machine-xfce-copy-paste-ssh-passwd-bash;
    };

    QEMUVirtualMachineXfceCopyPasteNixosTestBare = {
      description = "QEMU Virtual Machine with xfce and NixOS test (bare)";
      path = ./qemu-virtual-machine-xfce-copy-paste-nixos-test-bare;
    };

    QEMUVirtualMachineXfceCopyPasteNixosTestPythonVenvNumpy = {
      description = "QEMU Virtual Machine with xfce and NixOS test python venv numpy";
      path = ./qemu-virtual-machine-xfce-copy-paste-nixos-test-python-venv-numpy;
    };

    QEMUVirtualMachineXfceCopyPastePythonHttpServerForwardPorts = {
      description = "QEMU Virtual Machine with xfce and python http server with port forwarding";
      path = ./qemu-virtual-machine-xfce-copy-paste-python-http-server-forward-ports;
    };

    QEMUVirtualMachineXfceCopyPasteDockerFlask = {
      description = "QEMU Virtual Machine with xfce, docker and flask";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-flask;
    };

    QEMUVirtualMachineXfceCopyPasteDockerPodmanFlask = {
      description = "QEMU Virtual Machine with xfce, docker, podman and flask";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-podman-flask;
    };

    QEMUVirtualMachineXfceCopyPasteDockerPythonScriptAndPackage = {
      description = "QEMU Virtual Machine with xfce, docker, python script and package";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-python-script-and-package;
    };

    QEMUVirtualMachineXfceCopyPasteDockerPoetry2nixBloat = {
      description = "QEMU Virtual Machine with xfce, docker and poetry2nix bloat";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-poetry2nix-bloat;
    };

    QEMUVirtualMachineXfceVagrantVirtualboxUbuntu = {
      description = "QEMU Virtual Machine with xfce and vagrant virtualbox ubuntu";
      path = ./qemu-virtual-machine-xfce-vagrant-virtualbox-ubuntu;
    };

    QEMUVirtualMachineDocker = {
      description = "QEMU Virtual Machine with docker";
      path = ./qemu-virtual-machine-docker;
    };

    QEMUVirtualMachineSsh = {
      description = "QEMU Virtual Machine with SSH";
      path = ./qemu-virtual-machine-ssh;
    };

    dockerMultipleKernelVersions = {
      description = "Docker with multiple kernel versions";
      path = ./docker-multiple-kernel-versions;
    };

    kubenetesNginx = {
      description = "Kubernetes nginx example";
      path = ./kubenetes-nginx;
    };

    pythonWheelsLinuxX8664TestersRunNixosTests = {
      description = "Python wheels linux x86_64 testers run nixos tests";
      path = ./python-wheels-linux-x86-64-testers-run-nixos-tests;
    };

    unprivilegedUserNixHomeManagerQemuNixosVirtualMachineDocker = {
      description = "Unprivileged user nix home-manager QEMU NixOS VM with docker";
      path = ./unprivileged-user-nix-home-manager-qemu-nixos-virtual-machine-docker;
    };

    bugNixostest = {
      description = "Bug reproduction: NixOS test";
      path = ./bug-nixostest;
    };

    bugQemuVirtualMachineXfceCopyPaste = {
      description = "Bug reproduction: QEMU VM xfce copy paste";
      path = ./bug-qemu-virtual-machine-xfce-copy-paste;
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
    staticMinimalToybox = {
      description = "";
      path = ./static-minimal-toybox;
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

  nixStaticOciImageTemplates = {
    nixStaticBare = {
      description = "Bare OCI image with only a statically linked Nix";
      path = ./nix-static-bare;
    };
    nixStaticUnprivileged = {
      description = "OCI image with static Nix, busybox and an unprivileged user";
      path = ./nix-static-unprivileged;
    };
    nixStaticCaBundleEtcPasswdEtcGroupTmp = {
      description = "OCI image with static Nix, CA bundle, /etc/passwd, /etc/group and tmp";
      path = ./nix-static-ca-bundle-etc-passwd-etc-group-tmp;
    };
    nixStaticBusyboxSandboxShellCaBundleEtcPasswdEtcGroupTmp = {
      description = "OCI image with static Nix, busybox-sandbox-shell, CA bundle, /etc/passwd, /etc/group and tmp";
      path = ./nix-static-busybox-sandbox-shell-ca-bundle-etc-passwd-etc-group-tmp;
    };
    nixStaticBashInteractiveCaBundleEtcPasswdEtcGroupTmp = {
      description = "OCI image with static Nix, bashInteractive, CA bundle, /etc/passwd, /etc/group and tmp";
      path = ./nix-static-bash-interactive-ca-bundle-etc-passwd-etc-group-tmp;
    };
    nixStaticCoreutilsBashInteractiveCaBundleEtcPasswdEtcGroupTmp = {
      description = "OCI image with static Nix, coreutils, bashInteractive, CA bundle, /etc/passwd, /etc/group and tmp";
      path = ./nix-static-coreutils-bash-interactive-ca-bundle-etc-passwd-etc-group-tmp;
    };
    nixStaticToyboxCaBundleEtcPasswdEtcGroupTmp = {
      description = "OCI image with static Nix, toybox, CA bundle, /etc/passwd, /etc/group and tmp";
      path = ./nix-static-toybox-ca-bundle-etc-passwd-etc-group-tmp;
    };
  };

  binfmtTemplates = {
    binfmtEmulatedSystemsHello = {
      description = "";
      path = ./binfmt-emulated-systems-hello;
    };
    binfmtEmulatedSystemsDocker = {
      description = "";
      path = ./binfmt-emulated-systems-docker;
    };
    binfmtEmulatedSystemsPythonDockerRegistryImages = {
      description = "";
      path = ./binfmt-emulated-systems-python-docker-registry-images;
    };
    binfmtEmulatedRiscv64PythonAlpineWheelsViaPipAndDocker = {
      description = "";
      path = ./binfmt-emulated-riscv64-python-alpine-wheels-via-pip-and-docker;
    };
    binfmtEmulatedRiscv64PythonWheelsDockerRegistryImages = {
      description = "";
      path = ./binfmt-emulated-riscv64-python-wheels-docker-registry-images;
    };
  };

  nixosTemplates = {
    nixosIsoOfflineInstall = {
      description = "";
      path = ./nixos-iso-offline-install;
    };
    nixosIsoOfflineInstallMinimal = {
      description = "";
      path = ./nixos-iso-offline-install-minimal;
    };
    nixosTestsHelloSystemdService = {
      description = "";
      path = ./nixos-tests-hello-systemd-service;
    };
    nixosBuildVmSystemdSelfHostedRunnerForGithubActions = {
      description = "";
      path = ./nixos-build-vm-systemd-self-hosted-runner-for-github-actions;
    };
    nixosBuildVmKubernetesSelfHostedRunnerForGithubActions = {
      description = "";
      path = ./nixos-build-vm-kubernetes-self-hosted-runner-for-github-actions;
    };
  };

  fastapiCeleryTemplates = {
    fastapiCeleryAppDockerComposeUv = {
      description = "";
      path = ./fastapi-celery-app-docker-compose-uv;
    };
    fastapiCeleryAppDockerComposePip = {
      description = "";
      path = ./fastapi-celery-app-docker-compose-pip;
    };
    fastapiCeleryAppDockerComposePoetry = {
      description = "";
      path = ./fastapi-celery-app-docker-compose-poetry;
    };
  };

  qemuNixosTestTemplates = {
    qemuVirtualMachineNixosTestBareBase = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base;
    };
    qemuVirtualMachineNixosTestBareBaseNixCli = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-cli;
    };
    qemuVirtualMachineNixosTestBareBaseMultiPing = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-multi-ping;
    };
    qemuVirtualMachineNixosTestBareBaseMultiSshKeyscan = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-multi-ssh-keyscan;
    };
    qemuVirtualMachineNixosTestBareBaseFlamegraphPerf = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-flamegraph-perf;
    };
    qemuVirtualMachineNixosTestBareBaseJulia = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-julia;
    };
    qemuVirtualMachineNixosTestBareBaseJuliaKnapsack = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-julia-knapsack;
    };
    qemuVirtualMachineNixosTestBareBaseJuliaMultipleKnapsack = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-julia-multiple-knapsack;
    };
    qemuVirtualMachineNixosTestBareBaseJuliaCirclePacking = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-julia-circle-packing;
    };
    qemuVirtualMachineNixosTestBareBaseJuliaSudoku = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-julia-sudoku;
    };
    qemuVirtualMachineNixosTestBareBaseJuliaTravellingSalesmanProblem = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-julia-travelling-salesman-problem;
    };
    qemuVirtualMachineNixosTestBareBasePypyRustpythonAndMany = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-pypy-rustpython-and-many;
    };
    qemuVirtualMachineNixosTestBareBasePythonNixBuiltWheels = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-python-nix-built-wheels;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPath = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathHelloRun = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-hello-run;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathHelloBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-hello-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathHelloUnfreeBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-hello-unfree-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathCrossHelloBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-cross-hello-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathNumpyBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-numpy-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathScipyBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-scipy-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathScipyWheelBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-scipy-wheel-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathMmh3WheelBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-mmh3-wheel-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathSqliteBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-sqlite-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathNixServe = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-nix-serve;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathNixServeAlpineNixClient = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-nix-serve-alpine-nix-client;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathNixStaticBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-nix-static-build-rebuild;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathNixStoreQuery = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-nix-store-query;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathGitZshStarshipFontsDirenvFzf = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-git-zsh-starship-fonts-direnv-fzf;
    };
    qemuVirtualMachineNixosTestBareBaseNixFlakesNixpkgsPathVagrantUnfreeBuildRebuild = {
      description = "";
      path = ./qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-vagrant-unfree-build-rebuild;
    };
  };

  latexTemplates = {
    fontspecXetex = {
      description = "Minimal xetex document with fontspec — PDF build test";
      path = ./fontspec-xetex;
    };

    gsCleanPdf = {
      description = "Ghostscript-compressed PDF (input: lualatex Hello World, rebuilt inline)";
      path = ./gs-clean-pdf;
    };

    latexDemoDocument = {
      description = "LaTeX demo document — lualatex Hello World PDF";
      path = ./latex-demo-document;
    };

    pandocCiteprocPdf = {
      description = "Pandoc bibliography pipeline — citeproc + xelatex to PDF";
      path = ./pandoc-citeproc-pdf;
    };

    pandocDemos = {
      description = "A Nix flake building all 53 official pandoc demo outputs";
      path = ./pandoc-demos;
    };

    pandocManualXelatex = {
      description = "Pandoc MANUAL.txt converted to PDF via xelatex";
      path = ./pandoc-manual-xelatex;
    };

    abntex2Examples = {
      description = "A Nix flake for building all official abntex2 example documents";
      path = ./tkz-example-03;
    };

    legrandOrangeBook = {
      description = "A Nix flake for building the Legrand Orange Book LaTeX template";
      path = ./tkz-example-04;
    };

    mosfetAmplifier = {
      description = "A Nix flake for building the mosfet amplifier";
      path = ./tkz-mosfet-amplifier;
    };
  };

  pythonUv2nixTemplates = {
    pythonFlaskUv2nixBasic = {
      description = "Basic uv2nix flask example";
      path = ./uv2nix-basic-flask;
    };
    pythonFlaskUv2nixHello = {
      description = "QEMU VM + Docker + uv2nix + Flask hello world";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-flask-hello;
    };
    pythonFastAPIUv2nixHello = {
      description = "QEMU VM + Docker + uv2nix + FastAPI hello world";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-fastapi-hello;
    };
    pythonFastAPIUv2nixMmh3 = {
      description = "QEMU VM + Docker + uv2nix + FastAPI + mmh3";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-fastapi-mmh3;
    };
    pythonFastAPIUv2nixNumpy = {
      description = "QEMU VM + Docker + uv2nix + FastAPI + numpy";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-fastapi-numpy;
    };
    pythonFastAPIUv2nixPandas = {
      description = "QEMU VM + Docker + uv2nix + FastAPI + pandas";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-fastapi-pandas;
    };
    pythonFastAPIUv2nixPolars = {
      description = "QEMU VM + Docker + uv2nix + FastAPI + polars";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-fastapi-polars;
    };
    pythonFastAPIUv2nixScipy = {
      description = "QEMU VM + Docker + uv2nix + FastAPI + scipy";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-fastapi-scipy;
    };
    pythonFastAPIUv2nixGeopandas = {
      description = "QEMU VM + Docker + uv2nix + FastAPI + geopandas";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-fastapi-geopandas;
    };
    pythonFlaskUv2nixMmh3 = {
      description = "QEMU VM + Docker + uv2nix + Flask + mmh3";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-flask-mmh3;
    };
    pythonFlaskUv2nixNumpy = {
      description = "QEMU VM + Docker + uv2nix + Flask + numpy";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-flask-numpy;
    };
    pythonFlaskUv2nixPandas = {
      description = "QEMU VM + Docker + uv2nix + Flask + pandas";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-flask-pandas;
    };
    pythonFlaskUv2nixPolars = {
      description = "QEMU VM + Docker + uv2nix + Flask + polars";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-flask-polars;
    };
    pythonFlaskUv2nixScipy = {
      description = "QEMU VM + Docker + uv2nix + Flask + scipy";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-flask-scipy;
    };
    pythonFlaskUv2nixGeopandas = {
      description = "QEMU VM + Docker + uv2nix + Flask + geopandas";
      path = ./qemu-virtual-machine-xfce-copy-paste-docker-uv2nix-flask-geopandas;
    };
  };

  jsExampleTemplates = {
    jsUglifyEs = {
      description = "npm install uglify-es";
      path = ./js-example-uglify-es;
    };
    jsBunCreateVue = {
      description = "bun create vue (interactive scaffold)";
      path = ./js-example-bun-create-vue;
    };
    jsVueJs = {
      description = "Vite + Vue.js (JavaScript)";
      path = ./js-example-vue-js;
    };
    jsVueTs = {
      description = "Vite + Vue.js (TypeScript)";
      path = ./js-example-vue-ts;
    };
    jsBcrypt = {
      description = "bcrypt native binding + NixOS test";
      path = ./js-example-bcrypt;
    };
    jsNativeModules = {
      description = "sqlite3 argon2 sharp node-sass native npm modules";
      path = ./js-example-native-modules;
    };
    jsFfiNapi = {
      description = "ffi-napi native binding (--ignore-scripts for Node 22)";
      path = ./js-example-ffi-napi;
    };
    jsNestJs = {
      description = "NestJS HTTP application";
      path = ./js-example-nestjs;
    };
    jsYarnNix = {
      description = "TypeScript + Lodash via mkYarnPackage";
      path = ./js-example-yarn-nix;
    };
    jsPython312OciImage = {
      description = "Python 3.12 OCI image via dockerTools";
      path = ./js-example-python312-oci-image;
    };
    jsNixFlakesDocker = {
      description = "Run nix-flakes Docker container";
      path = ./js-example-nix-flakes-docker;
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
//
nixStaticOciImageTemplates
//
binfmtTemplates
//
nixosTemplates
//
fastapiCeleryTemplates
//
qemuNixosTestTemplates
//
latexTemplates
//
pythonUv2nixTemplates
//
jsExampleTemplates
