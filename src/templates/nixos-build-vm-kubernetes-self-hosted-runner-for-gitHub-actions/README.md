# github self-hosted runner using kubernetes in NixOS QEMU


0) Generating a token:
- https://github.com/settings/tokens
- with these checks: https://github.com/myoung34/docker-github-actions-runner/wiki/Usage#token-scope


1)
```bash
rm -fv nixos.qcow2; 
nix run --impure --refresh --verbose '.#'
```


2) Copie e cole no terminal da VM e EDITE com seu PAT gerado no passo anterior:
```bash
GITHUB_PAT=ghp_yyyyyyyyyyyyyyy
```

3) Copie e cole no terminal da VM:
```bash
NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.9.3" \
--version "0.9.3"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ES-Nix/es"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.9.3" \
--version "0.9.3"

wk8s
```


4) Verifique que o runner aparece no link:
https://github.com/ES-Nix/es/actions/runners?tab=self-hosted


5) No terminal do clone local (apenas para testes manuais) do repositório:
```bash
export GH_TOKEN=
```

Note: o remoto tenta iniciar a execução com o código que está no REMOTO, ou seja,
modificações apenas locais não são executadas.

6) Executando manualmente um workflow:
```bash
gh workflow run tests.yml --ref feature/k8s
```
Refs.:
- https://docs.github.com/en/enterprise-server@3.11/actions/using-workflows/manually-running-a-workflow?tool=cli#running-a-workflow

Pelo navegador:
https://github.com/ES-Nix/github-action-nix-flake/actions


Links:
- https://docs.github.com/en/enterprise-server@3.11/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller
- https://github.com/actions/actions-runner-controller/discussions/2775
- https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller#about-actions-runner-controller
- https://docs.github.com/en/enterprise-server@3.11/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/using-actions-runner-controller-runners-in-a-workflow#about-using-arc-runners-in-a-workflow-file
- https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller#assets-and-releases
- https://github.com/actions/runner/blob/9e3e57ff90c089641a3a5833c2211841da1a37f8/images/Dockerfile 
- https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/removing-self-hosted-runners



## DinD


Copie e cole no terminal da VM e EDITE com seu PAT:
```bash
GITHUB_PAT=ghp_yyyyyyyyyyyyyyy
```


###


```bash
cd "$HOME" \
&& git clone https://github.com/actions/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout 80d848339e5eeaa6b2cda3c4a5393dfcb4614794

cat << 'EOF' > enables-dind.patch
diff --git a/charts/gha-runner-scale-set/values.yaml b/charts/gha-runner-scale-set/values.yaml
index 6018b7d..d4ab3c2 100644
--- a/charts/gha-runner-scale-set/values.yaml
+++ b/charts/gha-runner-scale-set/values.yaml
@@ -75,8 +75,8 @@ githubConfigSecret:
 ##
 ## If any customization is required for dind or kubernetes mode, containerMode should remain
 ## empty, and configuration should be applied to the template.
-# containerMode:
-#   type: "dind"  ## type can be set to dind or kubernetes
+containerMode:
+  type: "dind"  ## type can be set to dind or kubernetes
 #   ## the following is required when containerMode.type=kubernetes
 #   kubernetesModeWorkVolumeClaim:
 #     accessModes: ["ReadWriteOnce"]
@@ -139,7 +139,9 @@ template:
   ##         - --group=$(DOCKER_GROUP_GID)
   ##       env:
   ##         - name: DOCKER_GROUP_GID
-  ##           value: "123"
+  ##           value: "131"
+  ##         - name: DOCKER_IPTABLES_LEGACY
+  ##           value: "1"
   ##       securityContext:
   ##         privileged: true
   ##       volumeMounts:

EOF

git apply enables-dind.patch \
&& rm -v enables-dind.patch


NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.9.3" \
--version "0.9.3"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ES-Nix/es"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.9.3" \
--version "0.9.3"

wk8s
```




