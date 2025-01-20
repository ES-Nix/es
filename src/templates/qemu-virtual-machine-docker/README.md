


```bash
nix \
run \
--refresh \
--override-input \
nixpkgs \
github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
github:ES-nix/es#installQEMUVirtualMachineDockerTemplate \
&& ((direnv &>/dev/null ) && direnv deny QEMUVirtualMachineDocker || true) \
&& cd QEMUVirtualMachineDocker

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm

chmod -v 0600 id_ed25519

ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -L | grep -q "$(cat id_ed25519.pub)") || ssh-add -v id_ed25519

ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null;

#while ! ssh -o ConnectTimeout=1 -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true' ; do 
#  echo $(date +'%d/%m/%Y %H:%M:%S:%3N')
#  sleep 1
#done

for i in {1..500}; do
  ssh -o ConnectTimeout=1 -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true' \
  && break
  
  ! $((i % 5)) && echo $(date +'%d/%m/%Y %H:%M:%S:%3N')
  sleep 0.2
done


direnv allow
nix develop .# --command docker images
```


```bash
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
.#nixosConfigurations.vm.config.system.build.vm
```

```bash
direnv deny

chmod -v 0600 id_ed25519

ssh-add -l 1> /dev/null 2> /dev/null || eval $(ssh-agent -s)
# There could be an race condition in here?
(ssh-add -l | grep -q "$(cat id_ed25519.pub)") || ssh-add id_ed25519

ssh-keygen -R '[localhost]:10022' 1>/dev/null 2>/dev/null;
for i in web{0..60};do ssh -oStrictHostKeyChecking=accept-new -p 10022 nixuser@localhost -- sh -c 'true':
sleep 1;
echo $(date +'%d/%m/%Y %H:%M:%S:%3N');
done;
direnv allow
docker images

# ssh-keyscan -H -p 10022 -t ecdsa localhost >> ~/.ssh/known_hosts
```

https://stackoverflow.com/a/73644766


nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659



```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/alpine:3.19.1

RUN apk update \
 && apk \
        add \
        --no-cache \
        ca-certificates \
        curl \
        shadow \
 && mkdir -pv -m 0700 /home/abcuser \
 && addgroup abcgroup --gid 4455 \
 && adduser \
        -g '"An unprivileged user with an group"' \
        -D \
        -h /home/abcuser \
        -G abcgroup \
        -u 3322 \
        abcuser \
 && echo \
 && apk del shadow

# If it is uncommented nix profile works!
RUN mkdir -pv -m 1735 /nix/var/nix && chown -Rv abcuser:abcgroup /nix

ENV PATH=/home/abcuser/.nix-profile/bin:/home/abcuser/.local/bin:"$PATH"

USER abcuser
WORKDIR /home/abcuser
ENV USER="abcuser"
ENV NIX_CONFIG="extra-experimental-features = nix-command flakes"

ENV HYDRA_BUILD_ID=257665509
ENV NIXPKGS_COMMIT=58a1abdbae3217ca6b702f03d3b35125d88a2994

RUN mkdir -pv "$HOME"/.local/bin \
 && cd "$HOME"/.local/bin \
 && curl -L https://hydra.nixos.org/build/"$HYDRA_BUILD_ID"/download-by-type/file/binary-dist > nix \
 && chmod -v +x nix \
 && nix flake --version \
 && nix \
      registry \
      pin \
      nixpkgs github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
 && nix \
    run \
    --refresh \
    --override-input \
    nixpkgs \
    github:NixOS/nixpkgs/219951b495fc2eac67b1456824cc1ec1fd2ee659 \
    github:ES-nix/es#installQEMUVirtualMachineDockerTemplate \
 && cd QEMUVirtualMachineDocker \
 && nix develop '.#' --command 'true' \
 && nix \
    build \
    --print-build-logs \
    --print-out-paths \
    '.#nixosConfigurations.vm.config.system.build.vm' \
 && nix \
    store \
    gc \
    --verbose \
    --option keep-build-log false \
    --option keep-derivations false \
    --option keep-env-derivations false \
    --option keep-failed false \
    --option keep-going false \
    --option keep-outputs false \
 && nix store optimise --verbose
EOF


podman \
build \
--file=Containerfile \
--tag=alpine-with-static-nix .


podman \
run \
--device=/dev/kvm:rw \
--interactive=true \
--tty=true \
--rm=true \
localhost/alpine-with-static-nix:latest \
sh \
-l
```


```bash
docker \
run \
--device=/dev/kvm:rw \
--interactive=true \
--tty=true \
--rm=true \
--user=app_user:app_group \
--workdir=/home/app_user \
vm-no-graphical-oci-image:0.0.1 \
sh 
```


foo