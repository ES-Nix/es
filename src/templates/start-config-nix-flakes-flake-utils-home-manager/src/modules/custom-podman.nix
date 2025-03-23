{ config, pkgs, lib, modulesPath, ... }:
with lib;
{

  virtualisation.podman = {
    enable = true;
    # Creates a `docker` alias for podman, to use it as a drop-in replacement
    # Note: se usado juntamente com o docker isso causa conflito
    dockerCompat = false;
    # TODO: parece quebrado
    # podman system service --time=0 unix:///tmp/podman.sock &
    # curl -s --unix-socket /tmp/podman.sock http://d/v1.0.0/libpod/info
    # https://medium.com/devops-dudes/how-to-setup-root-less-podman-containers-efd109fa4e0d
    # dockerSocket.enable = true;
  };

  #  environment.etc."containers/registries.conf" = {
  #    mode = "0644";
  #    text = ''
  #      [registries.search]
  #      registries = ['docker.io', 'localhost']
  #    '';
  #  };

}
