

https://blog.appsignal.com/2024/08/07/an-introduction-to-nix-for-ruby-developers.html
https://github.com/bobvanderlinden/nixpkgs-ruby?tab=readme-ov-file#devenvsh
https://notes.burke.libbey.me/debugging-nix-ruby/
https://github.com/fly-apps/rails-nix



Bundle for Ruby
Cabal for Haskel
Cargo for Rust
Gradle for Java Android
Maven for Clojure
Poetry for Python
Yarn for Node.js


Flutter:
- https://www.reddit.com/r/NixOS/comments/1ab77ht/flutter_on_nixos/
- https://github.com/babariviere/flutter-nix-hello-world/issues/32#issuecomment-2021526992




nix flake metadata github:the-sun-will-rise-tomorrow/nix/docker-user
2403b73203f2d6f93b43585f736a1f5462808b1e


mkdir vue-poc \
&& cd vue-poc \
&& 


```bash
bun create vue@latest \
&& cd vue-project \
&& bun install \
&& bun dev
```
Refs.:
- https://vuejs.org/guide/quick-start


```bash
yarn create vite hello-vue3 --template vue \
&& cd hello-vue3 \
&& yarn \
&& yarn build \
&& yarn dev
```



```bash
mkdir example-vue3 \
&& cd  example-vue3 \
&& yarn create vue my-project --template vue-ts --no-prompt

yarn create hello-vue3 --template vue \
&& cd hello-vue3 \
&& yarn \
&& yarn build \
&& yarn dev
```


```bash
docker run --name some-nginx -p 8080:80 -v ./dist:/usr/share/nginx/html:ro -d docker.io/library/nginx:1.27.2-alpine
```

```bash
firefox http://localhost:8080/

curl -s http://localhost:8080 | grep -q -e '<title>Vite + Vue</title>
```


```bash
nix \
flake \
lock \
--override-input nixpkgs 'github:NixOS/nixpkgs/aa4e34969baa92fcc227f880d82b1f5a6cc1d343' \
--override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'

nix build --no-link --print-build-logs --print-out-paths '.#'
```


TODO:
- https://discourse.nixos.org/t/yarn-plugnplay-and-direnv-packaging/19759/30
- https://all-dressed-programming.com/posts/nix-yarn/





```bash
yarn create vite hello-vue3 --template vue \
&& cd hello-vue3 \
&& yarn \
&& rm -r node_modules \
&& cat > flake.nix << '_EOF'
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
          distPhase = ":";
        };
        frontend = pkgs.stdenv.mkDerivation {
          name = "frontend";
          src = ./.;
          buildInputs = with pkgs; [ yarn vite nodeModules ];
          buildPhase = ''
            runHook preConfigure
        
            # Yarn writes cache directories etc to $HOME.
            export HOME=$(mktemp -d)
 
            ln -s ${nodeModules}/libexec/hello-vue3/node_modules node_modules

            yarn config --offline set yarn-offline-mirror ${nodeModules}

            yarn --verbose --offline build

            runHook postConfigure
          '';
          installPhase =  ''
            mkdir -v $out
            cp -R dist/* $out
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
&& git add . \
&& nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
&& git add . \
&& nix build --no-link --print-build-logs --print-out-paths '.#'
```


```bash
yarn create vite hello-vue3-ts --template vue-ts \
&& cd hello-vue3-ts \
&& yarn add -D vue-tsc \
&& rm -r node_modules \
&& cat > flake.nix << '_EOF'
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
          distPhase = ":";
        };
        frontend = pkgs.stdenv.mkDerivation {
          name = "frontend";
          src = ./.;
          buildInputs = with pkgs; [ yarn vite nodePackages.typescript nodeModules ];
          buildPhase = ''
            runHook preConfigure
        
            # Yarn writes cache directories etc to $HOME.
            export HOME=$(mktemp -d)
 
            ln -s ${nodeModules}/libexec/hello-vue3-ts/node_modules node_modules

            yarn config --offline set yarn-offline-mirror ${nodeModules}

            yarn --verbose --offline build

            runHook postConfigure
          '';
          installPhase =  ''
            mkdir -v $out
            cp -R dist/* $out
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

sed -i 's/vue-tsc -b/vue-tsc --noEmit/g' package.json \
&& git init \
&& git add . \
&& nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/d063c1dd113c91ab27959ba540c0d9753409edf3' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
&& git add . \
&& nix build --no-link --print-build-logs --print-out-paths '.#'
```
Refs.:
- https://github.com/microsoft/TypeScript/issues/53979

Extra Refs.:
- https://ajmasia.me/en/posts/2024/nestjs-dev-environment-with-nix/


Details about `yarn import`, well it did not work when bootstrapping:
- https://classic.yarnpkg.com/blog/2018/06/04/yarn-import-package-lock/
- https://www.arahansen.com/the-ultimate-guide-to-yarn-lock-lockfiles/


TODO: try to make it work, imperatively it worked but tests are broken!

http://localhost:3000/

https://github.com/mterrel/nest-nix


TODO: help there
https://discourse.nixos.org/t/building-docker-image-using-nix-for-a-nestjs-project/39139



```bash
mkdir myapp \
&& cd myapp \
&& yarn add express

cat > app.js << '_EOF'
const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
_EOF

node app.js
```
Refs.:
- https://expressjs.com/en/starter/hello-world.html
- 

nix \
shell \
--impure \
--expr \
'
(let pkgs = (builtins.getFlake "github:NixOS/nixpkgs").legacyPackages.${builtins.currentSystem}; in pkgs.buildFHSUserEnv (pkgs.appimageTools.defaultFhsEnvArgs // { name = "fhs"; profile = "export FHS=1"; runScript = "bash"; targetPkgs = pkgs: (with pkgs; [ hello cowsay ]); }))
' \
--command \
fhs \
-c \
'hello | cowsay'