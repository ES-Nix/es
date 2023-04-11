{ config, pkgs, lib, modulesPath, ... }:
let
  # https://github.com/pedroregispoar.keys
  PedroRegisPOARKeys = pkgs.writeText "pedro-regis-keys.pub" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExR+PSB/jBwJYKfpLN+MMXs3miRn70oELTV3sXdgzpr
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHGm7j7vAv3AtuTA3AWi9WPIAleWcuZQFvgk1YFpVcN
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgAw61KJMR+OB5ErhqDRkOkeUNANCPG+PJyolxJUiSa
  '';

  RodrigoKeys = pkgs.writeText "rodrigo-keys.pub" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIABPBOuSsDCkiiy6wOAh/XDYvKZOLBMUmxxCH+d52e8s
  '';

  jsb989Keys = pkgs.writeText "jsb989-keys.pub" ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDj/MPkY+35JhKopxMaMdgtTiRfd8Bj10LeQFQ728FJDAsDlFw4hVNQHe4Nb6/a0ghYlyNrVYmZ5qxEP1BvXhmoNNr3BV8naImK4zZs5AQWfz5IILWFrKwA1H5084XQltKGe4Q2Osqh22/XJelt2G81WAbgY+Ab7Rry9l5Nnr16twOdCloFDx5AhA0turD3HM63l1FrQsGoLUdcyviRhFx6sdIl/lJKmR7vLQgrmzovnf0lbs7vTWO1vEytrh3PCQqJ/XtW24hmAbx6MsW5imUpkaEuzrI0zifX1mWjq3WLgE/BH+sWE6oDfe92AVszXdToqGRUwM6mu6JEG35zKmHyqcTDz6isvYwa/VUG7flvqJwN1vY2ABXFw6kjT0MS2km0MNx/sl+SlwdwG1q3b5n6O4P9gyUnQ8XBnvPwGxrV5ihCPcUhxvfkUyCrQNObQ2wSeRTIzxmCl3aNMLWsrDMIkG7gjDW/91UT5Ndtvb/skYnHivdJMJXgLuTDmIKcbdM=
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzoqHv8dWznOmpLWSQxqNCJ/YonjKLyTkeZj5AacmxLXS63+eL+7wKuoaOnE3/hM4SCxG+ztxKwKdv9bfbMIZYxIWztQL7AZNouefHqXUdmD5RO4kE1Wyb5SapC/+lSw990jFkkUdj410pHddXdu+16vkxY/OYmiY8P60DI8Y5wG7Db5vKoser6Frm319vRpumKUAOkfVMZamAJ5+NyXGvnkhyqUu9qghG9DmxUV9ryMVbYvRopYkyFfLQuH7i765ic1ggipr3IvKyujtyXzYWV7or4F7PVgG2XGcIsF0NI8VgfA0oVJN69vJ3ReEqS3l0IgEo1q3ljxqW5Ed7TizDu8pdQIvQEdg/Ihcxclhb6+1fjbtKbhlcu9oDJQ+lA3yjIndWZzP6UwbGAViYwtrOl+Sp+AItbIxLbhH59wJ2+fwYt6E170R79ZcHSBhA7YcJY4+tGVTplwwKatxP9hsXZ09wDQeiTryrHOU5eaIJQ3myu7ngvuwxE2B5KrSzUkc=
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDW5eznIeNQlRN8SgeR1urHMJEpNTGr1h8U9TPmuo5fMaq3QeKfdsFyCElnp1i4wYhRMHy+b9bGYAvxSvBh/jTzeznFLt4pICmjEhGzD0Vr02Y0f/uMV7SF0RpwWAySIh48YXjBzuYo5sNpPX4TN+R4r9AbC7hsdkrdnCTbJa4+pHIgV3Bj97weegIUjNtoOGpvcf8SnIy8H+Iww3dIoGKBl5VVRDRZMMA4xZdiswAZ21XVPTYgGhPTG3q43ig6uHLRRLR/YiVacPh8T+Xn5WFKi5ksRMo3hGynX/BQxzmsNTH8pvLYNrA4QCYl14bjJ+uREQI6loqmpzVUlOHvLjy5UTxesjLGMEGcbdkXWEFkd3Y+Y3gUE9Ug2QadKjVHapClHsWjeaWCdvx/awcD4U6TDQaWPu+H9a3HRM0lVffLLBrRRTKaWJw5bakqIiui0fJPjZPI8hMLmr8oX2M5l8h8/2kWG59t5CHBSjFOpc+8Jw0eNSpsnSP/BiV78KhUPac=
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDODtppQdVc2Whbhu0b5jPE+M1OVuICL3ivVta0OOJ6jSDZvutxUHbDDFMhDiwhekMWfQI4BVjBq9zbMxdYHyvcTAFs+m19wk5DiWj4TItwikwFbGM8svK7kUxWg4U+UmOUX4+w7JKmNiTWK0yeisoH7ZAIg0ck6R8xLu8dgN8NaXA/Bo4D9/YoecjSQTPRH+EMtKq7BdNcdpANVKOirasWMKffZ45Hac0rx9BOq2XceMI0ZgOa35zAGh4amNT4bWJA0+hadXUBfWVb/aFH6N0K22JhXZDauu+ZVl3/f1VsGVkYL1lrqGp6+0/v6+2Oo5Uf28M5DM8e/olKGxom2vxGX/omORW9fMcy2qiLwGQgu43OPNzbOtGw3I1nUeTZVdFJ/K0IBnHb0eZQvdyXw/FNn7AXwCFzfodlVbVKVs0+CjEx6TbPTbzUxY1vUEic6a5h9aZVy/GPu18OWoDLc7pxwPSlQ4js2E+aFt6JLLm+D0nuEiFEqsvPyexZ/tAFsyM=
  '';

  brenovKeys = pkgs.writeText "brenov-keys.pub" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKlEyL4WYl/I6V+iOq+zkimRhyZrUsGvUs8yOxC0Zh+u
  '';

  peidraoKeys = pkgs.writeText "peidrao-keys.pub" ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCZ4vTF68VrktaDfLvbxRY4+Iogm9djBbdosCJPFKfE/w2l2bzSiG95UoPVWL4mfzMWhQ3psaKe2vVzeB7yAdC8iF8861Bo2ELul66BY4LgeMoJBCPX4Wbs8hv3Hs129sFcgk07oTNeJutNTccaqaGEuA60KOJd7sFimvEEkL+ikmd0CCIRq4Zb56d5YCddFOjs7VMLKWECHzfSQ1RHefadjbA2W+qkcJWBMZPAnpF0tG8brsNmw5lAYJqAvaLhU6bxCOBhZngQtzWfV5jCbL6CL9vYvEoFCSDsaTDBWGLJVEOlAxbFCeiJDiglyu7AZ1eqPrvSxH8Jpw422Fu4665T4+jYyGR3a2SWBiZc64OfLCdfWzdsjlq+fEKYCISRTEZ7tdp+O463wU1cICewXbctABQFHKyRAm6WfQ+yG3OjHAcZGsOtGuAbQu7CsANLNpmfVKCFmMZtkEXxobud58JUxD2mdb463do5kqpMLq+Hp4sUhZT83NDGMAoRT0kaz8M=
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1/PB+h3R0VawqsHXfCH8OYniPZTy9HdKZ/88G+L8WKpXrOWnqDRhzZASkg7KPjMyPNnVF2LFwY3jkQrsKOFhlrnWallzm0cxOisPk6vvcGvB8oqlmuTxISx52DyTRNPeKzpCPEp95Wxa6xKBXcfBmvyuqLLgUTEaoaMfsuJDCLoX7w2qcHN7AVEOZsKAOJSWk7NDo6y0x2J5f6ZDhaSlYKvsqJmA1lse9V/FgHL5DW2Yz3vkc+PB5M1tA9gm7QXa5xwWri9cQsZ0S5uRsBjbXN6wdHJwwTBhImXw/6zJXpx7QTrAwY+8BteorQErb2u6koxAtj/jfptIIC/ynQdbqOQRXm1F85aj87pTouNHeYgNXlgZZg6bzzinr60kyavp7jUty3+UhxQKEFyKzQkro/GvLvouGBKaYvxRVkKwxNI7Zd2aMdBCW2R+aSiytjwL7yEmT0vQK/wHajo2T3kjmrzCM33LxkWlaaUZ1dI2d6CPcHH/eacabuJ9XF0aMX/E=
  '';

  Carvs10Keys = pkgs.writeText "carvs10-keys.pub" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSf2cNHXGQ+HrGgyEFiSXNiUdo/ngVuD4wKWHeSIXS5
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAHFllD5u5T5SnTCakR4lkRZKA5m7om+xn3MUOj+ugcC
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0aG35kN64TAllQWofX7mlq/2J+mnhidT4AWLU4kF35
  '';

  alvaropfnKeys = pkgs.writeText "alvaropfn-keys.pub" ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3jksHd1Vf/PyxM4tUOd+g+VBw4AS4fsT3kjNtMNyOURxkpHMVBh+qAeBNMRCgl2WELdfKdmctNP7buACk9DSmXTVu5rHP5mxlOjQaTGYHzoOO7ovMeRFIaV6w+jKtwE0RDmDmcGDtMzdh/QadqJLAlMZwYOh6hAIV9Tu7oO7nnQGPs2ebRkf3iMQLD5vEvHY6SAhaiRNBFZbPOIj5nUbnoP1WJH0ojfUj6NxBQm6EAYrHaFEgSUbgJdMP7ICARGb8kMom18SGty65MvrQZLvEaGewMvy5ZGcmNzmZaVy/EU/rXr2dwjALrKKokAXQuj99c+lhe0+MsVk9GSxlfk5f6UmFp+6eqnA0Ww3Jj+pXjafKJZTOgqPTYRVQ5H66AKKWf8BZg1MG4lsOVu0uCkLa2MrmqHRwt4fWVk+gMjP7crfSKsH3mEkZYIHP/kBMLxGOsfyA3JFh2nthUdPDivn4KqgVxE5uVnSYrYFBpIkf7MNvIW2BoDL7gySQDdFMEV4gaJb9+1dNcP3SkLNyByyAk90B1uDzlYFvb1me33wlJJcT3VRuuXQpmI576DiiYK0W7adlvoiPHbdK5vVTGg7AMKY72wURsA3DGO1YFxr7qqAD7Q1FPjeL99tLw/39zwuvsBBqZa+F1xiBifCozl9x64sfVZSoQ9ABxKcCzv7xAQ==
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQChLmWMrzLBUcq060qTHKlvPKdh1T7HEzZI2qV0/3WMsry/i2GTKQneIHM417AUBKyuVYZjPn+j2ewAypcY8yNo1W+EWUknZyNQdb8xjSGOQUlK63L59nPFYJMcP5Woo9Ykqm6quND6D0oJ6WTpfNEgu9L+5+CJ7iCL++ow2Y/lp5NANK7I2F/Uqwbgn4Slgio2x+1LPCkyK+QT3/+McMgAWk3VYTIurrJ7RJS773pPAJKJ/a+0/sAHYX6nvis3uA9YTJXVNzhug/nDHQB7vC5qERWniBi2sHkzjTJ8z9v6PcImOgq6hhrbeTXt5CwWVgD4fjtoNvAmiRtOj3CnLrBHDlRpTv9cr0fP4o//FdxEK00d0AZ5sQ674243uIFX2Q15JcMV0mTcydxv+lRgWnXiG3+Lu6dQfdCXCZpYhNXvWPVzJgTDbEBO59xxyMMzmOVjDZkm1Dm45OuGkB+ASTGnp1tgMQ3M2xfC8wr5VGefvgux9ddbXhW/MCo8UJMCEV0=
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8rSvHuR0foLXsm7YMJ9Fb6UyZsbGqEY9OwbvQAqT3tJG5XsyNQP3UQgyejHQtKcyUUYw7+G8PhCNfk4OrqvyUrXFBb1yDMnNL7OapeQAaTfg0h/tLJbLuCyYyajZ8cEQsS6+oC/DVnWXNrYOB3qTVnJctS9eSBi+m5PwRlOmc9IT/E7c4c29ujj9w08gyvuPMrn4V0FfyupM8W4fKSptjBUdBuGZYxRU2WQF6Y8u7cbVdKvXTPwIC62o/PZbDjSfpXsNQxkLgBggKHX2ZUi4tnfM+efNV6oQ5NJ4uaVxNgVUArGhS7esy1eLOPrEikSRuM9OYJWrZ5wG9jVD8pP9KMhffsuxG2/AaqPeTTOCHoyb9Q3P2In8BolAXDy0egMICdLpeL3nsjn40KNNRx8oUaHOpviCSqwxg5v7hXLZlLoOHgNu7Fl7Gq008EXB8BIa4XbnHaw/Www+ysvqXc612VkZrPQ3Mzi5HyaB9bSQhmk8teUE3dc8w0tyfqlHRM9QHvtH+bAf8bYN30beDwKv64/+PKe0Oq/6KTb72Oj8WB8lNURNkivkSYZs4TwIn3zgBiIQ3gilK567B+VyYxqiKPvgjad9OK23aKKHge6jb7lecvWRxa9IBjCZ1ORx3RmGhjVcLt0rOUorz1Hcw93/h5oIMC/OZye/0Z56Lphs9sw==
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQU+aw1qs3kVr8pi8b7sLleO9lWTH/Rh3M56KoJ/nyq
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHLG7C4/Jr2fRWQM8UE3RkFCCzP8x6O6K+gheuY3peF
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+OLj2gTyo0XzLvE9cteFpgwaZZefjRTejKG6xSg6vN
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMokY3bUayQ37QG0eP+oRTSPyGjuM0bl9GQsAHTVdGwe
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVmKEd22c87nStT/FrIgwOpgPy168ngqHH3MpIKUulY
  '';

in
with lib;
{
  # users.motd = "Today is Sweetmorn, the 4th day of The Aftermath in the YOLD 3178.";
  users.motd = "${builtins.readFile ../pkgs/motd/imobanco-3d-01.txt}";

  users.mutableUsers = false;
  users.users.root = {
    password = "root";
    openssh.authorizedKeys.keyFiles = [
      PedroRegisPOARKeys
      RodrigoKeys
      jsb989Keys
      brenovKeys
      peidraoKeys
      Carvs10Keys
      alvaropfnKeys
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
      RodrigoKeys
      jsb989Keys
      brenovKeys
      peidraoKeys
      Carvs10Keys
      alvaropfnKeys
    ];

    openssh.authorizedKeys.keys = [
      "${PedroRegisPOARKeys}"
      "${RodrigoKeys}"
      "${jsb989Keys}"
      "${brenovKeys}"
      "${peidraoKeys}"
      "${Carvs10Keys}"
      "${alvaropfnKeys}"
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
      # "${toString RodrigoKeys}"
      # "${toString jsb989Keys}"
      # "${toString brenovKeys}"
      # "${toString peidraoKeys}"
      # "${toString Carvs10Keys}"
      # "${toString alvaropfnKeys}"
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
