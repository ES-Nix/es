{
  description = "Este é nix flake para executar localmente GitHub Actions Runners em máquina virtual NixOS via systemd";

  /*
    nix \
    flake \
    update \
    --override-input nixpkgs github:NixOS/nixpkgs/c1be43e8e837b8dbee2b3665a007e761680f0c3d \
    --override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/72841a4a8761d1aed92ef6169a636872c986c76d' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    # sops-nix.url = "github:Mic92/sops-nix";
    # sops-nix.inputs.nixpkgs.follows = "nixpkgs";
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
    (
      let
        # nix flake show --allow-import-from-derivation --impure --refresh .#
        suportedSystems = [
          "x86_64-linux"
          "aarch64-linux"
          # "aarch64-darwin"
        ];

      in
      allAttrs.flake-utils.lib.eachSystem suportedSystems
        (system:
        let
          name = "github-ci-runner";

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

          packages.default = packages.automatic-vm;
          packages.automatic-vm = pkgsAllowUnfree.writeShellApplication {
            name = "run-nixos-vm";
            runtimeInputs = with pkgsAllowUnfree; [ curl virt-viewer ];
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
              ${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm & PID_QEMU="$!"

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

          apps.default = {
            type = "app";
            program = "${self.packages."${system}".automatic-vm}/bin/run-nixos-vm";
          };

          # nix fmt
          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              age
              bashInteractive
              coreutils
              curl
              gettext
              gh
              gnumake
              httpie
              jq
              patchelf
              sops
              ssh-to-age
              virt-viewer
            ];

            shellHook = ''
              export TMPDIR=/tmp

              export HOSTNAME=$(hostname)

              echo "Entering the nix devShell no github-ci-runner"

              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop .# --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default

              test -L .profiles/nixosConfigurations."$system".vm.config.system.build.vm \
              || nix build --impure --out-link .profiles/nixosConfigurations."$system".vm.config.system.build.vm .#nixosConfigurations.vm.config.system.build.vm

              # For SOPS
              # test -d ~/.config/sops/age || mkdir -pv ~/.config/sops/age
              # test -f ~/.config/sops/age/keys.txt || age-keygen -o ~/.config/sops/age/keys.txt
              # https://github.com/getsops/sops/pull/860/files#diff-7b3ed02bc73dc06b7db906cf97aa91dec2b2eb21f2d92bc5caa761df5bbc168fR192
              # test -d secrets || mkdir -v secrets
              # test -f secrets/secrets.yaml.encrypted \
              # || sops \
              # --encrypt \
              # --age $(age-keygen -y ~/.config/sops/age/keys.txt) \
              # secrets/secrets.yaml > secrets/secrets.yaml.encrypted
            '';
          };
        })
    )
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

              GH_HOSTNAME = builtins.getEnv "HOSTNAME";
              GH_TOKEN = builtins.getEnv "GH_TOKEN";
            in
            {
              # Internationalisation options
              i18n.defaultLocale = "en_US.UTF-8";
              # i18n.defaultLocale = "pt_BR.UTF-8";
              console.keyMap = "br-abnt2";

              # Set your time zone.
              time.timeZone = "America/Recife";

              # Why
              # nix flake show --impure .#
              # breaks if it does not exists?
              # Use systemd boot (EFI only)
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/hda1"; };

              virtualisation.vmVariant =
                {

                  virtualisation.useNixStoreImage = false; # TODO: hardening
                  virtualisation.writableStore = true; # TODO: hardening

                  virtualisation.docker.enable = true;
                  virtualisation.podman = {
                    enable = true;
                    dockerCompat = false;
                    dockerSocket.enable = false;
                  };
                  # virtualisation.oci-containers.backend = "podman";

                  #  users = {
                  #    groups.podman = { gid = 31000; };
                  #    users.podman = {
                  #      isSystemUser = true;
                  #      uid = 31000;
                  #      linger = true;
                  #      group = "podman";
                  #      home = "/home/podman";
                  #      createHome = true;
                  #      subUidRanges = [{ count = 65536; startUid = 615536; }];
                  #      subGidRanges = [{ count = 65536; startGid = 615536; }];
                  #    };
                  #  };

                  programs.dconf.enable = true;
                  # security.polkit.enable = true; # TODO: hardening?

                  virtualisation.memorySize = 1024 * 3; # Use MiB memory.
                  virtualisation.diskSize = 1024 * 25; # Use MiB memory.
                  virtualisation.cores = 3; # Number of cores.
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
                };

              users.users.root = {
                password = "root";
                # initialPassword = "root";
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
                  foo-bar
                  gh
                  git
                  gnumake
                  nix-info
                  openssh
                  openssl
                  starship
                  sudo
                  which
                  xdotool
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

              /*
                https://github.com/NixOS/nixpkgs/issues/169812
                https://github.com/actions/runner/issues/1882#issuecomment-1427930611

                nix shell nixpkgs#github-runner --command \
                sh \
                -c \
                'config.sh --url https://github.com/ORG/REPO --pat "$PAT" --ephemeral && run.sh'

                TODO: https://www.youtube.com/watch?v=G5f6GC7SnhU
              */

              services.github-runners = {
                runner1 = {
                  enable = true;
                  ephemeral = true;
                  extraLabels = [ "nixos" ];
                  # extraPackages = config.environment.systemPackages;
                  extraPackages = with pkgs; [ iputils which podman python39 sudo ];
                  name = "${GH_HOSTNAME}";
                  replace = true;
                  # runnerGroup = "nixgroup"; # Apenas administradores da organização do github conseguem usar isso?
                  tokenFile = "/run/secrets/github-runner/nixos.token";
                  url = "https://github.com/ES-Nix/es";
                  user = "nixuser";
                };
              };

              systemd.services.github-runners-runner1.path = [ "/run/wrappers" "/run/current-system/sw/bin" ]; # https://discourse.nixos.org/t/podman-rootless-with-systemd/23536/6

              # systemd.user.extraConfig = ''
              #   DefaultEnvironment="PATH=/run/wrappers/bin:/run/current-system/sw/bin:/home/nixuser/.nix-profile/bin"
              # '';

              # systemd.services.github-runners-runner1.path = [
              #   # https://stackoverflow.com/a/70964228
              #   # https://discourse.nixos.org/t/sudo-run-current-system-sw-bin-sudo-must-be-owned-by-uid-0-and-have-the-setuid-bit-set-and-cannot-chdir-var-cron-bailing-out-var-cron-permission-denied/20463/11
              #   "/run/current-system/sw/bin"
              #   "/run/wrappers/bin"
              # ];

              services.github-runners.runner1.serviceOverrides = {
                ReadWritePaths = [
                  "/nix"
                  # "/nix/var/nix/profiles/per-user/" # https://github.com/cachix/cachix-ci-agents/blob/63f3f600d13cd7688e1b5db8ce038b686a5d29da/agents/linux.nix#L30C26-L30C59
                ];

                # BindPaths = [ "/proc:/proc:rbind" ]; # TODO: A/B teste!
                BindPaths = [
                  "/proc"
                ];

                IPAddressAllow = [ "0.0.0.0/0" "::/0" ]; # https://github.com/skogsbrus/os/blob/cced4b4dfc60d03168a2bf0ad5e4ca901c732136/sys/caddy.nix#L161
                IPAddressDeny = [ ];
                # Environment = [
                #   "HOME=/var/lib/caddy"
                # ];
                # ExecStart = lib.mkForce "echo Hi, %u";
                ProtectControlGroups = false;
                # PrivateTmp = false;
                PrivateUsers = false;
                RestrictNamespaces = false;
                DynamicUser = false; # TODO: A/B teste!
                PrivateDevices = false;
                PrivateMounts = false;
                ProtectHome = "no";
                ProtectSystem = "no"; # TODO: A/B teste!
                ProtectHostname = false; # TODO: hardening, precisamos disso? Talvez nix buils precise!
                # RemoveIPC = false;
                MemoryDenyWriteExecute = "no"; # TODO: A/B teste!
                PrivateNetwork = false; # https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#PrivateNetwork= TODO: hardening https://github.com/NixOS/nixpkgs/pull/259056/files#diff-e70037b1f30ecb052931d6b896b8236a67d5ca92dbc8b2057d4f41a8bb70a7a4R308
                RestrictRealtime = false;
                # ProtectKernelLogs = false;
                # ProtectKernelModules = false;
                ProtectKernelTunables = false; # TODO: A/B teste!
                ProtectProc = "default"; # https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#ProtectProc=
                # ProtectProc = "invisible"; # TODO: A/B teste!
                # ProtectProc = "ptraceable"; # TODO: A/B teste!
                SocketBindAllow = "any"; # TODO: A/B teste!
                SystemCallArchitectures = ""; # TODO: A/B teste!

                # https://www.redhat.com/sysadmin/mastering-systemd
                # https://unix.stackexchange.com/a/581337
                # https://man7.org/linux/man-pages/man7/capabilities.7.html
                # https://medium.com/@maros.kukan/advanced-containers-with-podman-f79302de85b0
                # https://linuxconfig.org/how-to-increase-the-security-of-systemd-services
                # https://unix.stackexchange.com/a/639604
                # https://nixos.wiki/wiki/Systemd_Hardening
                # TODO: https://discourse.nixos.org/t/nginx-worker-processes-exit-with-signal-31-when-running-via-systemd/13471/7

                # TODO: https://github.com/serokell/serokell.nix/blob/bfd859fcb96aa912f4ca05b4afe4082114ca9ec7/lib/systemd/profiles.nix#L5
                # https://github.com/containers/podman/issues/4618
                # https://manpages.debian.org/bullseye/manpages/capabilities.7.en.html#CAP_SYS_ADMIN
                # https://docs.arbitrary.ch/security/systemd.html
                # https://github.com/restic/rest-server/issues/148
                # https://discussion.fedoraproject.org/t/f40-change-proposal-systemd-security-hardening-system-wide/96423
                AmbientCapabilities = [
                  "CAP_AUDIT_CONTROL"
                  "CAP_AUDIT_WRITE"
                  "CAP_BLOCK_SUSPEN"
                  "CAP_CHOWN"
                  "CAP_DAC_OVERRIDE"
                  "CAP_DAC_READ_SEARCH"
                  "CAP_FOWNER"
                  "CAP_FSETID"
                  "CAP_IPC_LOCK"
                  "CAP_IPC_OWNER"
                  "CAP_KILL"
                  "CAP_LEASE"
                  "CAP_LINUX_IMMUTABLE"
                  "CAP_MAC_ADMIN"
                  "CAP_MAC_OVERRIDE"
                  "CAP_MKNOD"
                  "CAP_NET_ADMIN"
                  "CAP_NET_BIND_SERVICE"
                  "CAP_NET_BROADCAST"
                  "CAP_NET_RAW"
                  "CAP_SETFCAP"
                  "CAP_SETGID"
                  "CAP_SETPCAP"
                  "CAP_SETUID"
                  "CAP_SYSLOG"
                  "CAP_SYS_ADMIN"
                  "CAP_SYS_BOOT"
                  "CAP_SYS_CHROOT"
                  "CAP_SYS_MODULE"
                  "CAP_SYS_NICE"
                  "CAP_SYS_PACCT"
                  "CAP_SYS_PTRACE"
                  "CAP_SYS_RAWIO"
                  "CAP_SYS_RESOURCE"
                  "CAP_SYS_TIME"
                  "CAP_SYS_TTY_CONFIG"
                  "CAP_WAKE_ALARM"
                ];
                CapabilityBoundingSet = [
                  "CAP_AUDIT_CONTROL"
                  "CAP_AUDIT_WRITE"
                  "CAP_BLOCK_SUSPEN"
                  "CAP_CHOWN"
                  "CAP_DAC_OVERRIDE"
                  "CAP_DAC_READ_SEARCH"
                  "CAP_FOWNER"
                  "CAP_FSETID"
                  "CAP_IPC_LOCK"
                  "CAP_IPC_OWNER"
                  "CAP_KILL"
                  "CAP_LEASE"
                  "CAP_LINUX_IMMUTABLE"
                  "CAP_MAC_ADMIN"
                  "CAP_MAC_OVERRIDE"
                  "CAP_MKNOD"
                  "CAP_NET_ADMIN"
                  "CAP_NET_BIND_SERVICE"
                  "CAP_NET_BROADCAST"
                  "CAP_NET_RAW"
                  "CAP_SETFCAP"
                  "CAP_SETGID"
                  "CAP_SETPCAP"
                  "CAP_SETUID"
                  "CAP_SYSLOG"
                  "CAP_SYS_ADMIN"
                  "CAP_SYS_BOOT"
                  "CAP_SYS_CHROOT"
                  "CAP_SYS_MODULE"
                  "CAP_SYS_NICE"
                  "CAP_SYS_PACCT"
                  "CAP_SYS_PTRACE"
                  "CAP_SYS_RAWIO"
                  "CAP_SYS_RESOURCE"
                  "CAP_SYS_TIME"
                  "CAP_SYS_TTY_CONFIG"
                  "CAP_WAKE_ALARM"
                ];

                # https://man7.org/linux/man-pages/man7/address_families.7.html
                RestrictAddressFamilies = [ "AF_BRIDGE" "AF_UNIX" "AF_INET" "AF_NETLINK" "AF_INET6" "AF_XDP" ]; # TODO: A/B teste! # https://github.com/containers/podman/discussions/14311
                # RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" ]; # TODO: A/B teste! https://github.com/serokell/serokell.nix/blob/bfd859fcb96aa912f4ca05b4afe4082114ca9ec7/lib/systemd/profiles.nix#L34
                /*
                The reason is that using RestrictAddressFamilies in an unprivileged systemd user service implies
                NoNewPrivileges=yes. This prevents /usr/bin/newuidmap and /usr/bin/newgidmap from running with
                elevated privileges. Podman executes newuidmap and newgidmap to set up user namespace. Both executables
                normally run with elevated privileges, as they need to perform operations not available to an
                unprivileged user.
                https://www.redhat.com/sysadmin/podman-systemd-limit-access
                */
                NoNewPrivileges = false; # https://docs.arbitrary.ch/security/systemd.html#nonewprivileges
                SystemCallFilter = lib.mkForce [ ]; # Resolve ping -c 3 8.8.8.8 -> Bad system call (core dumped)
                RestrictSUIDSGID = false;
                DeviceAllow = [ "auto" ]; # https://github.com/NixOS/nixpkgs/issues/18708#issuecomment-248254608
                # Environment = "PATH=/run/current-system/sw/bin:${lib.makeBinPath [ pkgs.iputils ]}"; # https://discourse.nixos.org/t/how-to-add-path-into-systemd-user-home-manager-service/31623/4
                # Environment = "PATH=/run/current-system/sw/bin:/run/wrappers/bin:/home/nixuser/.nix-profile"; # https://discourse.nixos.org/t/how-to-add-path-into-systemd-user-home-manager-service/31623/4
                Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/per-user/nixuser/profile/bin:/home/nixuser/.nix-profile/bin"; # https://discourse.nixos.org/t/how-to-add-path-into-systemd-user-home-manager-service/31623/4
              };

              /*
                TODO: apenas na unidade do systemd,
                  na VM (no "terminal") o podman funciona!

                stat $(which newuidmap)
                stat $(which newgidmap)
                stat $(which /run/wrappers/bin/newuidmap)
                stat $(which /run/wrappers/bin/newgidmap)

                Relacionado?

                O sudo tb está "quebrado" nesse ambiente!
                sudo: The "no new privileges" flag is set, which
                prevents sudo from running as root.
                sudo: If sudo is running in a container, you may
                need to adjust the container configuration to
                disable the flag.
                https://github.com/ORG/REPO/actions/runs/7410857271/job/20164052167#step:5:51

                cannot clone: Operation not permitted
                Error: cannot re-exec process
                Error: Process completed with exit code 125.
                https://github.com/ORG/REPO/actions/runs/7410557206/job/20163140291#step:8:56
              */
              virtualisation.podman.enable = true;
              # boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;

              # Funciona, mas não resolveu o erro newuidmap: write to uid_map failed: Operation not permitted
              environment.etc.services.mode = ""; # https://github.com/containers/podman/issues/21033#issuecomment-1858199501

              systemd.services.github-runners.serviceConfig.SupplementaryGroups = [ "docker" "podman" ];

              systemd.user.services.populate-history-vagrant = {
                script = ''
                  echo "Started"

                  DESTINATION=/home/nixuser/.zsh_history

                  # TODO: https://stackoverflow.com/a/67169387
                  echo "sudo systemd-analyze security github-runner-runner1.service | cat" >> "$DESTINATION"
                  echo "sudo systemctl show github-runner-runner1.service | cat" >> "$DESTINATION"
                  echo "sudo systemctl cat github-runner-runner1.service | cat" >> "$DESTINATION"
                  echo "systemctl status github-runner-runner1.service | cat" >> "$DESTINATION"
                  echo "save-pat && sudo systemctl restart github-runner-runner1.service" >> "$DESTINATION"
                  echo "sudo systemctl restart github-runner-runner1.service" >> "$DESTINATION"
                  echo "journalctl -xeu github-runner-runner1.service" >> "$DESTINATION"

                  echo "Ended"
                '';
                wantedBy = [ "default.target" ];
              };

              # journalctl -u prepare-secrets -b -f
              systemd.services.prepare-secrets = {
                script = ''
                  echo "starting prepare-secrets script"

                  # TODO: remover hardcoded
                  mkdir -pv -m 0700 /run/secrets/github-runner
                  
                  echo "${GH_TOKEN}" > /run/secrets/github-runner/nixos.token
                  chown nixuser:nixgroup -Rv /run/secrets/github-runner
                  chmod 0600 /run/secrets/github-runner/nixos.token

                  echo End
                '';
                wantedBy = [ "multi-user.target" ];
              };

              /*
              https://github.com/vimjoyer/sops-nix-video/tree/25e5698044e60841a14dcd64955da0b1b66957a2
              https://github.com/Mic92/sops-nix/issues/65#issuecomment-929082304
              https://discourse.nixos.org/t/qmenu-secrets-sops-and-nixos/13621/8
              https://www.youtube.com/watch?v=1BquzE3Yb4I
              https://github.com/FiloSottile/age#encrypting-to-a-github-user
              https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html

              sudo cat /run/secrets/example-key
              */
              /*
              sops.defaultSopsFile = ./secrets/secrets.yaml.encrypted;
              sops.defaultSopsFormat = "yaml";
              sops.gnupg.sshKeyPaths = [];
              sops.age.sshKeyPaths = [];
              sops.age.keyFile = ./secrets/keys.txt;
              sops.secrets.example-key = { };
              */

              # https://github.com/NixOS/nixpkgs/blob/3a44e0112836b777b176870bb44155a2c1dbc226/nixos/modules/programs/zsh/oh-my-zsh.nix#L119
              # https://discourse.nixos.org/t/nix-completions-for-zsh/5532
              # https://github.com/NixOS/nixpkgs/blob/09aa1b23bb5f04dfc0ac306a379a464584fc8de7/nixos/modules/programs/zsh/zsh.nix#L230-L231
              programs.zsh = {
                enable = true;
                shellAliases = {
                  vim = "nvim";
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
                packages = with pkgs; [
                  powerline
                  powerline-fonts
                ];
                enableDefaultPackages = true;
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

              services.sshd.enable = true;

              # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
              services.openssh = {
                allowSFTP = true;
                settings.KbdInteractiveAuthentication = false;
                enable = true;
                # settings.ForwardX11 = false;
                settings.PasswordAuthentication = false;
                settings.PermitRootLogin = "yes";
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
              services.xserver.xkb.layout = "br";

              services.displayManager.autoLogin.user = "nixuser";
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
                  xdotool type 'journalctl -xeu github-runner-runner1.service' \
                  && xdotool key Return
              '';

              # https://nixos.org/manual/nixos/stable/#sec-xfce
              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;

              services.xserver.videoDrivers = [ "qxl" ];

              # For copy/paste to work
              services.spice-vdagentd.enable = true;

              nixpkgs.config.allowUnfree = true;

              boot.readOnlyNixStore = true;

              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                # package = pkgs.nixVersions.nix_2_10;
                registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
                nixPath = [
                  "nixpkgs=/etc/channels/nixpkgs"
                  "nixos-config=/etc/nixos/configuration.nix"
                ];
              };

              environment.etc."channels/nixpkgs".source = nixpkgs.outPath;

              environment.systemPackages = with pkgs; [
                bashInteractive
                direnv
                firefox
                fzf
                jq
                neovim
                nix-direnv
                nixos-option
                oh-my-zsh
                openssh
                python3
                which
                xclip
                zsh
                zsh-autosuggestions
                zsh-completions

                (
                  writeScriptBin "save-pat" ''
                    #! ${pkgs.runtimeShell} -e
                      # sudo mkdir -pv -m 0700 /run/secrets/github-runner
                      # sudo chown $(id -u):$(id -g) /run/secrets/github-runner
                      # echo -n ghp_yyyyy > /run/secrets/github-runner/nixos.token

                      bash -lc \
                      '
                      read -sp "Please enter your github PAT:" MY_PAT
                      echo -n "$MY_PAT" > /run/secrets/github-runner/nixos.token
                      '
                  ''
                )
              ];

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

              networking.firewall.enable = true; # TODO: hardening

              system.stateVersion = "23.11";
            })

          { nixpkgs.overlays = [ self.overlays.default ]; }

        ];

        specialArgs = { inherit nixpkgs allAttrs; };

      };
    };
}
