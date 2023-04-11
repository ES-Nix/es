{ config, pkgs, lib, modulesPath, ... }:
let
  # https://github.com/pedroregispoar.keys
  PedroRegisPOARKeys = pkgs.writeText "pedro-regis-keys.pub" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExR+PSB/jBwJYKfpLN+MMXs3miRn70oELTV3sXdgzpr
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHGm7j7vAv3AtuTA3AWi9WPIAleWcuZQFvgk1YFpVcN
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgAw61KJMR+OB5ErhqDRkOkeUNANCPG+PJyolxJUiSa
  '';

in
with lib;
{
  # users.motd = "Today is Sweetmorn, the 4th day of The Aftermath in the YOLD 3178.";

  users.mutableUsers = false;
  users.users.root = {
    password = "root";
    openssh.authorizedKeys.keyFiles = [
      PedroRegisPOARKeys
    ];
  };

  # TODO: Hardening
  # https://stackoverflow.com/a/55192323
  security.sudo.enable = true;

  # TODO: Hardening
  users.extraGroups.nixgroup.gid = 5678;

  # TODO: should it be refactored in an NixOS module?
  users.users.nixuser = {
    password = "1";
    # TODO: Hardening
    # isNormalUser = true;
    isSystemUser = true;
    # O padrão é /var/empty!
    home = "/home/nixuser";
    createHome = true;
    homeMode = "0700";
    group = "nixgroup";

    # https://nixos.wiki/wiki/Libvirt
    extraGroups = [
      "docker"
      "kubernetes"
      "libvirtd"
      "kvm"
      "nixgroup"
      "root"
      "wheel"
    ];

    # TODO: https://stackoverflow.com/a/67984113
    # https://www.vultr.com/docs/how-to-install-nixos-on-a-vultr-vps
    openssh.authorizedKeys.keyFiles = [
      PedroRegisPOARKeys
    ];

    openssh.authorizedKeys.keys = [
      "${PedroRegisPOARKeys}"
    ];

    shell = pkgs.zsh;

    # Por conta do podman.
    # TODO: deveria ser o módulo do podman o módulo a fazer isso?
    autoSubUidGidRange = true;
  };

  # https://github.com/NixOS/nixpkgs/issues/19246#issuecomment-252206901
  services.openssh = {
    # allowSFTP = true;
    kbdInteractiveAuthentication = false;
    enable = true;

    # Não funciona em ambientes sem $DISPLAY, em CI por exemplo
    forwardX11 = true;

    # TODO: hardening
    passwordAuthentication = false;
    # Se não setada a porta padrão é a 22
    # Pode ser setado como variável de ambiente
    # QEMU_NET_OPTS='hostfwd=tcp::2221-:22'
    # ou como opção de módulo
    # ports = [ 3322 ];

    # TODO: hardening, is it dangerous? How much?
    # Do NOT use it in PRODUCTION as yes!
    permitRootLogin = "yes";

    # What is the difference about this and the one in
    # users.extraUsers.nixuser.openssh.authorizedKeys.keyFiles ?
    authorizedKeysFiles = [
      "${toString PedroRegisPOARKeys}"
    ];
  };
  programs.ssh.forwardX11 = false;

  # What is it for?
  # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
  # programs.ssh.setXAuthLocation = true;

  # https://github.com/NixOS/nixpkgs/blob/3a44e0112836b777b176870bb44155a2c1dbc226/nixos/modules/programs/zsh/oh-my-zsh.nix#L119
  # https://discourse.nixos.org/t/nix-completions-for-zsh/5532
  # https://github.com/NixOS/nixpkgs/blob/09aa1b23bb5f04dfc0ac306a379a464584fc8de7/nixos/modules/programs/zsh/zsh.nix#L230-L231
  programs.zsh = {
    enable = true;
    shellAliases = {
      vim = "nvim";
      shebang = "echo '#!/usr/bin/env bash'"; # https://stackoverflow.com/questions/10376206/what-is-the-preferred-bash-shebang#comment72209991_10383546
      nfmt = "nix run nixpkgs#nixpkgs-fmt **/*.nix *.nix";
      k = "kubectl";
      ka = "kubectl get pods --all-namespaces -o wide";
      wkgp = "watch -n 1 kubectl get pods --all-namespaces -o wide";
      wkgs = "watch -n 1 kubectl get services --all-namespaces -o wide";
      wkgn = "watch -n 1 kubectl get nodes --all-namespaces -o wide";
      kdn = "kubectl describe nodes nixos";
      kdall = "kubectl delete all --all -n kube-system";
      ff = "firefox 0.0.0.0:80";
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

      source $ZSH/oh-my-zsh.sh
    '';
    ohMyZsh.custom = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    promptInit = "";
  };

  # Hack to fix annoying zsh warning, too overkill probably
  # https://www.reddit.com/r/NixOS/comments/cg102t/how_to_run_a_shell_command_upon_startup/eudvtz1/?utm_source=reddit&utm_medium=web2x&context=3
  systemd.services.fix-zsh-warning = {
    script = ''
      echo "Fixing a zsh warning"
      # https://stackoverflow.com/questions/638975/how-wdo-i-tell-if-a-regular-file-does-not-exist-in-bash#comment25226870_638985
      test -f /home/nixuser/.zshrc || touch /home/nixuser/.zshrc && chown nixuser: -Rv /home/nixuser
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
