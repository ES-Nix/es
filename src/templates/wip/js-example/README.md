
TODO: test the wiki example

```bash
mkdir js-example
cd $_
npm install uglify-es
ls -l node_modules/.bin/
```

```bash
bun create vue@latest
```



### bcrypt



```bash
mkdir bcrypt-example \
&& cd bcrypt-example \
&& yarn init -y \
&& yarn add bcrypt

cat > test.js << _EOF
const bcrypt = require('bcrypt');

bcrypt.hash('myPlainTextPassword', 10, function(err, hash) {
  if (err) {
    console.error('Error hashing password:', err);
  } else {
    console.log('Hashed password:', hash);
  }
});
_EOF

node test.js
```


```bash
yarn \
  add \
    sqlite3 \
    argon2 \
    sharp \
    node-sass
```

```bash
yarn \
  add \
ffi-napi
```



```bash
node -v \
&& yarn -v \
&& nest -v \
&& nest new project-name --package-manager yarn \
&& cd project-name \
&& yarn run start
```
Refs.:
- https://docs.nestjs.com/cli/usages


curl http://localhost:3000/



```bash
mkdir yarn-nix-example \
&& cd yarn-nix-example \
&& yarn add lodash \
&& cat << 'EOF' > src/wui.ts
import _ from 'lodash';
let message: string = 'Hello World';
console.log(message + _.join([' ', 'a', 'b', 'c'], '~'));
EOF


cat > flake.nix << '_EOF'
{
  description = "Example of a project that integrates nix flake with yarn.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nodeModules = pkgs.mkYarnPackage {
          name = "node-modules";
          src = ./.;
        };
        frontend = pkgs.stdenv.mkDerivation {
          name = "frontend";
          src = ./.;
          buildInputs = [ pkgs.yarn nodeModules ];
          buildPhase = ''
            ln -s ${nodeModules}/libexec/yarn-nix-example/node_modules node_modules
            ${pkgs.yarn}/bin/yarn build
          '';
          installPhase =  ''
            mkdir $out
            mv dist $out/lib
          '';

        };
      in 
        {
          packages = {
            nodeModules = nodeModules;
            default = frontend;
          };
        }
    );
}
_EOF

git init \
&& git add .

nix \
flake \
lock \
--override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
--override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
&& git add . \
&& nix run nixpkgs#nodejs -- $(nix build --no-link --print-build-logs --print-out-paths .#)/lib/wui.js
```


```bash
cat > Containerfile << _EOF
FROM docker.nix-community.org/nixpkgs/nix-flakes as builder
WORKDIR /tmp/build
RUN \
--mount=type=cache,target=/nix,from=docker.nix-community.org/nixpkgs/nix-flakes,source=/nix \
--mount=type=cache,target=/root/.cache \
--mount=type=bind,target=/tmp/build \
<<EOF
nix \
  build \
  --extra-substituters http://mycache.com \
  nixpkgs#python312 \
  --out-link /tmp/output/result
nix copy /tmp/output/result --to /nix-store-closure
EOF


FROM scratch
# FROM alpine
WORKDIR /app
COPY --from=builder /nix-store-closure /
COPY --from=builder /tmp/output /app/
ENTRYPOINT ["/app/result/bin/python"]
_EOF

docker \
build \
--file=Containerfile \
--tag=python312 .

docker run -it python312 -c 'import this'
```

```bash
docker \
run \
--env=PATH=/root/.nix-profile/bin:/usr/bin:/bin \
--privileged=true \
--device=/dev/fuse \
--env="DISPLAY=${DISPLAY:-:0.0}" \
--interactive=true \
--network=host \
--mount=type=tmpfs,destination=/var/lib/containers \
--tty=true \
--rm=true \
--user=0 \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
--volume=/etc/localtime:/etc/localtime:ro \
--volume=/dev:/dev \
docker.nix-community.org/nixpkgs/nix-flakes \
bash \
-c \
'id'
```
