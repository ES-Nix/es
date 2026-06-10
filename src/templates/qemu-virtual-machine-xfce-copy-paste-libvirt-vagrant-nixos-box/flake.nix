{
  description = "NixOS flake: QEMU/XFCE/SPICE VM, KVM, Libvirt Vagrant NixOS box, single-node Kubernetes; e2e tested with
 testers.runNixOSTest (nested KVM)";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/29e290002bfff26af1db6f64d070698019460302' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'  
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        nixosVagrantBoxDisk =
          let
            system = prev.stdenv.hostPlatform.system;
            isAarch64 = prev.stdenv.hostPlatform.isAarch64;
            guestSystem = nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                "${nixpkgs}/nixos/modules/virtualisation/vagrant-guest.nix"
                (if isAarch64 then {
                  system.stateVersion = "25.05";
                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = false;
                  boot.loader.efi.efiSysMountPoint = "/boot";
                  fileSystems."/" = { device = "/dev/vda2"; fsType = "ext4"; };
                  fileSystems."/boot" = { device = "/dev/vda1"; fsType = "vfat"; };
                  documentation.enable = false;
                  nix.enable = false;
                  services.udisks2.enable = false;
                  boot.kernelParams = [ "console=ttyAMA0" "console=tty0" ];
                } else {
                  system.stateVersion = "25.05";
                  boot.loader.grub.enable = true;
                  boot.loader.grub.device = "/dev/vda";
                  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
                  documentation.enable = false;
                  nix.enable = false;
                  services.udisks2.enable = false;
                  boot.kernelParams = [ "console=ttyS0" "console=tty0" ];
                })
              ];
            };
          in
          import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
            pkgs = nixpkgs.legacyPackages.${system};
            lib = nixpkgs.lib;
            inherit (guestSystem) config;
            diskSize = "auto";
            additionalSpace = "512M";
            format = "qcow2";
            partitionTableType = if isAarch64 then "efi" else "legacy";
            name = "nixos-vagrant-libvirt";
            baseName = "nixos-vagrant-libvirt";
            touchEFIVars = isAarch64;
          };

        nixosVagrantBox = prev.runCommand "nixos-vagrant-libvirt.box"
          {
            nativeBuildInputs = [ prev.gnutar ];
            meta.boxName = "local/nixos";
          } ''
          mkdir workdir && cd workdir
          cp ${final.nixosVagrantBoxDisk}/*.qcow2 box.img
          printf '{"provider":"libvirt","format":"qcow2","virtual_size":20}' > metadata.json
          printf 'Vagrant.configure("2") do |config|\nend\n' > Vagrantfile
          tar --owner=0 --group=0 --sort=name --numeric-owner -czf $out .
        '';

        vagrantfileNixOSMinimal =
          let
            isAarch64 = prev.stdenv.hostPlatform.isAarch64;
          in
          if isAarch64 then
            prev.writeText "vagrantfile-nixos-minimal" ''
              Vagrant.configure("2") do |config|
                config.vm.box = "local/nixos"
                config.ssh.extra_args = ["-F", "/dev/null"]
                config.vm.provider :libvirt do |v|
                  v.cpus = 1
                  v.memory = "1024"
                  v.machine_type = "virt"
                  v.machine_arch = "aarch64"
                  v.features = []
                  v.inputs = [{ type: "keyboard", bus: "virtio" }]
                  v.video_type = "virtio"
                  v.cpu_mode = "host-passthrough"
                  v.driver = "kvm"
                  v.uri = "qemu:///system"
                  v.loader = "${prev.OVMF.firmware}"
                  v.nvram = "${prev.OVMF.variables}"
                end
                config.vm.provision "shell", inline: <<-SHELL
                  echo "Hello from minimal NixOS"
                  cat /etc/os-release
                SHELL
              end
            ''
          else
            prev.writeText "vagrantfile-nixos-minimal" ''
              Vagrant.configure("2") do |config|
                config.vm.box = "local/nixos"
                config.ssh.extra_args = ["-F", "/dev/null"]
                config.vm.provider :libvirt do |v|
                  v.cpus = 1
                  v.memory = "1024"
                  v.cpu_mode = "host-passthrough"
                  v.driver = "kvm"
                  v.uri = "qemu:///system"
                end
                config.vm.provision "shell", inline: <<-SHELL
                  echo "Hello from minimal NixOS"
                  cat /etc/os-release
                SHELL
              end
            '';

        prepareVagrantVms = prev.writeScriptBin "prepare-vagrant-vms" ''
          #! ${prev.runtimeShell} -e
          for i in {0..100}; do
            echo "iteration $i: $(date +'%d/%m/%Y %H:%M:%S:%3N')"
            vagrant box list
            if (vagrant box list | grep -q nixos); then
              break
            fi
          done;
        '';

        testVagrantWithNixOS = prev.testers.runNixOSTest {
          name = "test-vagrant-libvirt-nixos";
          nodes.machineWithVagrant =
            { config, pkgs, lib, modulesPath, ... }:
            {
              config.environment.systemPackages = with final; [
                prepareVagrantVms
                vagrant
              ];
              config.virtualisation.libvirtd.enable = true;
              config.virtualisation.memorySize = 4096;
              config.virtualisation.diskSize = 8 * 1024;
              config.virtualisation.cores = 4;
              config.virtualisation.qemu.options = [ "-enable-kvm" "-cpu" "host" ];
              config.environment.variables = {
                VAGRANT_DEFAULT_PROVIDER = "libvirt";
              };

              config.systemd.services.copy-nixos-vagrant = {
                serviceConfig.Type = "oneshot";
                serviceConfig.RemainAfterExit = true;
                environment.HOME = "/root";
                path = with pkgs; [
                  curl
                  file
                  gnutar
                  gzip
                  openssh
                  procps
                  vagrant
                  xz
                ];
                script = ''
                  #! ${pkgs.runtimeShell} -e
                    echo $VAGRANT_DEFAULT_PROVIDER
                    id \
                    && BASE_DIR=/root/vagrant-examples/libvirt \
                    && mkdir -pv "$BASE_DIR"/nixos \
                    && cd "$BASE_DIR" \
                    && cp -v "${pkgs.vagrantfileNixOSMinimal}" nixos/Vagrantfile \
                    && PROVIDER=libvirt \
                    && vagrant box list --no-color --no-tty \
                    && vagrant \
                        box \
                        add \
                        "${pkgs.nixosVagrantBox.meta.boxName}" \
                        "${pkgs.nixosVagrantBox}" \
                        --force \
                        --provider $PROVIDER \
                        --no-color --no-tty \
                    && vagrant box list \
                    && echo done-copy-nixos-vagrant
                '';
                after = [ "libvirtd.service" "network.target" ];
                wantedBy = [ "default.target" ];
              };
            };

          globalTimeout = 25 * 60;

          testScript = ''
            start_all()
            machineWithVagrant.wait_for_unit("multi-user.target")
            machineWithVagrant.wait_for_unit("copy-nixos-vagrant")

            machineWithVagrant.succeed("type prepare-vagrant-vms")
            machineWithVagrant.succeed("type vagrant")
            machineWithVagrant.succeed("test -d /tmp")
            machineWithVagrant.succeed("id >&2")
            print(machineWithVagrant.succeed("env | sort"))

            assert 'libvirt' in machineWithVagrant.succeed("echo $VAGRANT_DEFAULT_PROVIDER"), \
              "VAGRANT_DEFAULT_PROVIDER is not 'libvirt'"
            machineWithVagrant.succeed("systemctl is-enabled libvirtd.service >&2")

            machineWithVagrant.succeed("journalctl --unit libvirtd.service --boot --no-pager >&2")
            machineWithVagrant.succeed("""
              journalctl --unit copy-nixos-vagrant.service --boot --no-pager >&2
            """)

            machineWithVagrant.succeed("vagrant box list | grep -q nixos")
            machineWithVagrant.succeed("vagrant box list >&2")

            kvm_rc, _ = machineWithVagrant.execute("test -c /dev/kvm")
            if kvm_rc == 0:
              machineWithVagrant.succeed(
                "cd /root/vagrant-examples/libvirt/nixos && vagrant up --no-tty 2>&1",
                timeout=900
              )
              result = machineWithVagrant.succeed(
                "cd /root/vagrant-examples/libvirt/nixos && vagrant ssh -c 'cat /etc/os-release' 2>/dev/null",
                timeout=120
              )
              print(result)
              assert 'NixOS' in result, f"Expected NixOS, got: {result!r}"
            else:
              print("Nested KVM not available; vagrant up/ssh test skipped")
          '';
        };

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = prev.stdenv.hostPlatform.system;
          modules = [
            ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
              {
                # Internationalisation options
                i18n.defaultLocale = "en_US.UTF-8";
                console.keyMap = "br-abnt2";

                # Set your time zone.
                time.timeZone = "America/Recife";

                # Why
                # nix flake show --impure .#
                # break if it does not exists?
                # Use systemd boot (EFI only)
                boot.loader.systemd-boot.enable = true;
                fileSystems."/" = { device = "/dev/hda1"; };

                virtualisation.vmVariant =
                  {
                    virtualisation.docker.enable = true;
                    virtualisation.podman.enable = true;

                    virtualisation.memorySize = 1024 * 9; # Use MiB memory.
                    virtualisation.diskSize = 1024 * 28; # Use MiB memory.
                    virtualisation.cores = 7; # Number of cores.
                    virtualisation.graphics = true;

                    virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                    virtualisation.qemu.options = [
                      # https://www.spice-space.org/spice-user-manual.html#Running_qemu_manually
                      # remote-viewer spice://localhost:3001

                      # "-daemonize" # How to save the QEMU PID?
                      "-machine vmport=off"
                      "-vga qxl"
                      "-spice port=3001,disable-ticketing=on"
                      "-device virtio-serial"
                      "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                      "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                    ];

                    virtualisation.useNixStoreImage = false; # TODO: hardening
                    virtualisation.writableStore = false; # TODO: hardening
                    # virtualisation.useBootLoader = true; # TODO: hardening
                  };

                security.sudo.wheelNeedsPassword = true; # TODO: hardening
                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 1000;
                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1"; # TODO: hardening
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "kvm"
                    "libvirtd"
                    "nixgroup"
                    "podman"
                    "qemu-libvirtd"
                    "root"
                    "vboxsf"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    file
                    firefox
                    git
                    jq
                    lsof
                    findutils
                    xdotool
                    vagrant
                    fooBar
                  ];
                  shell = pkgs.bash;
                  uid = 1000;
                  autoSubUidGidRange = true;
                };

                services.xserver.enable = true;
                services.xserver.xkb.layout = "br";
                services.displayManager.autoLogin.user = "nixuser";

                # https://nixos.org/manual/nixos/stable/#sec-xfce
                services.xserver.desktopManager.xfce.enable = true;
                services.xserver.desktopManager.xfce.enableScreensaver = false;
                services.xserver.videoDrivers = [ "qxl" ];
                services.spice-vdagentd.enable = true; # For copy/paste to work

                virtualisation.libvirtd.enable = true;
                # virtualisation.services.libvirtd.serviceOverrides = { PrivateUsers="no"; };

                # boot.nixStoreMountOpts = [ "rw" ]; # TODO: What may be missing?
                nix.extraOptions = "experimental-features = nix-command flakes";
                nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
                  "vagrant"
                ];

                programs.dconf.enable = true;

                environment.variables.VAGRANT_DEFAULT_PROVIDER = "libvirt";

                # displayManager.job.logToJournal
                # journalctl -t xsession -b -f
                # journalctl -u display-manager.service -b
                # https://askubuntu.com/a/1434433
                services.xserver.displayManager.sessionCommands = ''
                  exo-open \
                    --launch TerminalEmulator \
                    --zoom=-3 \
                    --geometry 154x40

                  for i in {1..100}; do
                    xdotool getactivewindow
                    $? && break
                    sleep 0.1
                  done
                  # Race condition. Why?
                  # sleep 3
                  xdotool type nixos-version \
                  && xdotool key Return
                '';

                environment.systemPackages = with pkgs; [
                  vagrant
                ];

                system.stateVersion = "25.11";
              })

            { nixpkgs.overlays = [ self.overlays.default ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvm = final.nixos-vm.config.system.build.vm;

        coreDNSImageOverlay = final: prev: {
          dockerTools = prev.dockerTools // {
            pullImage = args:
              if (args ? imageName) && args.imageName == "coredns/coredns" then
                prev.dockerTools.buildLayeredImage {
                  name = args.imageName;
                  tag = args.finalImageTag or "latest";
                  contents = prev.buildEnv {
                    name = "coredns-env";
                    paths = [ prev.coredns ];
                    pathsToLink = [ "/bin" ];
                  };
                  config.Entrypoint = [ "/bin/coredns" ];
                }
              else
                prev.dockerTools.pullImage args;
          };
        };

        nixos-vm-k8s = nixpkgs.lib.nixosSystem {
          system = prev.stdenv.hostPlatform.system;
          modules = [
            ({ config, pkgs, lib, ... }: {
              i18n.defaultLocale = "en_US.UTF-8";
              time.timeZone = "America/Recife";
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/hda1"; };

              services.kubernetes.roles = [ "master" "node" ];
              services.kubernetes.masterAddress = config.networking.hostName;
              environment.variables.KUBECONFIG =
                "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}";
              # services.kubernetes.kubelet.extraOpts = "--fail-swap-on=false";

              virtualisation.vmVariant = {
                virtualisation.memorySize = 1024 * 8;
                virtualisation.diskSize = 1024 * 20;
                virtualisation.cores = 4;
                virtualisation.graphics = false;
              };

              environment.systemPackages = with pkgs; [ kubectl ];
              system.stateVersion = "25.11";
            })
            { nixpkgs.overlays = [ self.overlays.default final.coreDNSImageOverlay ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvmK8s = final.nixos-vm-k8s.config.system.build.vm;

        # runNixOSTest sets nixpkgs.pkgs (via defaults.nixpkgs.pkgs), which makes
        # nixpkgs.overlays read-only inside the test nodes — so we can't set it
        # there. Instead, extend pkgs before passing it to runNixOSTest so the
        # coreDNSImageOverlay is already baked into the pkgs the test uses.
        testK8s = (prev.extend final.coreDNSImageOverlay).testers.runNixOSTest {
          name = "test-nixos-k8s";
          nodes.machine = { config, pkgs, lib, ... }: {
            services.kubernetes.roles = [ "master" "node" ];
            services.kubernetes.masterAddress = config.networking.hostName;
            environment.variables.KUBECONFIG =
              "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}";
            # services.kubernetes.kubelet.extraOpts = "--fail-swap-on=false";

            virtualisation.memorySize = 1024 * 4;
            virtualisation.cores = 8;
            virtualisation.qemu.options = [ "-enable-kvm" "-cpu" "host" ];

            environment.systemPackages = with pkgs; [ kubectl ];
          };

          globalTimeout = 15 * 60;

          testScript = ''
            start_all()
            machine.wait_for_unit("multi-user.target")
            machine.wait_for_unit("kube-apiserver.service", timeout=300)
            machine.wait_for_unit("kubelet.service",        timeout=300)
            machine.succeed("id >&2")
            machine.succeed(
              "kubectl get pod --all-namespaces -o wide >&2",
              timeout=120
            )
          '';
        };

        automaticVm = prev.writeShellApplication {
          name = "run-nixos-vm";
          runtimeInputs = with final; [ curl virt-viewer myvm ];
          /*
              Pode ocorrer uma condição de corrida de seguinte forma:
              a VM inicializa (o processo não é bloqueante, executa em background)
              o spice/VNC interno a VM inicializa
              o remote-viewer tenta conectar, mas o spice não está pronto ainda

              TODO: idealmente não deveria ser preciso ter mais uma dependência (o curl)
                    para poder sincronizar o cliente e o server. Será que no caso de
                    ambos estarem na mesma máquina seria melhor usar virt-viewer -fw?
              https://unix.stackexchange.com/a/698488
            */
          text = ''
            # https://unix.stackexchange.com/a/230442
            # export NO_AT_BRIDGE=1
            # https://gist.github.com/eoli3n/93111f23dbb1233f2f00f460663f99e2#file-rootless-podman-wayland-sh-L25
            # export LD_LIBRARY_PATH="${prev.libcanberra-gtk3}"/lib/gtk-3.0/modules

            ${final.lib.getExe final.myvm} & PID_QEMU="$!"
              
            export VNC_PORT=3001

            for _ in {0..100}; do
              if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
              then
                break
              fi
              # date +'%d/%m/%Y %H:%M:%S:%3N'
              sleep 0.1
            done;

            remote-viewer spice://localhost:"$VNC_PORT"

            kill $PID_QEMU
          '';
        };

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

      })
    ];
  } // (
    let
      # nix flake show --allow-import-from-derivation --impure --refresh .#
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];
    in
    flake-utils.lib.eachSystem suportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "vagrant"
          ];
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            automaticVm
            myvm
            myvmK8s
            nixosVagrantBox
            testK8s
            testVagrantWithNixOS
            ;
          default = pkgs.automaticVm;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
          default = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.automaticVm}";
            meta.description = "Run the NixOS VM";
          };
          k8s-vm = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.myvmK8s}";
            meta.description = "Run the NixOS K8s VM";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            automaticVm
            testK8s
            testVagrantWithNixOS
            ;
          default = pkgs.automaticVm;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            automaticVm
            testK8s
            testVagrantWithNixOS
          ];
          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true             
          '';
        };
      }
    )
  );
}
