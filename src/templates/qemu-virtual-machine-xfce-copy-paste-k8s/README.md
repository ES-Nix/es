


```bash
mkdir -v k8s \
&& cd $_ \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#QEMUVirtualMachineXfceCopyPasteK8s
(direnv allow &> /dev/null ) || true

nix profile install nixpkgs#git

git init && git add .

rm -fv nixos.qcow2; 
nix \
run \
--impure \
--verbose \
'.#'
```
Refs.:
- 


```bash
nix flake show '.#'

nix build --cores 5 --no-link --print-build-logs --print-out-paths '.#'

nix flake check --verbose '.#'
```


22.05
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/380be19fbd2d9079f677978361792cb25e8a3635 \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
````

22.11
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
````

23.05
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/70bdadeb94ffc8806c0570eb5c2695ad29f0e421 \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
````

23.11
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/a5e4bbcb4780c63c79c87d29ea409abf097de3f7 \
--override-input flake-utils github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725
```

24.05
805a384895c696f802a9bf5bf4720f37385df547
```bash
nix \
flake \
lock \
--override-input nixpkgs github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8 \
--override-input flake-utils github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a
```

```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#
```




```bash
file /var/lib/kubernetes/secrets/apitoken.secret
```

```bash
sudo -E kubectl get pods -n kube-system --field-selector status.phase=Running
```
Refs.:
- https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/

### 


If you are on metal you might need something like this:
```bash
rm -fr /var/lib/kubernetes/secrets /var/lib/cfssl/*
```

TODO: explain why!

The NixOS tests do it like this:
```bash
boot.postBootCommands = "rm -fr /var/lib/kubernetes/secrets";
```


```bash
nix \
eval \
--json \
nixpkgs#nixosTests.kubernetes.dns-single-node.config.nodes.machine1.services.kubernetes.pki.etcClusterAdminKubeconfig


nix \
eval \
--json \
nixpkgs#nixosTests.kubernetes.dns-single-node.config.nodes.machine1.services.kubernetes.pki.certs.clusterAdmin
```


#### swap, zramSwap


```nix
# swapon -s
# https://discourse.nixos.org/t/zramswap-enable-true-does-nothing/6734/5
zramSwap = {
  enable = true;
  algorithm = "zstd";
};
```


```nix
# Did not work!
# cat /proc/sys/vm/swappiness
swapDevices = lib.mkForce [{
  device = "/var/lib/swapfile";
  size = 4 * 1024;
}];
```


#### the wiki recomendations


It is broken!
```bash
services.kubernetes.easyCerts = true;
services.kubernetes.masterAddress = "api.kube";
services.kubernetes.apiserverAddress = "http://api.kube:6443";
```


This is what you need:
```bash
services.kubernetes.roles = [ "master" "node" ];
services.kubernetes.masterAddress = "${config.networking.hostName}";
environment.variables.KUBECONFIG = "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}";
# services.kubernetes.kubelet.extraOpts = "--fail-swap-on=false"; # If you use swap it is an must!
```


#### etcd errors

```bash
journalctl -u etcd.service -b \
| grep 'open /var/lib/kubernetes/secrets/etcd.pem' -c
```

```bash
journalctl -p 3 -xb | grep -q 'Failed to start etcd key-value store.'
```

Did an PR about it:
https://github.com/NixOS/nixpkgs/pull/321339

```nix
systemd.services.etcd.unitConfig.ConditionPathExists = "/var/lib/kubernetes/secrets/etcd.pem";
```

```bash
# https://github.com/NixOS/nixpkgs/issues/124037#issuecomment-846538656
systemd.services.etcd.preStart = ''${pkgs.writeShellScript "etcd-wait" ''
 while [ ! -f /var/lib/kubernetes/secrets/etcd.pem ]; do sleep 0.1; done
''}'';
```


#### The cluster-admin-key.pem permissions


https://github.com/NixOS/nixpkgs/pull/321632


#### certmgr and cfssl failures


```bash
journalctl -u certmgr.service -b | cat
journalctl -u cfssl.service -b | cat

journalctl -u certmgr.service -b | grep 'level=error' -c
journalctl -u certmgr.service -b | grep 'failed to verify certificate: x509: certificate signed by unknown authority' -c


systemctl show cfssl.service | cat
systemctl list-dependencies cfssl.service


journalctl cat certmgr.service 
journalctl -u cfssl.service -b | cat
```



```bash
journalctl \
--unit cfssl.service \
--boot \
--catalog \
--no-pager \
--full \
--priority=err \
--output="json" \
--output-fields="MESSAGE"
```

```bash
journalctl \
--unit certmgr.service \
--boot \
--catalog \
--no-pager \
--full \
--priority=err \
--output="json" \
--output-fields="MESSAGE"
```


```bash
journalctl --unit cfssl.service --boot --catalog --no-pager --full \
| grep -F 'open /var/lib/kubernetes/secrets' -c
```

```bash
journalctl --unit certmgr.service --boot --catalog --no-pager --full \
| grep -F 'open /var/lib/kubernetes/secrets' -c
```


```bash
ls -l --time-style=full-iso /var/lib/kubernetes/secrets/
ls -l --time-style=full-iso /var/lib/cfssl
```



```bash
/var/lib/kubernetes/secrets/etcd-key.pem
/var/lib/kubernetes/secrets/flannel-client.pem


# /var/lib/kubernetes/secrets/cluster-admin.pem
# /var/lib/kubernetes/secrets/etcd.pem
# /var/lib/kubernetes/secrets/flannel-client.pem
/var/lib/kubernetes/secrets/kube-addon-manager.pem
/var/lib/kubernetes/secrets/kube-apiserver-etcd-client.pem
/var/lib/kubernetes/secrets/kube-apiserver-kubelet-client.pem
/var/lib/kubernetes/secrets/kube-apiserver-proxy-client.pem
/var/lib/kubernetes/secrets/kube-apiserver.pem 
/var/lib/kubernetes/secrets/kube-controller-manager-client.pem
/var/lib/kubernetes/secrets/kube-controller-manager.pem
/var/lib/kubernetes/secrets/kube-proxy-client.pem
# /var/lib/kubernetes/secrets/kube-scheduler-client.pem
/var/lib/kubernetes/secrets/kubelet-client.pem 
/var/lib/kubernetes/secrets/kubelet.pem
# /var/lib/kubernetes/secrets/service-account.pem
```



TODO: why it fails in the begining?
```bash
curl -k https://nixos:8888/api/v1/cfssl/health
```


```bash
journalctl \
--unit etcd.service \
--boot \
--catalog \
--no-pager \
--full \
--priority=err \
 --output="json" \
--output-fields="MESSAGE"
```



```bash
openssl s_client -showcerts -connect nixos:8888
```

```bash
journalctl \
--unit certmgr.service \
--boot \
MESSAGE="Failed to start certmgr." \
--quiet \
--grep=.
```


```bash
journalctl \
--unit etcd.service \
--boot \
MESSAGE="Failed to start etcd key-value store." \
--quiet \
--grep=.


systemctl status etcd.service
systemctl status certmgr.service
```


```nix
systemd.services.certmgr.environment = { GODEBUG = "x509ignoreCN=0"; } // (config.services.certmgr.environment or {});
```

```nix
              # sudo journalctl -u investigate-k8s.service -b -o json
              systemd.services.investigate-k8s = {
                script = ''
                  CLUSTER_ADMIN_KEY_PATH=/var/lib/kubernetes/secrets/cluster-admin-key.pem

                  while ! test -L /var/lib/kubernetes/secrets/apitoken.secret; do
                    date +'%d/%m/%Y %H:%M:%S:%3N' \
                    && sleep 0.1
                  done

                  # chmod 0640 -v "$CLUSTER_ADMIN_KEY_PATH"
                  # chown root:kubernetes -v "$CLUSTER_ADMIN_KEY_PATH"
                '';
                wantedBy = [ "multi-user.target" ];
              };
```

```nix
systemd.services.certmgr.after = [ "cfssl.service" ];
```

```nix
  # while ! ${pkgs.curl}/bin/curl -k https://nixos:8888/api/v1/cfssl/health; do sleep 0.1; done
  systemd.services.certmgr.preStart = ''${pkgs.writeShellScript "certmgr-wait" ''

    # while [ ! -f /var/lib/kubernetes/secrets/kubelet-client.pem ]; do date --rfc-3339=seconds --utc && sleep 0.1; done
    while [ ! test -L /var/lib/kubernetes/secrets/apitoken.secret ]; do
      date --rfc-3339=seconds --utc && sleep 0.1;
    done

    # sleep 10

    while [ ! -f /etc/ssl/certs/ca-bundle.crt ]; do
      date --rfc-3339=seconds --utc && sleep 0.1;
    done

  ''}'';
```

#### TODO: regenerating certificates

```bash
sudo su -
```

```bash
kubeadm init phase certs ca

kubeadm \
init \
phase \
kubeconfig admin \
--cert-dir /etc/kubernetes/pki/
```


```bash
systemctl restart kubelet

kubeadm \
init \
phase \
kubeconfig admin \
--config /etc/kubernetes/cluster-admin.kubeconfig \
--cert-dir /var/lib/kubernetes/secrets/


kubectl get cm kube-root-ca.crt -n kube-system -o yaml
openssl x509 -in /var/lib/kubernetes/secrets/ca.pem -text -noout

echo \
| openssl s_client -connect nixos:6443 -servername api 2>/dev/null \
| openssl x509 -noout -enddate


kubeadm certs check-expiration \
--cert-dir /var/lib/kubernetes/secrets

--apiserver-advertise-address=10.0.2.15 \

--client-name system:node:$(hostname) \
```


```bash
kubeadm init phase kubeconfig admin \
--apiserver-advertise-address=0.0.0.0 \
--cert-dir /etc/kubernetes/pki
```


```bash
kubectl \
get \
nodes \
-o \
jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' 
```




```bash
unset KUBECONFIG

mkdir -p $HOME/.kube \
&& sudo cp -v /etc/kubernetes/admin.conf "$HOME"/.kube/config \
&& sudo chown -Rv $(id -u):$(id -g) $HOME/.kube/

kubectl cluster-info
```


```bash
kubectl delete --all pods --namespace=kube-system
```

```bash
sudo systemctl list-dependencies kubernetes.target
```


```bash
sudo ln -s /etc/kubernetes/cluster-admin.kubeconfig "$HOME"/.kube/config
sudo chown -Rv nixuser: "$HOME"/.kube/config
kubectl cluster-info
```


TODO: it is broken
```bash
mkdir -pv ~/.kube \
&& sudo cp -v /etc/kubernetes/cluster-admin.kubeconfig ~/.kube/config \
&& sudo chmod -v 0600 ~/.kube/config \
&& sudo chown -Rv $(id -u):$(id -g) ~/.kube

cat /home/nixuser/.kube/config | jq

kubectl cluster-info
```

Why it uses filepaths and not embeds the content like in Ubuntu?
```bash
/var/lib/kubernetes/secrets/ca.pem

/var/lib/kubernetes/secrets/cluster-admin.pem

/var/lib/kubernetes/secrets/cluster-admin-key.pem
```


```bash
kubeadm init phase certs ca

kubeadm init phase kubeconfig admin \
--cert-dir /etc/kubernetes/pki/
```

kubeadm init 

```bash
kubeadm init phase kubeconfig admin \
--apiserver-advertise-address 10.0.0.1 \
--cert-dir /etc/kubernetes/pki/
```


```bash
mkdir -p $HOME/.kube \
&& sudo cp -v /etc/kubernetes/admin.conf "$HOME"/.kube/config \
&& sudo chown -Rv $(id -u):$(id -g) $HOME/.kube/
```







### What about the nixosTests


```bash
cat $(nix eval nixpkgs#path)/nixos/tests/kubernetes/base.nix
```


```bash
nix \
eval \
--json \
--apply builtins.attrNames \
nixpkgs#nixosTests.kubernetes.dns-single-node.config.nodes.machine1.services.kubernet
```

```bash
nix \
eval \
--raw \
nixpkgs#nixosTests.kubernetes.dns-single-node.config.nodes.machine1.boot.postBootCommands
```


```bash
nix run nixpkgs#nixosTests.kubernetes.dns-single-node.driverInteractive
```

```bash
machine1.shell_interact()
```

```bash
ls -alh /var/lib/kubernetes/secret
```



```bash
nix \
build \
--no-link \
nixpkgs#nixosTests.kubernetes.dns-single-node \
nixpkgs#nixosTests.kubernetes.dns-multi-node \
nixpkgs#nixosTests.kubernetes.rbac-single-node \
nixpkgs#nixosTests.kubernetes.rbac-multi-node

nix \
build \
--no-link \
--rebuild \
nixpkgs#nixosTests.kubernetes.dns-single-node \
nixpkgs#nixosTests.kubernetes.dns-multi-node \
nixpkgs#nixosTests.kubernetes.rbac-single-node \
nixpkgs#nixosTests.kubernetes.rbac-multi-node
```
Refs.:
- https://github.com/NixOS/nixpkgs/pull/60415



RBAC
```bash
nix run nixpkgs#nixosTests.kubernetes.rbac-multi-node.driverInteractive
```

### Ubuntu VM instalation

It was tested using Vagrant and Ubuntu 24.04
```bash
sudo swapoff -a

sudo apt-get update \
&& sudo apt-get install -y \
     apt-transport-https \
     curl

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo apt-get update \
&& sudo apt install -y \
     kubelet \
     kubeadm \
     kubectl \
&& sudo apt-get install -y docker.io \
&& sudo systemctl enable docker

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 \
&& mkdir -p $HOME/.kube \
&& sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config \
&& sudo chown $(id -u):$(id -g) $HOME/.kube/config \
&& kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml 


kubectl get nodes

watch kubectl get pod --all-namespaces -o wide
```
Refs.:
- https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/
- https://www.liquidweb.com/blog/kubernetes-on-bare-metal/
- https://medium.com/@zomev/guide-to-bare-metal-kubernetes-everything-you-need-to-know-e15aedf013a3


TODO: how to make it persist after reboot?
```bash
swapon --show
cat /proc/swaps
```


####  

```bash
git clone https://github.com/justmeandopensource/kubernetes.git
cd kubernetes/vagrant-provisioning
vagrant up --provider libvirt
```


#### Other TODOs

```nix
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
    nixPath = [ "nixpkgs=${pkgs.path}" ];
  };
  environment.etc."channels/nixpkgs".source = "${pkgs.path}";
```



TODO:
```nix
   environment.etc."containers/registries.conf" = {
     mode = "0644";
     text = ''
       [registries.search]
       registries = ['docker.io', 'localhost', 'us-docker.pkg.dev', 'gcr.io']
     '';
   };
   # nix eval --impure --json \
   # '.#nixosConfigurations.vm.config.services.kubernetes.kubelet.seedDockerImages'
   services.kubernetes.kubelet.seedDockerImages = (with pkgs; [
     cachedOCIImage1
     cachedOCIImage2
     cachedOCIImage3
     cachedOCIImage4
     cachedOCIImage5
   ]);
```


