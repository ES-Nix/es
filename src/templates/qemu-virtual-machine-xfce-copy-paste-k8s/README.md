



              # TODO: refatorar, talvez usar self?
              environment.etc."kubernets/kubernetes-examples/minimal-pod-with-busybox-example/minimal-pod-with-busybox-example.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/minimal-pod-with-busybox-example/minimal-pod-with-busybox-example.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/minimal-pod-with-busybox-example/notes.md" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/minimal-pod-with-busybox-example/notes.md}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/deployment.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/deployment.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/service.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/service.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/ingress.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/ingress.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/notes.md" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/notes.md}";
              };

              # journalctl -u move-kubernetes-examples.service -b
              systemd.services.move-kubernetes-examples = {
                script = ''
                  echo "Started move-kubernets-examples"

                  # cp -rv ''\${./kubernetes-examples} /home/nixuser/
                  cp -Rv /etc/kubernets/kubernetes-examples/ /home/nixuser/

                  chown -Rv nixuser:nixgroup /home/nixuser/kubernetes-examples

                  kubectl \
                    apply \
                    --file /home/nixuser/kubernetes-examples/deployment.yaml \
                    --file /home/nixuser/kubernetes-examples/service.yaml \
                    --file /home/nixuser/kubernetes-examples/ingress.yaml
                '';
                wantedBy = [ "multi-user.target" ];
              };

