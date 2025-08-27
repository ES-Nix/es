{ self, pkgs }:

pkgs.nixosTest {
  name = "hello-boots";
  nodes.machineWithHelloService = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.helloNixosModule
    ];
    services.helloNixosTests = {
      enable = true;
    };

    system.stateVersion = "24.05";
  };
  globalTimeout = 2 * 60;
  testScript = ''
    machineWithHelloService.wait_for_unit("helloNixosTests.service")
    machineWithHelloService.wait_for_open_port(3000)
  '';
}
