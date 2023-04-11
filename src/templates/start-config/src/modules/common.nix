{ config, pkgs, lib, modulesPath, ... }:
with lib;
{

  # https://nixos.mayflower.consulting/blog/2021/01/28/nextcloud-stateversion/
  # https://discourse.nixos.org/t/when-should-i-change-system-stateversion/1433/18
  system.stateVersion = "22.05";

  networking.hostName = "nixos"; # Define your hostname.

  # xauth list $DISPLAY
  # export XAUTHORITY=~/.Xauthority
  # watch ls -al ~/.Xauthority
  # https://superuser.com/a/936753
  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # TODO: https://www.tweag.io/blog/2020-07-31-nixos-flakes/
  # Let 'nixos-version --json' know about the Git revision of this flake.
  # system.configurationRevision = mkIf (self ? rev) self.rev;
  #system.configurationRevision =
  #  if self ? rev
  #  then self.rev
  #  else throw "Refusing to build from a dirty Git tree!";
  #
  # https://xeiaso.net/blog/nix-flakes-terraform
  # system.configurationRevision = self.sourceInfo.rev;

  # TODO: testar
  # https://www.reddit.com/r/NixOS/comments/fsummx/how_to_list_all_installed_packages_on_nixos/
  # https://discourse.nixos.org/t/can-i-inspect-the-installed-versions-of-system-packages/2763/15
  # https://functor.tokyo/blog/2018-02-20-show-packages-installed-on-nixos
  # cat /etc/current-system-packages | wc -l
  environment.etc."current-system-packages".text =
    let
      packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;

}
