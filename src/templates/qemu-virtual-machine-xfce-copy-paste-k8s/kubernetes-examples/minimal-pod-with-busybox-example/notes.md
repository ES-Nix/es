

```bash
cd ~/kubernetes-examples/minimal-pod-with-busybox-example \
&& kubectl apply \
-f minimal-pod-with-busybox-example.yaml
```

```bash
wk8s
```



```bash
cat > minimal-pod-with-busybox-example.yaml <<-'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-pod
    image: busybox
    command: ['sh', '-c', "while ! false; do echo $(date +'%d/%m/%Y %H:%M:%S:%3N'); sleep 1; done"]
EOF

sudo -E kubectl apply -f minimal-pod-with-busybox-example.yaml
```

```bash
wk8s
```


```bash
docker pull python:3.11.9-alpine3.20
```

