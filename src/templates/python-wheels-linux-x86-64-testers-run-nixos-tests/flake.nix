{
  description = "A NixOS VM that can run and test many Python wheels on Linux x86_64 using binfmt_misc";

  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/057f63b6dc1a2c67301286152eb5af20747a9cb4' \
    --override-input flake-utils 'github:numtide/flake-utils/c1dfcf08411b08f6b8615f7d8971a2bfa81d5e8a'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'

  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        foo-bar = prev.hello;

        # python3WithPackages = prev.python3.withPackages (pyPkgs: with pyPkgs; [
        # ]);
        python3WithPackages = prev.python3.withPackages (pyPkgs: with pyPkgs; [
          # apache-airflow
          # awscli
          # click-man
          # google-cloud-aiplatform
          # great-expectations
          # mysql-connector-python
          # poetry
          # poetry-plugin-export
          # psycopg2-binary
          # pyspark
          # tb-nightly
          # typedload
          # asynctest
          # snowflake-sqlalchemy
          # keras
          # pymupdf
          # tensorflow
          # langchain_community
          # langchainhub
          # keras
          mmh3
          absl-py
          adal
          aenum
          aiobotocore
          aiohttp
          aioitertools
          aiosignal
          alembic
          altair
          annotated-types
          anthropic
          anyio
          appdirs
          argcomplete
          argon2-cffi
          argon2-cffi-bindings
          arrow
          asgiref
          asn1crypto
          astroid
          asttokens
          async-timeout
          attrs
          # awswrangler
          # azure-common
          # azure-core
          # azure-identity
          # azure-storage-blob
          babel
          backoff
          bcrypt
          beautifulsoup4
          behave
          black
          bleach
          blinker
          boto3
          botocore
          build
          cachecontrol
          cachetools
          cattrs
          certifi
          cffi
          chardet
          charset-normalizer
          chromadb
          cleo
          click
          cloudpickle
          colorama
          comm
          contourpy
          coverage
          crashtest
          croniter
          cryptography
          cycler
          cython
          dataclasses-json
          datadog
          debugpy
          decorator
          defusedxml
          deprecated
          dill
          distlib
          distro
          django
          django-cors-headers
          django-debug-toolbar
          django-polymorphic
          django-rest-polymorphic
          django-storages
          djangorestframework
          djangorestframework-simplejwt
          dnspython
          docker
          docutils
          drf-spectacular
          dulwich
          einops
          elasticsearch
          email-validator
          et-xmlfile
          exceptiongroup
          execnet
          executing
          factory_boy
          faker
          fastapi
          fastjsonschema
          filelock
          flake8
          flask
          flatbuffers
          folium
          fonttools
          freezegun
          frozenlist
          fsspec
          future
          geopandas
          gitdb
          gitpython
          google-api-core
          google-api-python-client
          google-auth
          google-auth-httplib2
          google-auth-oauthlib
          google-cloud-appengine-logging
          google-cloud-bigquery
          google-cloud-bigquery-storage
          google-cloud-core
          google-cloud-pubsub
          google-cloud-secret-manager
          google-cloud-storage
          google-crc32c
          google-pasta
          google-resumable-media
          googleapis-common-protos
          greenlet
          gremlinpython
          grpc-google-iam-v1
          grpcio
          grpcio-status
          grpcio-tools
          gunicorn
          h11
          h5py
          holidays
          httpcore
          httplib2
          httpx
          huggingface-hub
          humanfriendly
          idna
          imageio
          importlib-metadata
          importlib-resources
          iniconfig
          installer
          ipdb
          ipykernel
          ipython
          isodate
          isort
          itsdangerous
          jaraco-classes
          jax
          jedi
          jeepney
          jinja2
          jmespath
          joblib
          jsonpatch
          jsonpath-ng
          jsonpointer
          jsonschema
          jsonschema-specifications
          jupyter
          jupyter-client
          jupyter-core
          jupyter-server
          jupyterlab
          jupyterlab-server
          keyring
          kiwisolver
          kubernetes
          langchain
          loguru
          lxml
          mako
          markdown
          markdown-it-py
          markupsafe
          marshmallow
          matplotlib
          matplotlib-inline
          mccabe
          mdurl
          mistune
          monotonic
          more-itertools
          mpmath
          msal
          msal-extensions
          msgpack
          msrest
          multidict
          multiprocess
          mypy-extensions
          nbclient
          nbconvert
          nbformat
          nest-asyncio
          networkx
          nltk
          nltk
          nodeenv
          notebook
          numpy
          numpy
          oauth2client
          oauthlib
          openai
          opencv4
          openpyxl
          # opensearch-py
          opentelemetry-api
          opentelemetry-sdk
          opentelemetry-semantic-conventions
          orjson
          oscrypto
          overrides
          packaging
          pandas
          paramiko
          parso
          pathspec
          pbr
          pendulum
          pexpect
          pg8000
          pillow
          pip
          pkginfo
          pkgutil-resolve-name
          platformdirs
          plotly
          pluggy
          ply
          poetry-core
          polars
          portalocker
          progressbar2
          prometheus-client
          prompt-toolkit
          proto-plus
          protobuf
          psutil
          psycopg2
          ptyprocess
          pure-eval
          py
          py4j
          pyarrow
          pyasn1
          pyasn1-modules
          pycodestyle
          pycparser
          pycryptodome
          pycryptodomex
          pydantic
          pydantic-core
          pyflakes
          pygithub
          pygments
          pyjwt
          pylint
          pymongo
          pymupdf
          pymysql
          pynacl
          pyodbc
          pyopenssl
          pyparsing
          pyproject-hooks
          pyrsistent
          pysocks
          pyspark
          # pytest
          # pytest-cov
          # pytest-runner
          # pytest-xdist
          python-dateutil
          python-dotenv
          python-json-logger
          python-slugify
          python-utils
          pytz
          # pytzdata
          pyyaml
          pyzmq
          rapidfuzz
          redis
          redshift-connector
          referencing
          regex
          requests
          requests-aws4auth
          requests-file
          requests-oauthlib
          requests-toolbelt
          retry
          rfc3339-validator
          rich
          rpds-py
          rsa
          ruamel-yaml
          ruamel-yaml-clib
          rustworkx
          s3fs
          s3transfer
          sagemaker
          scikit-learn
          scikit-learn
          scikitimage
          scikitlearn
          scipy
          scipy
          scramp
          seaborn
          secretstorage
          selenium
          send2trash
          sentencepiece
          sentry-sdk
          setuptools
          setuptools-scm
          shapely
          shellingham
          simplejson
          six
          slack-sdk
          smart-open
          smmap
          sniffio
          snowflake-connector-python
          sortedcontainers
          soupsieve
          sqlalchemy
          sqlparse
          stack-data
          starlette
          structlog
          sympy
          tabulate
          tblib
          tenacity
          tensorboard
          termcolor
          text-unidecode
          threadpoolctl
          tiktoken
          tinycss2
          tinygrad
          tokenizers
          toml
          tomli
          tomlkit
          toolz
          torch
          tornado
          tqdm
          traitlets
          transformers
          trove-classifiers
          typeguard
          typer
          types-python-dateutil
          types-requests
          typing-extensions
          typing-inspect
          tzdata
          tzlocal
          ujson
          umap-learn
          uritemplate
          urllib3
          user-agents
          uvicorn
          virtualenv
          watchdog
          wcwidth
          webencodings
          websocket-client
          websockets
          werkzeug
          wheel
          wrapt
          xgboost
          xlrd
          xlsxwriter
          xmltodict
          yarl
          zipp
          zope-interface
        ]);

        testBinfmtMany = prev.testers.runNixOSTest {
          name = "test-python-wheels";
          nodes.machine =
            { config, pkgs, lib, modulesPath, ... }:
            {

              config.virtualisation.diskSize = 1024 * 6;

              config.virtualisation.docker.enable = true;

              config.environment.systemPackages = with final; [
                python3WithPackages
              ];
            };

          globalTimeout = 1 * 60;

          testScript = { nodes, ... }: ''
            start_all()
            machine.wait_for_unit("default.target")

            machine.succeed("""
                            python3 -c 'import mmh3; assert mmh3.hash128(bytes(123)) == 126000048256919600573431412872524959502'
                            python3 -c 'import mmh3; assert mmh3.hash128(bytes(123)) == 126000048256919600573431412872524959502'
                          """)
          '';
        };

        nixos-vm = nixpkgs.lib.nixosSystem {
          system = prev.system;
          modules = [
            ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
              {
                # Internationalisation options
                i18n.defaultLocale = "en_US.UTF-8";
                console.keyMap = "br-abnt2";

                # Set your time zone.
                time.timeZone = "America/Recife";

                # Why
                # nix flake show --impure .#
                # break if it does not exists?
                # Use systemd boot (EFI only)
                boot.loader.systemd-boot.enable = true;
                fileSystems."/" = { device = "/dev/hda1"; };

                boot.binfmt.registrations = {
                  riscv64-linux = {
                    interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv64";
                    fixBinary = true;
                  };
                };

                boot.binfmt.emulatedSystems = [
                  "riscv64-linux"
                ];

                virtualisation.vmVariant =
                  {
                    virtualisation.docker.enable = true;
                    virtualisation.podman.enable = true;

                    virtualisation.memorySize = 1024 * 9; # Use MiB memory.
                    virtualisation.diskSize = 1024 * 50; # Use MiB memory.
                    virtualisation.cores = 7; # Number of cores.
                    virtualisation.graphics = true;

                    virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                    virtualisation.qemu.options = [
                      # https://www.spice-space.org/spice-user-manual.html#Running_qemu_manually
                      # remote-viewer spice://localhost:3001

                      # "-daemonize" # How to save the QEMU PID?
                      "-machine vmport=off"
                      "-vga qxl"
                      "-spice port=3001,disable-ticketing=on"
                      "-device virtio-serial"
                      "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                      "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                    ];

                    virtualisation.useNixStoreImage = false; # TODO: hardening
                    virtualisation.writableStore = true; # TODO: hardening
                  };

                /*
                # journalctl --unit docker-custom-bootstrap-1.service -b -f
                systemd.services.docker-custom-bootstrap-1 = {
                  description = "Docker Custom Bootstrap 1";
                  wantedBy = [ "multi-user.target" ];
                  after = [ "docker.service" ];
                  path = with pkgs; [ docker ];
                  script = ''
                    echo "Loading OCI Images in docker..."

                    # docker load <"${final.}"
                  '';
                  serviceConfig = {
                    Type = "oneshot";
                  };
                };
                */

                security.sudo.wheelNeedsPassword = false; # TODO: hardening
                # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
                users.extraGroups.nixgroup.gid = 999;
                users.users.nixuser = {
                  isSystemUser = true;
                  password = "1"; # TODO: hardening
                  createHome = true;
                  home = "/home/nixuser";
                  homeMode = "0700";
                  description = "The VM tester user";
                  group = "nixgroup";
                  extraGroups = [
                    "docker"
                    "wheel"
                  ];
                  packages = with pkgs; [
                    file
                    firefox
                    git
                    jq
                    lsof
                    findutils
                    foo-bar
                  ];
                  shell = pkgs.bash;
                  uid = 1234;
                  autoSubUidGidRange = true;
                };

                services.xserver.enable = true;
                services.xserver.xkb.layout = "br";
                services.displayManager.autoLogin.user = "nixuser";

                # https://nixos.org/manual/nixos/stable/#sec-xfce
                services.xserver.desktopManager.xfce.enable = true;
                services.xserver.desktopManager.xfce.enableScreensaver = false;
                services.xserver.videoDrivers = [ "qxl" ];
                services.spice-vdagentd.enable = true; # For copy/paste to work

                nix.extraOptions = "experimental-features = nix-command flakes";

                environment.systemPackages = with pkgs; [
                ];

                system.stateVersion = "25.05";
              })

            { nixpkgs.overlays = [ self.overlays.default ]; }
          ];
          specialArgs = { inherit nixpkgs; };
        };

        myvm = final.nixos-vm.config.system.build.vm;

        automatic-vm = prev.writeShellApplication {
          name = "run-nixos-vm";
          runtimeInputs = with final; [ curl virt-viewer ];
          text = ''
            export VNC_PORT=3001

            ${final.lib.getExe final.myvm} & PID_QEMU="$!"

            for _ in {0..50}; do
              if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
              then
                break
              fi
              # date +'%d/%m/%Y %H:%M:%S:%3N'
              sleep 0.1
            done;

            remote-viewer spice://localhost:"$VNC_PORT"

            kill $PID_QEMU
          '';
        };

      })
    ];
  } // (
    let
      # nix flake show --allow-import-from-derivation --impure --refresh .#
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

    in
    flake-utils.lib.eachSystem suportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            automatic-vm
            testBinfmtMany
            myvm
            ;
          default = pkgs.testBinfmtMany;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.automatic-vm}";
          meta.description = "Run the NixOS VM";
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            testBinfmtMany
            automatic-vm
            ;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            foo-bar
            python3WithPackages
          ];
        };
      }
    )
  );
}
