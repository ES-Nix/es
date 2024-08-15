{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.helloNixosTests;
in
{
  options = {
    services.helloNixosTests = {
      enable = mkEnableOption "helloNixosTests";
    };
  };

  #### Implementation

  config = mkIf cfg.enable {
    users.users.hello = {
      createHome = true;
      description = "helloNixosTests user";
      isSystemUser = true;
      group = "hello";
      home = "/srv/helloNixosTests";
    };

    users.groups.hello.gid = 1000;

    systemd.services.helloNixosTests = {
      description = "helloNixosTests server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        exec ${pkgs.helloNixosTests}/bin/hello-nixos-tests \
      '';

      serviceConfig = {
        Type = "simple";
        User = "hello";
        Group = "hello";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  };
}