```bash
cat << 'EOF' > "$HOME"/values.yaml
githubConfigUrl: ""

githubConfigSecret:
  github_token: ""

template:
  spec:
    initContainers:
    - name: init-dind-externals
      image: ghcr.io/actions/actions-runner:2.319.1
      command: ["cp", "-r", "-v", "/home/runner/externals/.", "/home/runner/tmpDir/"]
      volumeMounts:
        - name: dind-externals
          mountPath: /home/runner/tmpDir
    containers:
    - name: runner
      image: ghcr.io/actions/actions-runner:2.319.1
      command: ["/home/runner/run.sh"]
      env:
        - name: DOCKER_HOST
          value: unix:///var/run/docker.sock
      volumeMounts:
        - name: work
          mountPath: /home/runner/_work
        - name: dind-sock
          mountPath: /var/run
    - name: dind
      image: docker:27.1.2-dind-alpine3.20
      args:
        - dockerd
        - --host=unix:///var/run/docker.sock
        - --group=$(DOCKER_GROUP_GID)
      env:
        - name: DOCKER_GROUP_GID
          value: "131"
        - name: DOCKER_IPTABLES_LEGACY
          value: "1"
      securityContext:
        privileged: true
      volumeMounts:
        - name: work
          mountPath: /home/runner/_work
        - name: dind-sock
          mountPath: /var/run
        - name: dind-externals
          mountPath: /home/runner/externals
    volumes:
    - name: work
      emptyDir: {}
    - name: dind-sock
      emptyDir: {}
    - name: dind-externals
      emptyDir: {}
  spec:
    containers:
      - name: runner
        image: ghcr.io/actions/actions-runner:2.319.1
        command: ["/home/runner/run.sh"]
EOF


NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.9.3" \
--version "0.9.3"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ES-Nix/es"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values "$HOME"/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.9.3" \
--version "0.9.3"

wk8s
```


After the pod starts:
```bash
kubectl exec --namespace arc-runners -it arc-runner-set-xpj4v-runner-ghl4s -- bash 
```


Inside the container:
```bash
docker images
```



As an git patch:
```bash
cd "$HOME" \
&& git clone https://github.com/emesar/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout 01abfdd45cc5c96711d9fdd31323787b8d1abc88

cat << 'EOF' > enables-dind.patch
diff --git a/charts/gha-runner-scale-set/values.yaml b/charts/gha-runner-scale-set/values.yaml
index d1c8216..590873d 100644
--- a/charts/gha-runner-scale-set/values.yaml
+++ b/charts/gha-runner-scale-set/values.yaml
@@ -1,3 +1,4 @@
+
 ## githubConfigUrl is the GitHub url for where you want to configure runners
 ## ex: https://github.com/myorg/myrepo or https://github.com/myorg
 githubConfigUrl: ""
@@ -75,8 +76,8 @@ githubConfigSecret:
 ##
 ## If any customization is required for dind or kubernetes mode, containerMode should remain
 ## empty, and configuration should be applied to the template.
-# containerMode:
-#   type: "dind"  ## type can be set to dind or kubernetes
+containerMode:
+  type: "dind"  ## type can be set to dind or kubernetes
 #   ## the following is required when containerMode.type=kubernetes
 #   kubernetesModeWorkVolumeClaim:
 #     accessModes: ["ReadWriteOnce"]
@@ -125,22 +126,22 @@ template:
   ##       command: ["/home/runner/run.sh"]
   ##       env:
   ##         - name: DOCKER_HOST
-  ##           value: unix:///run/docker/docker.sock
+  ##           value: unix:///var/run/docker.sock
   ##       volumeMounts:
   ##         - name: work
   ##           mountPath: /home/runner/_work
   ##         - name: dind-sock
-  ##           mountPath: /run/docker
+  ##           mountPath: /var/run
   ##           readOnly: true
   ##     - name: dind
   ##       image: docker:dind
   ##       args:
   ##         - dockerd
-  ##         - --host=unix:///run/docker/docker.sock
+  ##         - --host=unix:///var/run/docker.sock
   ##         - --group=$(DOCKER_GROUP_GID)
   ##       env:
   ##         - name: DOCKER_GROUP_GID
-  ##           value: "123"
+  ##           value: "131"
   ##         - name: DOCKER_IPTABLES_LEGACY
   ##           value: "1"
   ##       securityContext:
@@ -149,7 +150,7 @@ template:
   ##         - name: work
   ##           mountPath: /home/runner/_work
   ##         - name: dind-sock
-  ##           mountPath: /run/docker
+  ##           mountPath: /var/run
   ##         - name: dind-externals
   ##           mountPath: /home/runner/externals
   ##     volumes:

EOF

git apply enables-dind.patch \
&& rm -v enables-dind.patch


NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.9.0" \
--version "0.9.0"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ES-Nix/es"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values "$HOME"/actions-runner-controller/charts/gha-runner-scale-set/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.9.0" \
--version "0.9.0"

wk8s
```


