






```nix
  services.nginx.enable = true;
  services.nginx.virtualHosts."fooo" = {
    locations."/" = {
      root = "${pkgs.runCommand "testdir" {} ''
          mkdir "$out"
          echo '<h2>hello world</h2>' > "$out/index.html"
          echo '<h3>574e9081-0cf3-435c-afd9-f0d2c16e409a</h3>' >> "$out/index.html"
        ''
      }";
    };
  };
```


TODO: write NixOS tests!
```bash
127.0.0.1
127.0.0.1/
http://127.0.0.1
http://127.0.0.1/

localhost
localhost/
http://localhost
http://localhost/
```


```nix
# May be good to use
services.nginx.recommendedGzipSettings = true;
services.nginx.recommendedOptimisation = true;
services.nginx.recommendedProxySettings = true;
services.nginx.recommendedTlsSettings = true;
```

```nix
services.nginx.logError = ''stderr emerg'';
```

Or
```nix
services.nginx.logError = ''/dev/null emerg'';
```
Refs.:
- https://nixos.wiki/wiki/Talk:Nginx



TODO: Substitute the html package rendered:
```nix
root = "${pkgs.glowing-bear}";
```


TODO: make custom package using overlays.


## 


List:
- https://thenewstack.io/nixos-a-combination-linux-os-and-package-manager/
- https://joshrosso.com/c/nix-k8s/
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=82&end=112&version=3), 
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1532&end=1950&version=3), ?
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1950&end=2052&version=3), start=1950&end=2052
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1997&end=2052&version=3),


```bash
firefox localhost:8080

curl -k localhost:8080
curl -k 127.0.0.1:8080
curl -k 0.0.0.0:8080
```



```bash
python3 -m http.server 8090

lsof -t -i tcp:8090 -s tcp:listen
lsof -t -i tcp:8090 -s tcp:listen
```



```bash
ps -ww -fp $(lsof -t -i tcp:8080 -s tcp:listen)
```
Refs.:
- https://stackoverflow.com/questions/821837/how-to-get-the-command-line-args-passed-to-a-running-process-on-unix-linux-syste#comment639663_821889
-

