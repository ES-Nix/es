



List:
- https://thenewstack.io/nixos-a-combination-linux-os-and-package-manager/
- https://joshrosso.com/c/nix-k8s/
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=82&end=112&version=3), 
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1532&end=1950&version=3), ?
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1950&end=2052&version=3), start=1950&end=2052
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1997&end=2052&version=3),



              #              systemd.services.kubelet-custom-bootstrap = {
              #                description = "Boostrap Custom Kubelet";
              #                wantedBy = [ "kubernetes.target" ];
              #                after = [ "docker.service" "network.target" ];
              #                path = with pkgs; [ docker ];
              #                script =
              #                  let
              #                    myCustomImage =
              #                      let
              #                        conf = {
              #                          nginxWebRoot = pkgs.writeTextDir "index.html"
              #                            ''
              #                              <html>
              #                                <body>
              #                                  <center>
              #                                  <marquee><h1>all ur PODZ is belong to ME</h1></marquee>
              #                                  <img src=\"https://m.media-amazon.com/images/M/MV5BYjBlODg3ZTgtN2ViNS00MDlmLWIyMTctZmQ2NWYwMzE2N2RmXkEyXkFqcGdeQVRoaXJkUGFydHlJbmdlc3Rpb25Xb3JrZmxvdw@@._V1_.jpg\" width=\"100%\">
              #                                  </center>
              #                                </body>
              #                              </html>\n
              #                            '';
              #
              #                          nginxPort = "80";
              #                          nginxConf = pkgs.writeText "nginx.conf" ''
              #                            user nobody nobody;
              #                            daemon off;
              #                            error_log /dev/stdout info;
              #                            pid /dev/null;
              #                            events {}
              #                            http {
              #                              access_log /dev/stdout;
              #                              server {
              #                                listen ${conf.nginxPort};
              #                                index index.html;
              #                                location / {
              #                                  root ${conf.nginxWebRoot};
              #                                }
              #                              }
              #                            }
              #                          '';
              #                        };
              #                      in
              #                      pkgs.dockerTools.buildLayeredImage {
              #                        name = "joshrosso";
              #                        tag = "1.4";
              #                        contents = [ pkgs.fakeNss pkgs.nginx ];
              #
              #                        extraCommands = ''
              #                          mkdir -p tmp/nginx_client_body
              #
              #                          # nginx still tries to read this directory even if error_log
              #                          # directive is specifying another file :/
              #                          mkdir -p var/log/nginx
              #                        '';
              #                        config = {
              #                          Cmd = [ "nginx" "-c" conf.nginxConf ];
              #                          ExposedPorts = { "${conf.nginxPort}/tcp" = { }; };
              #                        };
              #                      };
              #                  in
              #                  ''
              #                    echo "Seeding docker image..."
              #                    docker load <"${myCustomImage}"
              #                  '';
              #                serviceConfig = {
              #                  Slice = "kubernetes.slice";
              #                  Type = "oneshot";
              #                };
              #              };


                  # https://discourse.nixos.org/t/nixpkgs-support-for-linux-builders-running-on-macos/24313/2
                  virtualisation.forwardPorts = [
                    {
                      from = "host";
                      # host.address = "127.0.0.1";
                      host.port = 8090;
                      # guest.address = "34.74.203.201";
                      guest.port = 30163;
                    }
                  ];


```bash
cat > joshrosso-kubecon.yml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: a-message
  namespace: default
spec:
  containers:
  - name: message
    image: joshrosso/kubecon:1.4
    ports:
    - containerPort: 80
EOF

#kubectl get --raw='/livez'
#kubectl get --raw='/readyz'
kubectl apply -f joshrosso-kubecon.yml
wk8s
```


```bash
kubectl port-forward --address 0.0.0.0 pods/a-message 8080:80
```