### ?


```bash
NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.9.3" \
--version "0.9.3"


cat << 'EOF' > values.yaml
githubConfigUrl: ""

githubConfigSecret:
  github_token: ""

## maxRunners is the max number of runners the autoscaling runner set will scale up to.
maxRunners: 5

## minRunners is the min number of idle runners. The target number of runners created will be
## calculated as a sum of minRunners and the number of jobs assigned to the scale set.
minRunners: 0

template:
  spec:
    initContainers:
    - name: init-dind-externals
      image: ghcr.io/actions/actions-runner:2.319.1
      command: ["cp", "-r", "-v", "/home/runner/externals/.", "/home/runner/tmpDir/"]
      volumeMounts:
        - name: dind-externals
          mountPath: /home/runner/tmpDir
    containers:
    - name: runner
      image: ghcr.io/actions/actions-runner:2.319.1
      command: ["/home/runner/run.sh"]
      env:
        - name: DOCKER_HOST
          value: unix:///var/run/docker.sock
      volumeMounts:
        - name: work
          mountPath: /home/runner/_work
        - name: dind-sock
          mountPath: /var/run
    - name: dind
      image: docker:27.1.2-dind-alpine3.20
      args:
        - dockerd
        - --host=unix:///var/run/docker.sock
        - --group=$(DOCKER_GROUP_GID)
      env:
        - name: DOCKER_GROUP_GID
          value: "131"
        - name: DOCKER_IPTABLES_LEGACY
          value: "1"          
      securityContext:
        privileged: true
      volumeMounts:
        - name: work
          mountPath: /home/runner/_work
        - name: dind-sock
          mountPath: /var/run
        - name: dind-externals
          mountPath: /home/runner/externals
    volumes:
    - name: work
      emptyDir: {}
    - name: dind-sock
      emptyDir: {}
    - name: dind-externals
      emptyDir: {}
EOF


INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ES-Nix/es"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values "$HOME"/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.9.3" \
--version "0.9.3"

wk8s
```

```bash
kubectl exec --namespace arc-runners -it arc-gha-rs-controller-5f79dc8687-lpdx6 -- bash
```


```bash
docker \
run \
-it \
--rm \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
docker:27.1.2-dind-alpine3.20 \
sh \
-c \
'docker images'
```



https://datawookie.dev/blog/2024/04/dind-in-github-actions/


### O mais simples (que deveria funcionar!)

https://docs.github.com/en/enterprise-server@3.10/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/deploying-runner-scale-sets-with-actions-runner-controller#using-docker-in-docker-or-kubernetes-mode-for-containers

```bash
# 1f9b7541e6545a9d5ffa052481a84aad7ba4aa4d
cd "$HOME" \
&& git clone https://github.com/actions/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout 4357525445b0b77388af4e1f171b5b7bd9b116a4

cat << 'EOF' > enables-dind.patch
diff --git a/charts/gha-runner-scale-set/values.yaml b/charts/gha-runner-scale-set/values.yaml
index 021fecb..b474e88 100644
--- a/charts/gha-runner-scale-set/values.yaml
+++ b/charts/gha-runner-scale-set/values.yaml
@@ -75,8 +75,8 @@ githubConfigSecret:
 ##
 ## If any customization is required for dind or kubernetes mode, containerMode should remain
 ## empty, and configuration should be applied to the template.
-# containerMode:
-#   type: "dind"  ## type can be set to dind or kubernetes
+containerMode:
+  type: "dind"  ## type can be set to dind or kubernetes
 #   ## the following is required when containerMode.type=kubernetes
 #   kubernetesModeWorkVolumeClaim:
 #     accessModes: ["ReadWriteOnce"]

EOF

git apply enables-dind.patch
rm -v enables-dind.patch


NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.9.0" \
--version "0.9.0"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ES-Nix/es"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values "$HOME"/actions-runner-controller/charts/gha-runner-scale-set/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.9.0" \
--version "0.9.0"

wk8s
```


