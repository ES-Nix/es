{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation rec {
  name = "install-qemu-virtual-machine-xfce-copy-paste-minimal-template";
  buildInputs = with pkgs; [ stdenv ];
  nativeBuildInputs = with pkgs; [ makeWrapper ];
  propagatedNativeBuildInputs = with pkgs; [
    bashInteractive
    coreutils
    gnused
    git
    openssh
    virt-viewer
  ];

  src = builtins.path { path = ./.; inherit name; };
  phases = [ "installPhase" ];

  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin

    cp -r "${src}/scripts/${name}.sh" $out

    install \
    -m0755 \
    $out/${name}.sh \
    -D \
    $out/bin/${name}

    patchShebangs $out/bin/${name}

    wrapProgram $out/bin/${name} \
      --prefix PATH : "${pkgs.lib.makeBinPath propagatedNativeBuildInputs }"
  '';

}
