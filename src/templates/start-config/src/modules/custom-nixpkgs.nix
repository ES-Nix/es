{ config, pkgs, lib, modulesPath, ... }:
with lib;
{

  nixpkgs.config.allowUnfree = true;

  # TODO: it is related to
  # https://discourse.nixos.org/t/confusion-about-tarball-ttl-and-its-default-value/20998/2
  #
  # https://github.com/NixOS/nixpkgs/issues/62832#issuecomment-500135970
  # no need to inject `nixpkgs.overlays` here, this will be done by NixOS
  # nixpkgs.pkgs = import "${pkgs.nixpkgs}" {
  #   inherit (config.nixpkgs) config;
  # };

  # TODO: hardening
  #nixpkgs.config.permittedInsecurePackages = [
  #"libgit2-0.27.10"
  #];

}