### Pina versões


docker:dind -> docker:24.0.7-dind-alpine3.18  
actions-runner:latest -> actions-runner:2.311.0

image.dindSidecarRepositoryAndTag
https://github.com/actions/actions-runner-controller/issues/3159#issuecomment-1857989007


TODO: `dindSidecarRepositoryAndTag: "docker:24.0.7-dind-alpine3.18"`
https://github.com/actions/actions-runner-controller/issues/3159#issuecomment-1860616220

https://github.com/actions/actions-runner-controller/issues/3159#issuecomment-1864952928

```bash
cd "$HOME" \
&& git clone https://github.com/actions/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout 1f9b7541e6545a9d5ffa052481a84aad7ba4aa4d

cat << 'EOF' > enables-dind.patch
diff --git a/charts/gha-runner-scale-set/values.yaml b/charts/gha-runner-scale-set/values.yaml
index 021fecb..3cbb9f6 100644
--- a/charts/gha-runner-scale-set/values.yaml
+++ b/charts/gha-runner-scale-set/values.yaml
@@ -75,8 +75,8 @@ githubConfigSecret:
 ##
 ## If any customization is required for dind or kubernetes mode, containerMode should remain
 ## empty, and configuration should be applied to the template.
-# containerMode:
-#   type: "dind"  ## type can be set to dind or kubernetes
+containerMode:
+  type: "dind"  ## type can be set to dind or kubernetes
 #   ## the following is required when containerMode.type=kubernetes
 #   kubernetesModeWorkVolumeClaim:
 #     accessModes: ["ReadWriteOnce"]
@@ -133,7 +133,7 @@ template:
   ##           mountPath: /run/docker
   ##           readOnly: true
   ##     - name: dind
-  ##       image: docker:dind
+  ##       image: docker:24.0.7-dind-alpine3.18
   ##       args:
   ##         - dockerd
   ##         - --host=unix:///run/docker/docker.sock
@@ -190,7 +190,7 @@ template:
   spec:
     containers:
       - name: runner
-        image: ghcr.io/actions/actions-runner:latest
+        image: ghcr.io/actions/actions-runner:2.311.0
         command: ["/home/runner/run.sh"]
 
 ## Optional controller service account that needs to have required Role and RoleBinding
 
EOF

git apply enables-dind.patch
rm -v enables-dind.patch


NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.8.1" \
--version "0.8.1"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ORG/REPO"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values ~/actions-runner-controller/charts/gha-runner-scale-set/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.8.1" \
--version "0.8.1"

wk8s
```


```bash
kubectl get pods -n arc-systems
kubectl get pods -n arc-runners
```

```bash
kubectl -n arc-systems get pod arc-runner-set-754b578d-listener -o yaml
kubectl -n arc-systems get pod arc-gha-rs-controller-58d944bbdb-rkdzh -o yaml
```


Muda de `+  type: "dind"` para `+  type: ""`
Ver: https://github.com/actions/actions-runner-controller/issues/3159#issuecomment-1869454029

