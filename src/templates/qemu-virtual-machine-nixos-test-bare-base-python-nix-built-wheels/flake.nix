{
  description = "A flake for testing nix in a NixOS virtual machine using QEMU. It includes a test that starts a NixOS VM and checks if it can run the nix command and access the nix store. It also provides an interactive driver for manual testing and a shell with the necessary tools to run the tests.";

  /*
    # 25.11
    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/f560ccec6b1116b22e6ed15f4c510997d99d5852' \
    --override-input flake-utils 'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b'  
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (final: prev: {
        fooBar = prev.hello;

        wheelsELFs =
          let
            # pyPkgsNames = [
            #   "numpy"
            #   "pandas"
            #   "scipy"
            #   # "scikit-learn"
            #   "matplotlib"
            #   "seaborn"
            #   "plotly"
            #   # "tensorflow"
            #   "torch"
            # ];

            pyPkgsNames = [
              "mmh3"
              # "absl-py"
              # "adal"
              # "aenum"
              # "aiobotocore"
              # "aiohttp"
              # "aioitertools"
              # "aiosignal"
              # "alembic"
              # "altair"
              # # "annotated-types"
              # "anthropic"
              # "anyio"
              # "appdirs"
              # "argcomplete"
              # # "argon2-cffi"
              # # "argon2-cffi-bindings"
              # "arrow"
              # "asgiref"
              # # "asn1crypto"
              # "astroid"
              # "asttokens"
              # # "async-timeout"
              # "attrs"
              # "babel"
              # "backoff"
              # "bcrypt"
              # "beautifulsoup4"
              # "behave"
              # "black"
              # "bleach"
              # "blinker"
              # "boto3"
              # "botocore"
              # "build"
              # "cachecontrol"
              # "cachetools"
              # "cattrs"
              # # "certifi"
              # "cffi"
              # "chardet"
              # # "charset-normalizer"
              # "chromadb"
              # "cleo"
              # "click"
              # "cloudpickle"
              # "colorama"
              # "comm"
              # "contourpy"
              # "coverage"
              # "crashtest"
              # "croniter"
              # "cryptography"
              # "cycler"
              # "cython"
              # # "dataclasses-json"
              # "datadog"
              # "debugpy"
              # "decorator"
              # "defusedxml"
              # "deprecated"
              # "dill"
              # "distlib"
              # "distro"
              # "django"

              # "django-cors-headers"
              # "django-debug-toolbar"
              # "django-polymorphic"
              # "django-rest-polymorphic"
              # "django-storages"
              # "djangorestframework"
              # "djangorestframework-simplejwt"
              # "dnspython"
              # "docker"
              # "docutils"
              # "drf-spectacular"
              # "dulwich"
              # "einops"
              # "elasticsearch"
              # "email-validator"
              # "et-xmlfile"
              # "exceptiongroup"
              # "execnet"
              # "executing"
              # "factory-boy"
              # "faker"
              # "fastapi"
              # "fastjsonschema"
              # "filelock"
              # "flake8"
              # "flask"
              # "flatbuffers"
              # "folium"
              # "fonttools"
              # "freezegun"
              # "frozenlist"
              # "fsspec"
              # "geopandas"
              # "gitdb"
              # "gitpython"
              # "google-api-core"
              # "google-api-python-client"
              # "google-auth"
              # "google-auth-httplib2"
              # "google-auth-oauthlib"
              # "google-cloud-appengine-logging"
              # "google-cloud-bigquery"
              # "google-cloud-bigquery-storage"
              # "google-cloud-core"
              # "google-cloud-pubsub"
              # "google-cloud-secret-manager"
              # "google-cloud-storage"
              # "google-crc32c"
              # "google-pasta"
              # "google-resumable-media"
              # "googleapis-common-protos"
              # "greenlet"
              # "gremlinpython"
              # "grpc-google-iam-v1"
              # "grpcio"
              # "grpcio-status"
              # "grpcio-tools"
              # "gunicorn"
              # "h11"
              # "h5py"
              # "holidays"
              # "httpcore"
              # "httplib2"
              # "httpx"
              # "huggingface-hub"
              # "humanfriendly"
              # "idna"
              # "imageio"
              # "importlib-metadata"
              # "importlib-resources"
              # "iniconfig"
              # "installer"
              # "ipdb"
              # "ipykernel"
              # "ipython"
              # "isodate"
              # "isort"
              # "itsdangerous"
              # "jaraco-classes"
              # "jax"
              # "jedi"
              # "jeepney"
              # "jinja2"
              # "jmespath"
              # "joblib"
              # "jsonpatch"
              # "jsonpath-ng"
              # "jsonpointer"
              # "jsonschema"
              # "jsonschema-specifications"
              # "jupyter"
              # "jupyter-client"
              # "jupyter-core"
              # "jupyter-server"
              # "jupyterlab"
              # "jupyterlab-server"
              # "keyring"
              # "kiwisolver"
              # "kubernetes"
              # "langchain"
              # "loguru"
              # "lxml"
              # "mako"
              # "markdown"
              # "markdown-it-py"
              # "markupsafe"
              # "marshmallow"
              # "matplotlib"
              # "matplotlib-inline"
              # "mccabe"
              # "mdurl"
              # "mistune"
              # "monotonic"
              # "more-itertools"
              # "mpmath"
              # "msal"
              # "msal-extensions"
              # "msgpack"
              # "msrest"
              # "multidict"
              # "multiprocess"
              # "mypy-extensions"
              # "nbclient"
              # "nbconvert"
              # "nbformat"
              # "nest-asyncio"
              # "networkx"
              # "nltk"
              # "nltk"
              # "nodeenv"
              # "notebook"
              # "numpy"
              # "numpy"
              # "oauth2client"
              # "oauthlib"
              # "openai"
              # "opencv4"
              # "openpyxl"
              # "opentelemetry-api"
              # "opentelemetry-sdk"
              # "opentelemetry-semantic-conventions"
              # "orjson"
              # "oscrypto"
              # "overrides"
              # "packaging"
              # "pandas"
              # "paramiko"
              # "parso"
              # "pathspec"
              # "pbr"
              # "pendulum"
              # "pexpect"
              # "pg8000"
              # "pillow"
              # "pip"
              # "pkginfo"
              # "pkgutil-resolve-name"
              # "platformdirs"
              # "plotly"
              # "pluggy"
              # "ply"
              # "poetry-core"
              # "polars"
              # "portalocker"
              # "progressbar2"
              # "prometheus-client"
              # "prompt-toolkit"
              # "proto-plus"
              # "protobuf"
              # "psutil"
              # "psycopg2"
              # "ptyprocess"
              # "pure-eval"
              # "py"
              # "py4j"
              # "pyarrow"
              # "pyasn1"
              # "pyasn1-modules"
              # "pycodestyle"
              # "pycparser"
              # "pycryptodome"
              # "pycryptodomex"
              # "pydantic"
              # "pydantic-core"
              # "pyflakes"
              # "pygithub"
              # "pygments"
              # "pyjwt"
              # "pylint"
              # "pymongo"
              # "pymupdf"
              # "pymysql"
              # "pynacl"
              # "pyodbc"
              # "pyopenssl"
              # "pyparsing"
              # "pyproject-hooks"
              # "pyrsistent"
              # "pysocks"
              # "pyspark"
              # "python-dateutil"
              # "python-dotenv"
              # "python-json-logger"
              # "python-slugify"
              # "python-utils"
              # "pytz"
              # "# pytzdata"
              # "pyyaml"
              # "pyzmq"
              # "rapidfuzz"
              # "redis"
              # "redshift-connector"
              # "referencing"
              # "regex"
              # "requests"
              # "requests-aws4auth"
              # "requests-file"
              # "requests-oauthlib"
              # "requests-toolbelt"
              # "retry"
              # "rfc3339-validator"
              # "rich"
              # "rpds-py"
              # "rsa"
              # "ruamel-yaml"
              # "ruamel-yaml-clib"
              # "rustworkx"
              # "s3fs"
              # "s3transfer"
              # "sagemaker"
              # "scikit-learn"
              # "scikit-learn"
              # "scikit-image"
              # "scipy"
              # "scipy"
              # "scramp"
              # "seaborn"
              # "secretstorage"
              # "selenium"
              # "send2trash"
              # "sentencepiece"
              # "sentry-sdk"
              # "setuptools"
              # "setuptools-scm"
              # "shapely"
              # "shellingham"
              # "simplejson"
              # "six"
              # "slack-sdk"
              # "smart-open"
              # "smmap"
              # "sniffio"
              # "snowflake-connector-python"
              # "sortedcontainers"
              # "soupsieve"
              # "sqlalchemy"
              # "sqlparse"
              # "stack-data"
              # "starlette"
              # "structlog"
              # "sympy"
              # "tabulate"
              # "tblib"
              # "tenacity"
              # "tensorboard"
              # "termcolor"
              # "text-unidecode"
              # "threadpoolctl"
              # "tiktoken"
              # "tinycss2"
              # "tinygrad"
              # "tokenizers"
              # "toml"
              # "tomli"
              # "tomlkit"
              # "toolz"
              # "torch"
              # "tornado"
              # "tqdm"
              # "traitlets"
              # "transformers"
              # "trove-classifiers"
              # "typeguard"
              # "typer"
              # "types-python-dateutil"
              # "types-requests"
              # "typing-extensions"
              # "typing-inspect"
              # "tzdata"
              # "tzlocal"
              # "ujson"
              # "umap-learn"
              # "uritemplate"
              # "urllib3"
              # "user-agents"
              # "uvicorn"
              # "virtualenv"
              # "watchdog"
              # "wcwidth"
              # "webencodings"
              # "websocket-client"
              # "websockets"
              # "werkzeug"
              # "wheel"
              # "wrapt"
              # "xgboost"
              # "xlrd"
              # "xlsxwriter"
              # "xmltodict"
              # "yarl"
              # "zipp"
              # "zope-interface"
            ];

            f = { pyPkgName }: ''
              set +x
              pwd
              ls -alh
              WHEEL_NAME=${final.python3Packages.${pyPkgName}.dist} \
              && wheel unpack $WHEEL_NAME/* \
              && UNPAKED_WHEEL_DIRETORY_NAME=${final.python3Packages.${pyPkgName}.pname}-${final.python3Packages.${pyPkgName}.version} \
              && cd "$UNPAKED_WHEEL_DIRETORY_NAME" \
              && mkdir -p $out/"$UNPAKED_WHEEL_DIRETORY_NAME" \
              && find . -type f -iname '*.so' | wc -l
              ls -alh
              rm -frv *
              ls -alh
            '';
          in
          prev.runCommand "wheels-elfs"
            {
              nativeBuildInputs = with final; [
                # auditwheel
                # binutils.out
                # glibc.bin
                # patchelf
                # python3Packages.pip
                python3Packages.wheel
                # python3Packages.wheel-filename
                # python3Packages.wheel-inspect
                # twine

                findutils

                # python3Packages.numpy.dist
                (map (pyPkgName: final.python3Packages."${pyPkgName}".dist) pyPkgsNames)
              ];
            }
            # (f { pyPkgName = "numpy"; })
            (map (pyPkgName: f { pyPkgName = pyPkgName; }) pyPkgsNames)
        ;

        allTests = let name = "all-tests"; in final.writeShellApplication
          {
            name = name;
            runtimeInputs = with final; [ ];
            text = ''
              nix fmt . \
              && nix flake show --all-systems '.#' \
              && nix flake metadata '.#' \
              && nix build --no-link --print-build-logs --print-out-paths '.#' \
              && nix build --no-link --print-build-logs --print-out-paths --rebuild '.#' \
              && nix develop '.#' --command sh -c 'true' \
              && nix flake check --all-systems --verbose '.#'
            '';
          } // { meta.mainProgram = name; };

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
            fooBar
            wheelsELFs
            ;
          # default = pkgs.testNixOSBare;
          default = pkgs.wheelsELFs;
        };

        apps = {
          allTests = {
            type = "app";
            program = "${pkgs.lib.getExe pkgs.allTests}";
            meta.description = "Run all tests";
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          inherit (pkgs)
            wheelsELFs
            ;
          default = pkgs.wheelsELFs;
        };

        devShells.default = with pkgs; mkShell {
          packages = [
            fooBar
            wheelsELFs
          ];

          shellHook = ''
            test -d .profiles || mkdir -v .profiles
            test -L .profiles/dev \
            || nix develop --impure .# --profile .profiles/dev --command true             
          '';
        };
      }
    )
  );
}
