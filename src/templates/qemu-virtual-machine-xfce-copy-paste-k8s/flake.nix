{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    allAttrs@{ self
    , nixpkgs
    , ...
    }:
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev;

        foo-bar = prev.hello;

      };
    } //
    allAttrs.flake-utils.lib.eachDefaultSystem
      (system:
      let
        name = "k8s-github-runner";

        pkgsAllowUnfree = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
          config = {
            allowUnfree = true;
          };
        };

        # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
        pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
          (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
      in
      rec {

        packages.vm = self.nixosConfigurations.vm.config.system.build.toplevel;

        /*
        # Utilized by `nix run .#<name>`

        rm -fv nixos.qcow2
        nix run --impure --refresh --verbose .#vm

        # Open the QMEU VM terminal and:
        start-github-runner-with-pat "$PAT"
        */
        apps.vm = {
          type = "app";
          program = "${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm";
        };

        # nix fmt
        formatter = pkgsAllowUnfree.nixpkgs-fmt;

        devShells.default = pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            coreutils
            curl
            jq
            patchelf
          ];

          shellHook = ''
            # TODO:
            export TMPDIR=/tmp

            test -d .profiles || mkdir -v .profiles

            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true

            test -L .profiles/dev-shell-default \
            || nix build --impure $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default

            test -L .profiles/nixosConfigurations."$system".vm.config.system.build.vm \
            || nix build --impure --out-link .profiles/nixosConfigurations."$system".vm.config.system.build.vm .#nixosConfigurations.vm.config.system.build.vm
          '';
        };
      })
    // {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        # About system and maybe --impure
        # https://www.youtube.com/watch?v=90aB_usqatE&t=3483s
        system = builtins.currentSystem;

        modules = [
          # export QEMU_NET_OPTS="hostfwd=tcp::2200-:10022" && nix run .#vm
          # Then connect with ssh -p 2200 nixuser@localhost
          # ps -p $(pgrep -f qemu-kvm) -o args | tr ' ' '\n'
          ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
            let
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExR+PSB/jBwJYKfpLN+MMXs3miRn70oELTV3sXdgzpr";
            in
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

                  virtualisation.useNixStoreImage = false; # TODO: hardening
                  virtualisation.writableStore = true; # TODO: hardening

                  virtualisation.docker.enable = true;

                  programs.dconf.enable = true;
                  # security.polkit.enable = true; # TODO: hardening?

                  virtualisation.memorySize = 1024 * 8; # Use MiB memory.
                  virtualisation.diskSize = 1024 * 50; # Use MiB memory.
                  virtualisation.cores = 8; # Number of cores.
                  virtualisation.graphics = true;

                  virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                  virtualisation.qemu.options = [
                    # Better display option
                    # TODO: -display sdl,gl=on
                    # https://gitlab.com/qemu-project/qemu/-/issues/761
                    "-vga virtio"
                    "-display gtk,zoom-to-fit=false"
                    # Enable copy/paste
                    # https://www.kraxel.org/blog/2021/05/qemu-cut-paste/
                    "-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on"
                    "-device virtio-serial-pci"
                    "-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0"

                    # https://serverfault.com/a/1119403
                    # "-device intel-iommu,intremap=on"

                    # "-net user,hostfwd=tcp::8090-::8080"
                  ];
                };

              users.users.root = {
                password = "root";
                initialPassword = "root";
                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "${toString nixuserKeys}" }"
                ];
              };

              # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
              users.extraGroups.nixgroup.gid = 999;

              security.sudo.wheelNeedsPassword = false; # TODO: hardening
              users.users.nixuser = {
                isSystemUser = true;
                password = "101"; # TODO: hardening
                createHome = true;
                home = "/home/nixuser";
                homeMode = "0700";
                description = "The VM tester user";
                group = "nixgroup";
                extraGroups = [
                  "docker"
                  "kubernetes"
                  "kvm"
                  "libvirtd"
                  "nixgroup"
                  "podman"
                  "qemu-libvirtd"
                  "root"
                  "wheel"
                ];
                packages = with pkgs; [
                  awscli
                  bashInteractive
                  btop
                  coreutils
                  direnv
                  file
                  firefox
                  gh
                  git
                  gnumake
                  kubernetes-helm
                  nix-info
                  openssh
                  openssl
                  starship
                  which
                  foo-bar

                ];
                shell = pkgs.zsh;
                uid = 1234;
                autoSubUidGidRange = true;

                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "${toString nixuserKeys}" }"
                ];

                openssh.authorizedKeys.keys = [
                  "${toString nixuserKeys}"
                ];
              };

              virtualisation.docker.enable = true;

              systemd.user.services.populate-history-vagrant = {
                script = ''
                  echo "Started"

                  DESTINATION=/home/nixuser/.zsh_history

                  # TODO: https://stackoverflow.com/a/67169387
                  echo "wk8s" >> "$DESTINATION"

                  echo "Ended"
                '';
                wantedBy = [ "default.target" ];
              };

              # https://github.com/NixOS/nixpkgs/blob/3a44e0112836b777b176870bb44155a2c1dbc226/nixos/modules/programs/zsh/oh-my-zsh.nix#L119
              # https://discourse.nixos.org/t/nix-completions-for-zsh/5532
              # https://github.com/NixOS/nixpkgs/blob/09aa1b23bb5f04dfc0ac306a379a464584fc8de7/nixos/modules/programs/zsh/zsh.nix#L230-L231
              programs.zsh = {
                enable = true;
                shellAliases = {
                  vim = "nvim";
                  k = "kubectl";
                  kaf = "kubectl apply -f";
                };
                enableCompletion = true;
                autosuggestions.enable = true;
                syntaxHighlighting.enable = true;
                interactiveShellInit = ''
                  export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
                  export ZSH_THEME="agnoster"
                  export ZSH_CUSTOM=${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions
                  plugins=(
                            colored-man-pages
                            docker
                            git
                            #zsh-autosuggestions # Why this causes an warn?
                            #zsh-syntax-highlighting
                          )

                  # https://nixos.wiki/wiki/Fzf
                  source $ZSH/oh-my-zsh.sh

                  export DIRENV_LOG_FORMAT=""
                  eval "$(direnv hook zsh)"

                  eval "$(starship init zsh)"

                  export FZF_BASE=$(fzf-share)
                  source "$(fzf-share)/completion.zsh"
                  source "$(fzf-share)/key-bindings.zsh"
                '';

                ohMyZsh.custom = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
                promptInit = "";
              };

              fonts = {
                fontDir.enable = true;
                fonts = with pkgs; [
                  powerline
                  powerline-fonts
                ];
                enableDefaultFonts = true;
                enableGhostscriptFonts = true;
              };

              # Hack to fix annoying zsh warning, too overkill probably
              # https://www.reddit.com/r/NixOS/comments/cg102t/how_to_run_a_shell_command_upon_startup/eudvtz1/?utm_source=reddit&utm_medium=web2x&context=3
              # https://stackoverflow.com/questions/638975/how-wdo-i-tell-if-a-regular-file-does-not-exist-in-bash#comment25226870_638985
              systemd.user.services.fix-zsh-warning = {
                script = ''
                  test -f /home/nixuser/.zshrc || touch /home/nixuser/.zshrc && chown nixuser: -Rv /home/nixuser
                '';
                wantedBy = [ "default.target" ];
              };

              # journalctl -u fix-k8s.service -b -f
              systemd.services.fix-k8s = {
                script = ''
                  echo "Fixing k8s"

                  CLUSTER_ADMIN_KEY_PATH=/var/lib/kubernetes/secrets/cluster-admin-key.pem

                  while ! test -f "$CLUSTER_ADMIN_KEY_PATH"; do echo $(date +'%d/%m/%Y %H:%M:%S:%3N'); sleep 0.5; done

                  chmod 0660 -v "$CLUSTER_ADMIN_KEY_PATH"
                  chown root:kubernetes -v "$CLUSTER_ADMIN_KEY_PATH"
                '';
                wantedBy = [ "multi-user.target" ];
              };

              # Enable ssh
              services.sshd.enable = true;

              # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
              services.openssh = {
                allowSFTP = true;
                kbdInteractiveAuthentication = false;
                enable = true;
                forwardX11 = false;
                passwordAuthentication = false;
                permitRootLogin = "yes";
                ports = [ 10022 ];
                authorizedKeysFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "${toString nixuserKeys}" }"
                ];
              };

              # https://nixos.wiki/wiki/Libvirt
              # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
              boot.extraModprobeConfig = "options kvm_intel nested=1";

              services.qemuGuest.enable = true;

              # X configuration
              services.xserver.enable = true;
              services.xserver.layout = "br";

              services.xserver.displayManager.autoLogin.user = "nixuser";
              services.xserver.displayManager.sessionCommands = ''
                exo-open \
                  --launch TerminalEmulator \
                  --zoom=-3 \
                  --geometry 154x40
              '';

              # https://nixos.org/manual/nixos/stable/#sec-xfce
              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;

              services.xserver.videoDrivers = [ "qxl" ];

              # For copy/paste to work
              services.spice-vdagentd.enable = true;

              # nixpkgs.config.allowUnfree = true;

              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                package = pkgs.nixVersions.nix_2_10;
                readOnlyStore = true;
                registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
                nixPath = [ "nixpkgs=${pkgs.path}" ];
              };

              environment.etc."channels/nixpkgs".source = "${pkgs.path}";

              environment.systemPackages = with pkgs; [
                bashInteractive
                openssh

                direnv
                fzf
                jq
                neovim
                nix-direnv
                nixos-option
                oh-my-zsh
                xclip
                zsh
                zsh-autosuggestions
                zsh-completions
                firefox
                which

                # Looks like kubernetes needs at least all this
                kubectl
                kubernetes
                #
                cni
                cni-plugins
                conntrack-tools
                cri-o
                cri-tools
                ebtables
                ethtool
                flannel
                iptables
                socat

                (
                  writeScriptBin "fix-k8s-cluster-admin-key" ''
                    #! ${pkgs.runtimeShell} -e
                    sudo chmod 0660 -v /var/lib/kubernetes/secrets/cluster-admin-key.pem
                    sudo chown root:kubernetes -v /var/lib/kubernetes/secrets/cluster-admin-key.pem
                  ''
                )

                (
                  writeScriptBin "wk8s" ''
                    #! ${pkgs.runtimeShell} -e
                        while true; do
                          kubectl get pod --all-namespaces -o wide \
                          && echo \
                          && kubectl get services --all-namespaces -o wide \
                          && echo \
                          && kubectl get deployments.apps --all-namespaces -o wide \
                          && echo \
                          && kubectl get nodes --all-namespaces -o wide;
                          sleep 1;
                          clear;
                        done
                  ''
                )
              ];

              # Is this a must to kubernetes?
              swapDevices = pkgs.lib.mkForce [ ];

              # Is it a must for k8s?
              # Take a look into:
              # https://github.com/NixOS/nixpkgs/blob/9559834db0df7bb274062121cf5696b46e31bc8c/nixos/modules/services/cluster/kubernetes/kubelet.nix#L255-L259
              boot.kernel.sysctl = {
                # If it is enabled it conflicts with what kubelet is doing
                # "net.bridge.bridge-nf-call-ip6tables" = 1;
                # "net.bridge.bridge-nf-call-iptables" = 1;

                # https://docs.projectcalico.org/v3.9/getting-started/kubernetes/installation/migration-from-flannel
                # https://access.redhat.com/solutions/53031
                "net.ipv4.conf.all.rp_filter" = 1;
                # https://www.tenable.com/audits/items/CIS_Debian_Linux_8_Server_v2.0.2_L1.audit:bb0f399418f537997c2b44741f2cd634
                # "net.ipv4.conf.default.rp_filter" = 1;
                "vm.swappiness" = 0;
              };

              environment.variables.KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";

              # services.kubernetes.kubelet.seedDockerImages = [
              #   (pkgs.dockerTools.pullImage {
              #     name = "ghcr.io/actions";
              #     imageName = "actions-runner:2.311.0";
              #     # tag = "2.311.0";
              #     sha256 = "sha256-BVnOXiYRUg3ukjYJBYbazOfrIrzQt7aRB2LWPf1b+ZE=";
              #     # podman inspect docker.io/sickcodes/docker-osx:latest | jq ".[].Digest"
              #     # imageDigest = "sha256:e505724e0dbb070454912b159645932f74dda9aed03c48c463f33e270a6cbfa1";
              #     imageDigest = "";
              #   })
              # ];
              # docker pull ghcr.io/actions/actions-runner:2.311.0
              # docker inspect docker.io/sickcodes/docker-osx:latest | jq ".[].Digest"
              # dockerTools.examples.redis
              services.kubernetes.roles = [ "master" "node" ];
              services.kubernetes.masterAddress = "nixos";
              services.kubernetes = {
                flannel.enable = true;
              };

              # TODO: refatorar, talvez usar self?
              environment.etc."kubernets/kubernetes-examples/minimal-pod-with-busybox-example/minimal-pod-with-busybox-example.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/minimal-pod-with-busybox-example/minimal-pod-with-busybox-example.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/minimal-pod-with-busybox-example/notes.md" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/minimal-pod-with-busybox-example/notes.md}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/deployment.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/deployment.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/service.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/service.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/ingress.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/ingress.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/notes.md" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/notes.md}";
              };

              # journalctl -u move-kubernetes-examples.service -b
              systemd.services.move-kubernetes-examples = {
                script = ''
                  echo "Started move-kubernets-examples"

                  # cp -rv ''\${./kubernetes-examples} /home/nixuser/
                  cp -Rv /etc/kubernets/kubernetes-examples/ /home/nixuser/

                  chown -Rv nixuser:nixgroup /home/nixuser/kubernetes-examples

                  kubectl \
                    apply \
                    --file /home/nixuser/kubernetes-examples/deployment.yaml \
                    --file /home/nixuser/kubernetes-examples/service.yaml \
                    --file /home/nixuser/kubernetes-examples/ingress.yaml
                '';
                wantedBy = [ "multi-user.target" ];
              };

              # journalctl --user --unit create-custom-desktop-icons.service -b -f
              systemd.user.services.create-custom-desktop-icons = {
                script = ''
                  #! ${pkgs.runtimeShell} -e

                  echo "Started"

                  ln \
                    -sfv \
                    "${pkgs.xfce.xfce4-settings}"/share/applications/xfce4-terminal-emulator.desktop \
                    /home/nixuser/Desktop/xfce4-terminal-emulator.desktop

                  ln \
                    -sfv \
                    "${pkgs.firefox}"/share/applications/firefox.desktop \
                    /home/nixuser/Desktop/firefox.desktop

                  echo "Ended"
                '';
                wantedBy = [ "xfce4-notifyd.service" ];
              };

              # https://discourse.nixos.org/t/nixos-firewall-with-kubernetes/23673/2
              # networking.firewall.trustedInterfaces ??
              # networking.firewall.allowedTCPPorts = [ 80 8000 8080 8443 9000 9443 ];
              networking.firewall.enable = false; # TODO: hardening

              environment.etc."containers/registries.conf" = {
                mode = "0644";
                text = ''
                  [registries.search]
                  registries = ['docker.io', 'localhost', 'us-docker.pkg.dev', 'gcr.io']
                '';
              };

              boot.kernelParams = [
                "swapaccount=0"
                "systemd.unified_cgroup_hierarchy=0"
                "group_enable=memory"
                "cgroup_enable=cpuset"
                "cgroup_memory=1"
                "cgroup_enable=memory"
              ];

              system.stateVersion = "22.11";
            })

          { nixpkgs.overlays = [ self.overlays.default ]; }

        ];

        specialArgs = { inherit nixpkgs allAttrs; };

      };
    };
}