```bash
cd "$HOME" \
&& git clone https://github.com/actions/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout 1f9b7541e6545a9d5ffa052481a84aad7ba4aa4d

cat << 'EOF' > enables-dind.patch
diff --git a/charts/gha-runner-scale-set/values.yaml b/charts/gha-runner-scale-set/values.yaml
index 021fecb..3cbb9f6 100644
--- a/charts/gha-runner-scale-set/values.yaml
+++ b/charts/gha-runner-scale-set/values.yaml
@@ -75,8 +75,8 @@ githubConfigSecret:
 ##
 ## If any customization is required for dind or kubernetes mode, containerMode should remain
 ## empty, and configuration should be applied to the template.
-# containerMode:
-#   type: "dind"  ## type can be set to dind or kubernetes
+containerMode:
+  type: ""  ## type can be set to dind or kubernetes
 #   ## the following is required when containerMode.type=kubernetes
 #   kubernetesModeWorkVolumeClaim:
 #     accessModes: ["ReadWriteOnce"]
@@ -133,7 +133,7 @@ template:
   ##           mountPath: /run/docker
   ##           readOnly: true
   ##     - name: dind
-  ##       image: docker:dind
+  ##       image: docker:24.0.7-dind-alpine3.18
   ##       args:
   ##         - dockerd
   ##         - --host=unix:///run/docker/docker.sock
@@ -190,7 +190,7 @@ template:
   spec:
     containers:
       - name: runner
-        image: ghcr.io/actions/actions-runner:latest
+        image: ghcr.io/actions/actions-runner:2.311.0
         command: ["/home/runner/run.sh"]
 
 ## Optional controller service account that needs to have required Role and RoleBinding
 
EOF

git apply enables-dind.patch
rm -v enables-dind.patch


NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.8.1" \
--version "0.8.1"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ORG/REPO"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values ~/actions-runner-controller/charts/gha-runner-scale-set/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.8.1" \
--version "0.8.1"

wk8s
```



#### Expanção do template manualmente


TODO: WIP
- https://github.com/actions/actions-runner-controller/issues/2967#issuecomment-1790955550
- https://github.com/actions/actions-runner-controller/issues/2967#issuecomment-1846987624
- https://helm.sh/docs/chart_template_guide/debugging/


Copie e cole no terminal da VM e EDITE com seu PAT:
```bash
GITHUB_PAT=ghp_yyyyyyyyyyyyyyy
```


```bash
cd "$HOME" \
&& git clone https://github.com/actions/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout 1f9b7541e6545a9d5ffa052481a84aad7ba4aa4d

cat << 'EOF' > ~/actions-runner-controller/charts/gha-runner-scale-set/values.yaml
## githubConfigUrl is the GitHub url for where you want to configure runners
## ex: https://github.com/myorg/myrepo or https://github.com/myorg
githubConfigUrl: ""

## githubConfigSecret is the k8s secrets to use when auth with GitHub API.
## You can choose to use GitHub App or a PAT token
githubConfigSecret:
  ### GitHub PAT Configuration
  github_token: ""

## template is the PodSpec for each runner Pod
## For reference: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#PodSpec
template:
  spec:
    initContainers:
    - name: init-dind-externals
      image: ghcr.io/actions/actions-runner:2.311.0
      command: ["cp", "-r", "-v", "/home/runner/externals/.", "/home/runner/tmpDir/"]
      volumeMounts:
        - name: dind-externals
          mountPath: /home/runner/tmpDir
    containers:
    - name: runner
      image: ghcr.io/actions/actions-runner:2.311.0
      command: ["/home/runner/run.sh"]
      env:
        - name: DOCKER_HOST
          value: unix:///var/run/docker.sock
      volumeMounts:
        - name: work
          mountPath: /home/runner/_work
        - name: dind-sock
          mountPath: /var/run
          readOnly: true
    - name: dind
      image: docker:24.0.7-dind-alpine3.18
      args:
        - dockerd
        - --host=unix:///var/run/docker.sock
        - --group=$(DOCKER_GROUP_GID)
      env:
        - name: DOCKER_GROUP_GID
          value: "123"
      securityContext:
        privileged: true
      volumeMounts:
        - name: work
          mountPath: /home/runner/_work
        - name: dind-sock
          mountPath: /var/run
        - name: dind-externals
          mountPath: /home/runner/externals
    volumes:
    - name: work
      emptyDir: {}
    - name: dind-sock
      emptyDir: {}
    - name: dind-externals
      emptyDir: {}
    #controllerServiceAccount:
    #  namespace: arc-systems
    #  name: arc-gha-rs-controller
EOF


NAMESPACE="arc-systems"
helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.8.1" \
--version "0.8.1"

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ORG/REPO"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values ~/actions-runner-controller/charts/gha-runner-scale-set/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.8.1" \
--version "0.8.1"

wk8s
```
Refs.:
- https://docs.github.com/en/enterprise-server@3.11/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/deploying-runner-scale-sets-with-actions-runner-controller#using-docker-in-docker-mode



