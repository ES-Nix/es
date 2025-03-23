{ config, pkgs, lib, modulesPath, ... }:
let
  empty = pkgs.dockerTools.buildImage {
    name = "oci-empty";
    tag = "0.0.0";
  };

  busybox-sandbox-shell = pkgs.dockerTools.buildImage
    {
      name = "oci-static-busybox-sandbox-shell";
      tag = "latest";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = [ pkgs.pkgsStatic.busybox-sandbox-shell ];
        pathsToLink = [ "/bin" ];
      };

      config = {
        Cmd = [ "/bin/sh" ];
      };
    };

  hello = pkgs.dockerTools.buildImage
    {
      name = "oci-static-hello-static";
      tag = "0.0.1";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = [ pkgs.pkgsStatic.hello ];
        pathsToLink = [ "/bin" ];
      };

      config = {
        Cmd = [ "/bin/hello" ];
      };
    };

  toybox = pkgs.dockerTools.buildImage
    {
      name = "oci-static-toybox";
      tag = "0.0.1";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = [ pkgs.pkgsStatic.toybox ];
        pathsToLink = [ "/bin" ];
      };

      config = {
        Cmd = [ "sh" ];
      };
    };

  busybox = pkgs.dockerTools.buildImage
    {
      name = "oci-static-busybox";
      tag = "0.0.1";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = [ pkgs.pkgsStatic.busybox ];
        pathsToLink = [ "/bin" ];
      };

      config = {
        Cmd = [ "sh" ];
      };
    };

  bashinteractive-coreutils = pkgs.dockerTools.buildImage
    {
      name = "oci-bashinteractive-coreutils";
      tag = "0.0.1";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = with pkgs; [ bashInteractive coreutils ];
        pathsToLink = [ "/bin" ];
      };

      config = {
        Cmd = [ "bash" ];
      };
    };

  bashinteractive-coreutils-user = pkgs.dockerTools.buildImage
    {
      name = "oci-bashinteractive-coreutils-user";
      tag = "0.0.1";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = with pkgs; [ bashInteractive coreutils ];
        pathsToLink = [ "/bin" ];
      };

      config = {
        Cmd = [ "bash" ];
        # TODO: add user

      };
    };

  base-fonts = pkgs.dockerTools.buildImage
    {
      name = "oci-base-fonts";
      tag = "0.0.1";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = with pkgs; [ bashInteractive coreutils fontconfig ];
        pathsToLink = [ "/bin" ];
      };

      config = {
        Cmd = [ "bash" ];
        Env = [
          "FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
          "FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts/"
        ];
      };
    };

  xorg-xclock = pkgs.dockerTools.buildImage {
    # https://github.com/NixOS/nixpkgs/issues/176081
    name = "oci-static-xorg-xclock";
    tag = "latest";
    config = {
      contents = with pkgs; [
        pkgsStatic.busybox-sandbox-shell

        # bashInteractive
        # coreutils

        # TODO: test this xskat
        xorg.xclock
        # https://unix.stackexchange.com/questions/545750/fontconfig-issues
        # fontconfig
      ];
      Env = [
        "FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
        "FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts/"
        # "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        # "PATH=${pkgs.coreutils}/bin:${pkgs.hello}/bin:${pkgs.findutils}/bin"
        # :${pkgs.coreutils}/bin:${pkgs.fontconfig}/bin
        "PATH=/bin:${pkgs.pkgsStatic.busybox-sandbox-shell}/bin:${pkgs.xorg.xclock}/bin"

        # https://access.redhat.com/solutions/409033
        # https://github.com/nix-community/home-manager/issues/703#issuecomment-489470035
        # https://bbs.archlinux.org/viewtopic.php?pid=1805678#p1805678
        "LC_ALL=C"
      ];

      # Entrypoint = [ "bash" ];
      # Entrypoint = [ "sh" ];

      Cmd = [ "xclock" ];
    };

    #runAsRoot = ''
    #  echo 'Some message from runAsRoot echo.'
    #  echo "$(pwd)"
    #
    #  mkdir ./abcde
    #  id > ./abcde/my-id-output.txt
    #'';
    runAsRoot = ''
      #!${pkgs.stdenv}
      ${pkgs.dockerTools.shadowSetup}
      groupadd --gid 56789 nixgroup
      useradd --no-log-init --uid 12345 --gid nixgroup nixuser

      mkdir -pv ./home/nixuser
      chmod 0700 ./home/nixuser
      chown 12345:56789 -R ./home/nixuser

      # https://www.reddit.com/r/ManjaroLinux/comments/sdkrb1/comment/hue3gnp/?utm_source=reddit&utm_medium=web2x&context=3
      mkdir -pv ./home/nixuser/.local/share/fonts
    '';

    #    extraCommands = ''
    #      ${pkgs.coreutils}/bin/mkdir -pv ./etc/pki/tls/certs
    #      ${pkgs.coreutils}/bin/ln -sv ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ./etc/pki/tls/certs
    #    '';
  };


  alpine = pkgs.dockerTools.buildImage {
    name = "oci-alpine";
    tag = "3.17.1";
    fromImage = pkgs.dockerTools.pullImage {
      name = "library/alpine";
      imageName = "alpine";
      sha256 = "sha256-kmbL9Zc68Y1mq97NdBWpOM+VPYSy/jcXjGOYUu/Imsk=";
      # podman inspect docker.io/library/alpine:3.17.1 | jq ".[].Digest"
      imageDigest = "sha256:f271e74b17ced29b915d351685fd4644785c6d1559dd1f2d4189a5e851ef753a";
    };

    config = {
      Cmd = [ "/bin/sh" ];
    };
  };

  ubuntu = pkgs.dockerTools.buildImage
    {
      name = "oci-ubuntu";
      tag = "22.04";
      fromImage = pkgs.dockerTools.pullImage {
        name = "library/ubuntu";
        imageName = "ubuntu";
        sha256 = "sha256-EHSF50vZV9fvtPFJ7I19tCdB7u9UPhEjYue3A/LPuiI=";
        # podman inspect docker.io/library/ubuntu:22.04  | jq ".[].Digest"
        imageDigest = "sha256:9a0bdde4188b896a372804be2384015e90e3f84906b750c1a53539b585fbbe7f";
      };

      config = {
        Cmd = [ "/bin/bash" ];
      };
    };

  debian = pkgs.dockerTools.buildImage {
    name = "oci-debian";
    tag = "bookworm-20230208-slim";
    fromImage = pkgs.dockerTools.pullImage {
      name = "library/debian";
      imageName = "debian";
      sha256 = "sha256-eh6vM0LF2+wscgWuOPFMF8PlJhj4VVU9B+UTIUx5oOc=";
      # podman inspect docker.io/library/ubuntu:22.04  | jq ".[].Digest"
      imageDigest = "sha256:72cc75fa1097aa604b310e70fee7e19afa24d8b64057cc6a717066207af29ee3";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

  nix-dev-bloated =
    let
      troubleshoot-packages = with pkgs; [
        # https://askubuntu.com/questions/16700/how-can-i-change-my-own-user-id#comment749398_167400
        # https://unix.stackexchange.com/a/693915
        acl

        file
        findutils
        # gzip
        hello
        bpytop
        iproute
        nettools # why the story name is with an -?
        nano
        netcat
        ripgrep
        patchelf
        binutils
        mount
        # bpftrace
        strace
        uftrace
        # gnutar
        wget
        which
      ];

      customLocales = pkgs.glibcLocales.override {
        allLocales = false;
        locales = [
          "en_GB.UTF-8/UTF-8"
          "ru_RU.UTF-8/UTF-8"
          "en_US.UTF-8/UTF-8"
          "pt_BR.UTF-8/UTF-8"
          "ja_JP.UTF-8/UTF-8"
          "en_IE.UTF-8/UTF-8"
        ];
      };

      customSudo = (pkgs.pkgsStatic.sudo.override { pam = null; });
      customSu = (pkgs.pkgsStatic.shadow.override { pam = null; }).su;

      userName = "nixuser";
      userGroup = "nixgroup";
    in
    pkgs.dockerTools.buildImage {
      name = "nix-sudo-su";
      tag = "0.0.1";

      copyToRoot = [
        # ca-bundle-etc-passwd-etc-group-sudo-su
        # create-tmp
      ]
      ++
      (with pkgs; [
        # pkgsStatic.busybox-sandbox-shell
        bashInteractive
        coreutils
        # uutils-coreutils
        # busybox

        # It might be missing the /etc stuff
        # systemd


        # TODO: test it with new versions
        # pkgsStatic.nix
        # pkgsStatic.nixVersions.nix_2_10
        nix

        customSu
        customSudo
      ]
        # ++ troubleshoot-packages
      );

      config = {
        # Cmd = [ "nix" ];

        # Entrypoint = [ "${pkgs.systemd}/lib/systemd/systemd" ];
        # Entrypoint = [ "es" ];

        Entrypoint = [ "${pkgs.bashInteractive}/bin/bash" ];
        # Entrypoint = [ "${pkgs.busybox-sandbox-shell}/bin/sh" ];
        # Entrypoint = [ "${pkgs.coreutils}/bin/stat" ];
        Env = [
          "FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
          "FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts/"
          # TODO
          # https://access.redhat.com/solutions/409033
          # https://github.com/nix-community/home-manager/issues/703#issuecomment-489470035
          # https://bbs.archlinux.org/viewtopic.php?pid=1805678#p1805678
          "LC_ALL=C"
          "LOCALE_ARCHIVE=${customLocales}/lib/locale/locale-archive"

          # TODO: study all this
          # - have really great oneliners that fail and that, of course, works.
          # http://bugs.python.org/issue19846
          # > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
          # ENV LANG C.UTF-8

          #
          #
          # https://gist.github.com/eoli3n/93111f23dbb1233f2f00f460663f99e2#file-rootless-podman-wayland-sh-L25
          "LD_LIBRARY_PATH=${pkgs.libcanberra-gtk3}/lib/gtk-3.0/modules"
          #
          # TODO: document it
          # https://unix.stackexchange.com/a/230442
          "NO_AT_BRIDGE=1"
          #
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          # "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          # "NIX_PAGER=cat"
          # A user is required by nix
          # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
          #"USER=${userName}"
          #"HOME=/home/${userName}"
          # "PATH=/bin:/home/${userName}/bin"
          # "NIX_PATH=/nix/var/nix/profiles/per-user/root/channels"
          #"TMPDIR=/home/${userName}/tmp"
        ];
      };

      # sudo chown "$(id -u)":"$(id -g)" -R /nix
      # chmod 0655 /nix
      # nix flake metadata nixpkgs
      #
      # sudo mkdir -pv /nix/var/nix/profiles
      # sudo chown "$(id -u)":"$(id -g)" -R /nix/var/nix/profiles
      #
      #
      # sudo mkdir -pv "${HOME}"/.cache
      # sudo chown "$(id -u)":"$(id -g)" -R "${HOME}"/.cache
      #
      # sudo chmod 0755 -R /nix
      # sudo chown "$(id -u)":"$(id -g)" -R /nix
      #
      # nix flake metadata nixpkgs
      #
      # chmod 0755 -R ./nix
      # chown nixuser:nixgroup -R ./nix
      runAsRoot = ''
            #!${pkgs.stdenv}
            ${pkgs.dockerTools.shadowSetup}

            echo 'Some message from runAsRoot echo.'

        #    # TODO:
        #    # https://discourse.nixos.org/t/how-to-run-chown-for-docker-image-built-with-streamlayeredimage-or-buildlayeredimage/11977/3
        #    # useradd --no-log-init --uid 1234 --gid nixgroup ''${userName}
        #    groupadd --gid 6789 nixgroup
        #    # -l = --no-log-init
        #    # -m = --create-home
        #    # -k = --skel
        #    useradd -k ./etc/skel -l -m  --uid 1234 --gid nixgroup ${userName}
        #
        #    # This 302 is from what we have in Ubuntu usually
        #    groupadd --gid 302 kvm
        #    usermod --append --groups kvm ${userName}

            cp "${customSudo}"/bin/sudo ./bin/sudo
            chown 0:0 ./bin/sudo
            chmod 4755 ./bin/sudo

            test -d ./etc || mkdir -pv ./etc/sudoers
            echo 'ALL  ALL=(ALL) NOPASSWD: ALL' >> ./etc/sudoers

        #    # TODO
        #    # https://unix.stackexchange.com/a/55776
        #    #
        #    # Is it ugly or beautiful?
        #    test -d ./tmp || mkdir -pv ./tmp
        #    chmod 1777 ./tmp
        #
        #    test -d ./home/nixuser/tmp || mkdir -pv ./home/nixuser/tmp
        #    chmod 1777 ./home/nixuser/tmp

        #    # https://www.reddit.com/r/ManjaroLinux/comments/sdkrb1/comment/hue3gnp/?utm_source=reddit&utm_medium=web2x&context=3
        #    mkdir -pv ./home/nixuser/.local/share/fonts
        #    chown nixuser:nixgroup -R ./home/nixuser/.local/share/fonts

        #    test -d ./home/nixuser/.cache || mkdir -pv ./home/nixuser/.cache
        #    chown nixuser:nixgroup -R ./home/nixuser/

            test -d ./root/.config/nix || mkdir -pv ./root/.config/nix
            echo 'experimental-features = nix-command flakes' > /root/.config/nix/nix.conf

            test -d ./root/.config/nix || mkdir -pv ./root/.config/nixpkgs/
            echo '{ nixpkgs.config.allowUnfree = true; }' > ./root/.config/config.nix

            # mkdir -pv ./nix/store/.links
            # chown 1234:6789 ./nix
            # chown 1234:6789 ./nix/store
            # chown 1234:6789 ./nix/store/.links


            # mkdir -pv ./usr/share
            # cp -R "''${pkgs.systemd}"/bin ./bin
            # cp -R "''${pkgs.systemd}"/etc ./etc
            # cp -R "''${pkgs.systemd}"/lib ./lib
            # cp -R "''${pkgs.systemd}"/share ./usr/share

            # cp -R "''${pkgs.systemd}"/example/systemd/user/default.target ./lib/systemd
      '';

      #  extraCommands = ''
      #    #!${pkgs.stdenv}
      #
      #    test -d ./home/nixuser/.config/nix || mkdir -pv ./home/nixuser/.config/nix
      #    echo 'experimental-features = nix-command flakes' > ./home/nixuser/.config/nix/nix.conf
      #
      #    test -d ./home/nixuser/.config/nix || mkdir -pv ./home/nixuser/.config/nixpkgs/
      #    echo '{ nixpkgs.config.allowUnfree = true; }' > ./home/nixuser/.config/config.nix
      #    id > ./home/nixuser/log.txt
      #    chmod 0777 ./home/nixuser
      #    chown -R 1234:6789 ./home/nixuser
      #  '';

    };


in
with lib;
{
  # environment.variables.OCI_IMAGES_TO_LOAD = "${alpine}";

  environment.systemPackages = with pkgs; [
    (
      writeScriptBin "load-oci-images" ''
        podman load --input "''${empty}"
        podman load --input "''${busybox-sandbox-shell}"
        podman load --input "''${hello}"
        podman load --input "''${xorg-xclock}"
        podman load --input "''${toybox}"
        podman load --input "''${busybox}"
        podman load --input "''${bashinteractive-coreutils}"
        podman load --input "''${bashinteractive-coreutils-user}"
        podman load --input "''${base-fonts}"

        podman load --input "${alpine}"
        # podman load --input "''${debian}"
        # podman load --input "''${ubuntu}"

        podman load --input "${nix-dev-bloated}"

        podman images

        #podman run -ti --rm localhost/oci-static-busybox-sandbox-shell sh -c 'pwd'
        #podman run -ti --rm localhost/oci-static-busybox-sandbox-shell sh -c 'echo $0'
        #
        #podman run -ti --rm -u=1111:2222 localhost/oci-static-busybox:0.0.1 id
        #podman run -ti --rm -u=1111:2222 localhost/oci-static-busybox:0.0.1 sh -c 'echo $0'
        #
        #podman run -ti --rm -u=1111:2222 localhost/oci-bashinteractive-coreutils:0.0.1 id
        #podman run -ti --rm localhost/oci-bashinteractive-coreutils-user:0.0.1 id

        xhost +

        podman \
        run \
        --security-opt seccomp=unconfined \
        --security-opt label=disable \
        --env="DISPLAY=''${DISPLAY:-:0.0}" \
        -ti \
        --rm=true \
        --user=1111:2222 \
        --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
        localhost/oci-static-xorg-xclock:latest
      ''
    )
  ];

  # journalctl -u load-oci-images.service -b
  # systemctl status load-oci-images.service
  #  systemd.services.load-oci-images = {
  #    script = ''
  #      set -x
  #
  #      echo "${alpine}"
  #      podman load -i "${alpine}"
  #      exit 0
  #    '';
  #    wantedBy = [ "multi-user.target" ];
  #  };
}
