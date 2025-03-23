{ config, pkgs, lib, modulesPath, ... }:
let
  empty = pkgs.dockerTools.buildImage {
    name = "oci-empty";
    tag = "0.0.0";
  };

  busybox-musl = pkgs.dockerTools.buildImage {
    name = "oci-busybox";
    tag = "1.36.0-musl";
    fromImage = pkgs.dockerTools.pullImage {
      name = "library/busybox";
      imageName = "busybox";
      sha256 = "sha256-3NxE4X/+EyQIgd1SqfCuRw4sgJJNKsZ8lOdtzkHH6U0=";
      imageDigest = "sha256:e7dc28a9c45363cb558fd4a03bc65a21b602a4fd744d48a4002790ea2c988178";
    };

    config = {
      Cmd = [ "/bin/sh" ];
    };
  };

  busybox-glibc = pkgs.dockerTools.buildImage {
    name = "oci-busybox";
    tag = "1.36.0-glibc";
    fromImage = pkgs.dockerTools.pullImage {
      name = "library/busybox";
      imageName = "busybox";
      sha256 = "sha256-3NxE4X/+EyQIgd1SqfCuRw4sgJJNKsZ8lOdtzkHH6U0=";
      imageDigest = "sha256:f2c7344e7c13f559171a602a16a49769cf524513d30379651afb5f0637cf6c27";
    };

    config = {
      Cmd = [ "/bin/sh" ];
    };
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

  archlinux = pkgs.dockerTools.buildImage {
    name = "oci-archlinux";
    tag = "base-20230212.0.126025";
    fromImage = pkgs.dockerTools.pullImage {
      name = "library/archlinux";
      imageName = "archlinux";
      sha256 = "sha256-dISvrwPO6uYAinshBLpLibDwpvZ0hwURNW22BY35/bk=";
      # podman inspect docker.io/library/ubuntu:22.04  | jq ".[].Digest"
      imageDigest = "sha256:27f132b602ba42dd597637d716b59f1cc2b31cf3af69325201a2168a288501d8";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

  centos = pkgs.dockerTools.buildImage {
    # https://github.com/docker-library/docs/pull/2205#issuecomment-1260187725
    name = "oci-centos";
    tag = "8";
    fromImage = pkgs.dockerTools.pullImage {
      name = "library/centos";
      imageName = "centos";
      sha256 = "sha256-p4WOxdf6YU9949tibwBM40juPzAgJKWeq0vOvfCOhj4=";
      # podman inspect docker.io/library/ubuntu:22.04  | jq ".[].Digest"
      imageDigest = "sha256:a27fd8080b517143cbbbab9dfb7c8571c40d67d534bbdee55bd6c473f432b177";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

  fedora = pkgs.dockerTools.buildImage {
    name = "oci-fedora";
    tag = "38";
    fromImage = pkgs.dockerTools.pullImage {
      name = "library/fedora";
      imageName = "fedora";
      sha256 = "sha256-XfS2AHICq12PeXaFg8TuukCxVY0MdvWHPmUCU3Vxl/Q=";
      imageDigest = "sha256:1587983af31a66cc3c7cadf065a0782bb3fac64221d70497aa2633eb43b7722a";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

  nix = pkgs.dockerTools.buildImage {
    name = "nix";
    tag = "latest";
    fromImage = pkgs.dockerTools.pullImage {
      name = "nixos/nix";
      imageName = "nixos/nix";
      sha256 = "sha256-u/lRu0IX5AjO3ZnOh48g3p8iiZ8FuoWmbcOhJwDhdPI=";
      # podman inspect docker.io/nixos/nix:latest | jq ".[].Digest"
      imageDigest = "sha256:af1b4e1eb819bf17374141fc4c3b72fe56e05f09e91b99062b66160a86c5d155";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

  podman = pkgs.dockerTools.buildImage {
    name = "oci-podman";
    tag = "stable";
    fromImage = pkgs.dockerTools.pullImage {
      name = "quay.io/podman";
      imageName = "quay.io/podman";
      sha256 = "sha256-XfS2AHICq12PeXaFg8TuukCxVY0MdvWHPmUCU3Vxl/Q=";
      imageDigest = "sha256:39c090899cb0d5baeea32770d6678204b72ba80b09db793e80ce8b01a253d8d1";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

  latex-basic = pkgs.dockerTools.buildImage {
    name = "oci-latex-basic";
    tag = "ctanbasic";
    fromImage = pkgs.dockerTools.pullImage {
      name = "blang/latex";
      imageName = "latex";
      sha256 = "sha256-3NxE4X/+EyQIgd1SqfCuRw4sgJJNKsZ8lOdtzkHH6U0=";
      imageDigest = "sha256:27665560667e9108f8d9a98a8f6cfac524f8b3792f7bde97d5efcb3701e1ab37";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

  latex-full = pkgs.dockerTools.buildImage {
    name = "oci-latex-ctanfull";
    tag = "ctanfull";
    fromImage = pkgs.dockerTools.pullImage {
      name = "blang/latex";
      imageName = "latex";
      sha256 = "sha256-3NxE4X/+EyQIgd1SqfCuRw4sgJJNKsZ8lOdtzkHH6U0=";
      imageDigest = "sha256:5950147165027b122befcf131550840e024782bab24b16c3ecc82338dd0c8835";
    };

    config = {
      Cmd = [ "/bin/bash" ];
    };
  };

in
with lib;
{
  # environment.variables.OCI_IMAGES_TO_LOAD = "${alpine}";

  environment.systemPackages = with pkgs; [
    (
      writeScriptBin "load-oci-images" ''
                podman load --input "${archlinux}"
                podman load --input "${alpine}"
                # podman load --input "''${busybox-glibc}"
                # podman load --input "''${busybox-musl}"
                podman load --input "${centos}"
                podman load --input "${debian}"
                podman load --input "${empty}"
                podman load --input "${fedora}"
        #        podman load --input "''${latex-basic}"
        #        podman load --input "''${latex-full}"
        #        podman load --input "''${nix}"
        #        podman load --input "''${podman}"
                podman load --input "${ubuntu}"
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