```bash
kubectl get pods -n arc-systems
kubectl get pods -n arc-runners
```



### Tentativa de reproduzir o que é feito no vídeo


[GitHub Actions: Dive into actions-runner-controller (ARC) || Advanced installation & configuration](https://www.youtube.com/watch?v=_F5ocPrv6io)

> Bem complicado pinar cada coisa de modo exatamente igual!

```bash
cd "$HOME" \
&& git clone https://github.com/actions/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout e0a7e142e0fcd446c58e7875d4d44a7eea6e72f2


mkdir -pv ~/arc-configuration/{controller,runner-scale-set-1,runner-scale-set-2} \
&& cd ~/arc-configuration


cd ~/actions-runner-controller/charts \
&& cp -v actions-runner-controller/values.yaml ~/arc-configuration/controller \
&& cp -v gha-runner-scale-set/values.yaml ~/arc-configuration/runner-scale-set-1 \
&& cp -v gha-runner-scale-set/values.yaml  ~/arc-configuration/runner-scale-set-2
```


```bash
cd "$HOME" \
&& git clone https://github.com/actions/actions-runner-controller.git \
&& cd actions-runner-controller \
&& git checkout e0a7e142e0fcd446c58e7875d4d44a7eea6e72f2

cat << 'EOF' > pin-tags-and-dind.patch
diff --git a/charts/gha-runner-scale-set/values.yaml b/charts/gha-runner-scale-set/values.yaml
index bbd58ac..8c2db90 100644
--- a/charts/gha-runner-scale-set/values.yaml
+++ b/charts/gha-runner-scale-set/values.yaml
@@ -68,8 +68,8 @@ githubConfigSecret:
 #       key: ca.crt
 #   runnerMountPath: /usr/local/share/ca-certificates/
 
-# containerMode:
-#   type: "dind"  ## type can be set to dind or kubernetes
+containerMode:
+  type: "dind"  ## type can be set to dind or kubernetes
 #   ## the following is required when containerMode.type=kubernetes
 #   kubernetesModeWorkVolumeClaim:
 #     accessModes: ["ReadWriteOnce"]
@@ -158,7 +158,7 @@ template:
   spec:
     containers:
     - name: runner
-      image: ghcr.io/actions/actions-runner:latest
+      image: ghcr.io/actions/actions-runner:2.306.0
       command: ["/home/runner/run.sh"]
 
 ## Optional controller service account that needs to have required Role and RoleBinding
EOF

git pin-tags-and-dind.patch
rm -v pin-tags-and-dind.patch


NAMESPACE="arc-systems"

helm install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
    --set image.tag="0.4.0" \
    --version "0.4.0" 

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ORG/REPO"

helm install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
    --set image.tag="0.4.0" \
    --version "0.4.0" 
    
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ORG/REPO"

helm \
install \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
--values ~/actions-runner-controller/charts/gha-runner-scale-set/values.yaml \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.4.0" \
--version "0.4.0" 
    
wk8s
```



#### Kaniko


https://some-natalie.dev/blog/kaniko-in-arc/
https://snyk.io/blog/building-docker-images-kubernetes/

Modifiquei adicionando o PersistentVolume. Excelentes explicações:
https://stackoverflow.com/a/74372350
https://stackoverflow.com/a/44891419

```bash
NAMESPACE="arc-systems"

helm \
install \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller


#INSTALLATION_NAME="arc-runner-set"
#NAMESPACE="arc-runners"
#GITHUB_CONFIG_URL="https://github.com/ORG/REPO"
#
#helm install "${INSTALLATION_NAME}" \
#    --namespace "${NAMESPACE}" \
#    --create-namespace \
#    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
#    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
#    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set


cat > k8s-storage.yml << 'EOF'
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: k8s-mode
  namespace: test-runners # just showing the test namespace
provisioner: file.csi.azure.com
allowVolumeExpansion: true # probably not strictly necessary
reclaimPolicy: Delete
mountOptions:
 - dir_mode=0777 # this mounts at a directory needing this
 - file_mode=0777
 - uid=1000 # match your pod's user id, this is for actions/actions-runner
 - gid=1000
 - mfsymlinks
 - cache=strict
 - actimeo=30
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: "k8s-mode"
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/home/runner/_work"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-k8s-cache-pvc
  namespace: test-runners
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: k8s-mode # we'll need this in the runner Helm chart

EOF


kubectl create namespace test-runners
kubectl apply -f k8s-storage.yml


cat > helm-kaniko.yml << 'EOF'
template:
  spec:
    initContainers: # needed to set permissions to use the PVC
    - name: kube-init
      image: ghcr.io/actions/actions-runner:latest
      command: ["sudo", "chown", "-R", "runner:runner", "/home/runner/_work"]
      volumeMounts:
      - name: work
        mountPath: /home/runner/_work
    containers:
      - name: runner
        image: ghcr.io/actions/actions-runner:latest
        command: ["/home/runner/run.sh"]
        env:
          - name: ACTIONS_RUNNER_CONTAINER_HOOKS
            value: /home/runner/k8s/index.js
          - name: ACTIONS_RUNNER_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER
            value: "false"  # allow non-container steps, makes life easier
        volumeMounts:
          - name: work
            mountPath: /home/runner/_work

containerMode:
  type: "kubernetes" 
  kubernetesModeWorkVolumeClaim:
    accessModes: ["ReadWriteOnce"]
    storageClassName: "k8s-mode"
    resources:
      requests:
        storage: 1Gi
EOF


INSTALLATION_NAME="kaniko-worker"
NAMESPACE="test-runners"
GITHUB_CONFIG_URL="https://github.com/ORG/REPO"

helm install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    -f helm-kaniko.yml \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
    --set image.tag="0.8.1" \
    --version "0.8.1"

wk8s
```


```bash
provisioner: kubernetes.io/example
```

```bash
    nodeSelector:
      kubernetes.io/hostname: nixos 
```

### Testando DinD via Docker


TODO: ajudar nessa issue?
https://github.com/actions/actions-runner-controller/issues/2696#issuecomment-1701155470

```bash
docker run --device=/dev/kvm -d -t \
--name=action-container --rm \
-v /var/run/docker.sock:/var/run/docker.sock \
summerwind/actions-runner-dind:v2.308.0-ubuntu-22.04 tail -f /dev/null

docker exec -it action-container /bin/bash -c 'cat /etc/os-release
```


```bash
docker run --device=/dev/kvm -d -t \
--name=action-container --rm \
-v /var/run/docker.sock:/var/run/docker.sock \
docker:24.0.7-dind-alpine3.18 tail -f /dev/null

docker exec -it action-container /bin/sh \
-c 'docker run -it --rm alpine cat /etc/os-release'
```


```bash
docker run --device=/dev/kvm -d -t \
--name=action-container --rm \
-v /var/run/docker.sock:/var/run/docker.sock \
ghcr.io/actions/actions-runner:2.311.0 tail -f /dev/null

docker exec -it action-container /bin/sh \
-c 'docker run -it --rm alpine cat /etc/os-release'
```

TODO: hardening e security
https://github.com/actions/actions-runner-controller/issues/1288


### helm install --dry-run --debug



```bash
NAMESPACE="arc-systems"

helm \
install \
--dry-run \
arc \
--namespace "${NAMESPACE}" \
--create-namespace \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
--set image.tag="0.8.1" \
--version "0.8.1" \
-o yaml > gha-runner-scale-set-controller.yml
```


Quebrado!
```bash
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/ORG/REPO"


helm \
install \
--dry-run \
"${INSTALLATION_NAME}" \
--namespace "${NAMESPACE}" \
--create-namespace \
--set githubConfigUrl="${GITHUB_CONFIG_URL}" \
--set githubConfigSecret.github_token="${GITHUB_PAT}" \
oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
--set image.tag="0.8.1" \
--version "0.8.1" \
-o yaml > gha-runner-scale-set.yml
```



```bash
kubectl create namespace arc-runners
kubectl create secret generic pre-defined-secret \
--namespace=arc-runners \
--from-literal=github_token="${GITHUB_PAT}"
```


```bash
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"

helm uninstall "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" 
```


