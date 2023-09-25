{ config, pkgs, lib, modulesPath, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.flask ]);

  pythonScript = pkgs.writeScriptBin "test-push-to-s3" ''
    #!${python}/bin/python3

    import argparse


    def main():
        parser = argparse.ArgumentParser()
        parser.add_argument('stuff', nargs='+')
        args = parser.parse_args()
        print args.stuff

      if __name__ == '__main__':
          main()
  '';
in
with lib;
{


  environment.systemPackages = with pkgs; [

    figlet
    sqlite

    awscli
    # aws-iam-authenticator

    gcc

    (
      writeScriptBin "generating-a-private-public-keypair" ''
        #! ${pkgs.runtimeShell} -e
        # https://nixos.wiki/wiki/Binary_Cache

        cd /var
        sudo sh -c "
        nix-store --generate-binary-cache-key binarycache.example.com cache-priv-key.pem cache-pub-key.pem
        chown nixuser cache-priv-key.pem
        chmod 0600 cache-priv-key.pem
        cat cache-pub-key.pem
        "
      ''
    )

    (
      writeScriptBin "test-binary-cache-0" ''
        #! ${pkgs.runtimeShell} -e
        curl http://binarycache.example.com/nix-cache-info
      ''
    )

    (
      writeScriptBin "test-binary-cache-1" ''
        #! ${pkgs.runtimeShell} -e

        cd
        nix build --no-link --print-build-logs nixpkgs#hello

        OUT_HELLO_PATH=$(nix build --no-link --print-out-paths nixpkgs#hello | cut -d'/' -f4 | cut -d'-' -f1)

        curl http://binarycache.example.com/$OUT_HELLO_PATH.narinfo
      ''
    )

    (
      writeScriptBin "watch-for-processes-from-nixblders" ''
        #! ${pkgs.runtimeShell} -e
        exec bash -c "while ! false; do clear && echo $(date +'%d/%m/%Y %H:%M:%S:%3N') && ps -u "$(echo nixbld{1..32})"; sleep 0.5; done)"
      ''
    )

  ];

  systemd.services.populate-history = {
    script = ''
      echo "Started"

      echo "while ! false; do clear && echo $(date +'%d/%m/%Y %H:%M:%S:%3N') && ps -u \"\$(echo nixbld{1..32})\"; sleep 0.5; done" >> /home/nixuser/.zsh_history

      chown -v nixuser:nixgroup /home/nixuser/.zsh_history

      echo "Ended"
    '';
    wantedBy = [ "multi-user.target" ];
  };



  networking.hostName = mkForce "binarycache";
  networking.domain = "example.com";

  services.nginx = {
    enable = true;
    virtualHosts = {
      # ... existing hosts config etc. ...
      "binarycache.example.com" = {
        serverAliases = [ "binarycache" ];
        locations."/".extraConfig = ''
          proxy_pass http://localhost:${toString config.services.nix-serve.port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };


  # journalctl -f -u nix-serve.service
  # journalctl -xefu nix-serve
  services.nix-serve = {
    enable = true;

    # :lf .#
    # :p nixosConfigurations.build-vm-nix-server.options.services.nix-serve.secretKeyFile.value
    secretKeyFile = "/etc/nix/private-key";
  };

  #  services.nix-serve.enable = true;
  #  services.nix-serve.openFirewall = true;
  #  # services.nix-serve.port = 5000; # This is the default port.
  #  services.nix-serve.secretKeyFile = "/home/nixuser/.ssh";

  # nix.trustedUsers -> nix.settings.trusted-users
  # https://github.com/NixOS/nix/issues/2330#issuecomment-451650296
  nix.settings.trusted-users = [ "root" "@wheel" "nixuser" ];

  # nix build --print-build-logs --no-link --rebuild nixpkgs#hello
  # nix-store --query --requisites --include-outputs $(nix path-info --derivation nixpkgs#hello)
  # xargs nix path-info --derivation
  #
  # nix-store --query --requisites --include-outputs --force-realise
  # http://sandervanderburg.blogspot.com/2014/07/backing-up-nix-and-hydra-builds.html
  #
  # CACHE=s3://playing-bucket-nix-cache-test/
  # nix copy --no-check-sigs --eval-store auto -vvvv --to "$CACHE"
  #
  # echo 'a B a' | grep -v -e '[[:upper:]]'
  #
  # https://github.com/NixOS/nix/issues/4665#issuecomment-1270644790
  nix.settings.post-build-hook = pkgs.writeScript "custom-pbh" ''
    #! ${pkgs.runtimeShell} -e

      set -x

      KEY_FILE=/etc/nix/private-key
      # Testar ?region=eu-west-1
      CACHE=s3://playing-bucket-nix-cache-test/

      echo "post-build-hook"
      echo "-- ''${OUT_PATHS} --"
      echo "^^ ''${DRV_PATH} ^^"

      # mapfile -t DERIVATIONS < <(echo "''${OUT_PATHS[@]}" | xargs nix path-info --derivation)
      mapfile -t DEPENDENCIES < <(echo "''${OUT_PATHS[@]}" | xargs nix path-info --recursive)
      # mapfile -t DERIVATIONS < <(echo "''${OUT_PATHS[@]}" | xargs nix path-info)

      # mapfile -t DEPENDENCIES < <(echo "''${DRV_PATH[@]}" | xargs nix-store --query --requisites --include-outputs --force-realise)
      # mapfile -t DEPENDENCIES < <(echo "''${DRV_PATH[@]}" | xargs nix-store --query --requisites --include-outputs)
      # mapfile -t DEPENDENCIES < <(echo "''${DRV_PATH[@]}" | xargs nix-store --query --outputs)

      # TODO: é o correto assinar as derivações, os .drv?
      # echo "''${DERIVATIONS[@]}" | xargs nix store sign --key-file "$KEY_FILE" --recursive

      # TODO:
      echo "''${DEPENDENCIES[@]}" | xargs nix store sign -vvvv --key-file "$KEY_FILE" --recursive

      echo "''${DEPENDENCIES[@]}" | xargs nix store verify --recursive --sigs-needed 1

      echo "''${DEPENDENCIES[@]}" | xargs nix copy --eval-store auto -vvv --to "$CACHE"

      # echo "''${DEPENDENCIES[@]}" | xargs nix copy --eval-store auto -vvv --to "$CACHE"
      # echo "''${DEPENDENCIES[@]}" | xargs nix copy --eval-store auto --no-check-sigs -vvv --to "$CACHE"

      # echo "''${DEPENDENCIES[@]}" | xargs nix copy --eval-store auto -vvvv --to "$CACHE"?region=us-east-1\&secret-key=/etc/nix/private-key

  '';


  services.qemuGuest.enable = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ]; # in terminal: nixos-option boot.binfmt.emulatedSystems

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;


}
