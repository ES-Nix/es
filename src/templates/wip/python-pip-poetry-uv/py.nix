let
  nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b");
  pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};

  customPython3 = (pkgs.python3.withPackages (pyPkgs: with pyPkgs; [

#  APScheduler
#  BTrees
#  Babel
#  BlinkStick
#  ColanderAlchemy
#  CommonMark
#  ConfigArgParse
#  EasyProcess
#  Fabric
#  FormEncode
#  GeoIP
#  GitPython
#  HAP-python
#  HTSeq
#  IMAPClient
#  JPype1
#  JayDeBeApi
#  Kajiki
#  Keras
#  Logbook
#  MDP
#  Mako
#  Markups
#  MechanicalSoup
#  Nikola
#  Nuitka
#  PasteDeploy
#  Pmw
#  Pweave
#  PyChromecast
#  PyGithub
#  PyICU
#  PyLD
#  # PyLTI
#  PyMVGLive
#  PyRSS2Gen
#  PyStemmer
#  # PyVirtualDisplay
#  Pyro4
#  Pyro5
#  Quandl
#  ROPGadget
#  Rtree
##  SPARQLWrapper
#  # SQLAlchemy-ImageAttach
#  Theano
##  TheanoWithCuda
##  TheanoWithoutCuda
##  ViennaRNA
#  # WSME
#  Wand
#  WazeRouteCalculator
#  XlsxWriter
#  Yapsy
#  aadict
#  aafigure
#  aardwolf
#  abodepy
#  absl-py
##  accupy
#  accuweather
##  acebinf
#  acme
#  acme-tiny
#  acoustics
#  acquire
#  actdiag
#  adafruit-io
#  adafruit-nrfutil
#  adafruit-platformdetect
#  adafruit-pureio
#  adal
#  adax
#  adax-local
#  adb-enhanced
#  adb-homeassistant
#  adb-shell
#  adblock
#  add-trailing-comma
#  addict
#  adext
#  adguardhome
#  adjusttext
#  adlfs
#  advantage-air
#  advocate
#  aemet-opendata
#  aenum
##  aeppl
##  aesara
##  aesedb
#  afdko
#  affine
#  afsapi
#  agate
#  agate-dbf
#  agate-excel
#  agate-sql
#  agent-py
#  aggdraw
#  ailment
#  aio-geojson-client
#  aio-geojson-generic-client
#  aio-geojson-geonetnz-quakes
#  aio-geojson-geonetnz-volcano
#  aio-geojson-nsw-rfs-incidents
#  aio-geojson-usgs-earthquakes
#  aio-georss-client
#  aio-georss-gdacs
#  aioairq
#  aioairzone
#  aioaladdinconnect
#  aioambient
#  aioamqp
#  aioapns
#  aioaseko
#  aioasuswrt
#  aioazuredevops
#  aiobiketrax
#  aioblescan
#  aiobotocore
#  aiobroadlink
#  aiocache
#  aiocoap
#  aioconsole
#  aiocontextvars
#  aiocron
#  aiocsv
#  aiocurrencylayer
#  aiodiscover
#  aiodns
#  aioeafm
#  aioeagle
#  aioecowitt
#  aioemonitor
#  aioesphomeapi
#  aioextensions
#  aiofile
#  aiofiles
#  aioflo
#  aioftp
#  aiogithubapi
#  aioguardian
#  # aioh2
#  aioharmony
#  aiohomekit
#  aiohttp
#  aiohttp-apispec
#  aiohttp-cors
#  aiohttp-jinja2
#  # aiohttp-oauthlib
#  # aiohttp-openmetrics
#  aiohttp-remotes
#  aiohttp-retry
#  aiohttp-socks
#  aiohttp-swagger
#  aiohttp-wsgi
#  aiohue
#  aiohwenergy
#  aioimaplib
#  aioinflux
#  aioitertools
#  aiojobs
#  aiokafka
#  aiokef
#  aiolifx
#  aiolifx-connection
#  aiolifx-effects
#  aiolifx-themes
#  aiolimiter
#  aiolip
#  # aiolivisi
#  aiolookin
#  aiolyric
#  aiomisc
#  aiomodernforms
#  aiomultiprocess
#  aiomusiccast
#  aiomysensors
#  aiomysql
#  aionanoleaf
#  aionotify
#  aionotion
#  aiooncue
#  aioopenexchangerates
#  aiopg
#  aioprocessing
#  aiopulse
#  # aiopurpleair
#  aiopvapi
#  aiopvpc
#  aiopyarr
#  aiopylgtv
#  aioqsw
#  aioquic
#  aiorecollect
#  aioredis
#  aioresponses
#  aioridwell
#  aiorpcx
#  aiortm
#  aiorun
#  aiorwlock
#  aiosenseme
#  aiosenz
#  aioserial
#  aioshelly
#  aioshutil
#  aiosignal
#  aioskybell
#  aioslimproto
#  aiosmb
#  aiosmtpd
#  aiosmtplib
#  aiosqlite
#  aiosteamist
#  aiostream
#  aioswitcher
#  aiosyncthing
#  aiotractive
#  aiounifi
#  aiounittest
#  aiovlc
#  aiowatttime
#  aiowebostv
#  aioweenect
#  aiowinreg
#  aioymaps
#  aiozeroconf
#  airly
#  airthings-ble
#  airthings-cloud
#  airtouch4pyapi
#  ajpy
#  ajsonrpc
#  alabaster
#  aladdin-connect
#  alarmdecoder
#  # ale-py
#  alectryon
#  alembic
#  algebraic-data-types
#  aliyun-python-sdk-cdn
#  aliyun-python-sdk-config
#  aliyun-python-sdk-core
#  aliyun-python-sdk-dbfs
#  aliyun-python-sdk-iot
#  aliyun-python-sdk-kms
#  aliyun-python-sdk-sts
#  allpairspy
#  allure-behave
#  allure-pytest
#  allure-python-commons
#  allure-python-commons-test
#  alpha-vantage
#  altair
#  amaranth
#  amaranth-boards
#  amaranth-soc
#  amarna
#  amazon-ion
##  amazon_kclpy
#  ambee
#  amberelectric
#  ambiclimate
#  amcrest
#  amiibo-py
#  amply
#  amqp
#  amqplib
#  amqtt
#  androguard
#  android-backup
#  androidtv
#  angr
#  angrcli
##  angrop
#  aniso8601
#  annexremote
#  annoy
#  anonip
#  ansi
#  ansi2html
#  ansible
#  # ansible-base
#  ansible-compat
#  ansible-core
#  ansible-doctor
#  ansible-kernel
#  ansible-later
#  ansible-lint
#  ansible-runner
#  ansicolor
#  ansicolors
#  ansiconv
#  ansimarkup
#  ansiwrap
#  antlr4-python3-runtime
#  anyascii
#  anybadge
#  anyconfig
#  anyio
##  anyjson
##  anytree
#  aocd
#  apache-airflow
#  apache-beam
#  apcaccess
#  apipkg
#  apispec
#  aplpy
#  appdirs
#  applicationinsights
##  appnope
#  apprise
#  approvaltests
#  appthreat-vulnerability-db
#  apptools
#  aprslib
#  apsw
#  apycula
#  aqipy-atmotech
#  aqualogic
#  arabic-reshaper
#  # aranet4
#  arc4
#  arcam-fmj
#  archinfo
#  archspec
#  area
#  arelle
##  arelle-headless
#  aresponses
#  argcomplete
#  argh
#  argon2-cffi
#  argon2-cffi-bindings
#  argon2_cffi
#  argparse-addons
#  args
#  aria2p
#  # ariadne
#  arnparse
#  arpeggio
#  arrayqueues
#  arris-tg2492lg
#  arrow
#  arviz
#  arxiv2bib
#  asana
#  ascii-magic
#  asciimatics
#  asciitree
#  asdf
#  asdf-standard
#  asdf-transform-schemas
#  ase
#  asf-search
#  asgi-csrf
#  asgineer
#  asgiref
#  asks
#  asmog
#  asn1
#  asn1ate
#  asn1crypto
#  asn1tools
#  aspell-python
#  aspy-refactor-imports
##  aspy-yaml
#  assay
#  assertpy
#  asterisk-mbox
#  asteval
#  astor
#  astral
#  astroid
#  astropy
#  astropy-extension-helpers
#  astropy-healpix
#  astropy-helpers
##  astroquery
#  asttokens
#  astunparse
#  asyauth
#  async-dns
#  async-lru
#  async-modbus
#  async-timeout
#  async-upnp-client
#  async_generator
#  async_stagger
#  asyncclick
#  asynccmd
#  asyncio-dgram
#  asyncio-mqtt
#  asyncio-nats-client
#  asyncio-rlock
#  asyncio-throttle
##  asyncmy
#  asyncpg
#  asyncserial
#  asyncsleepiq
#  asyncssh
#  asyncstdlib
#  asynctest
#  # asyncua
#  asyncwhois
#  asysocks
#  atc-ble
#  atenpdu
#  atlassian-python-api
#  atom
#  atomiclong
##  atomicwrites
#  atomicwrites-homeassistant
##  atomman
#  atpublic
#  atsim_potentials
#  attrdict
#  attrs
#  aubio
#  audible
#  audio-metadata
#  audioread
#  audiotools
#  augeas
#  augmax
#  auroranoaa
#  aurorapy
#  autarco
#  auth0-python
##  authcaptureproxy
#  authheaders
#  authlib
#  authres
#  autobahn
#  autocommand
#  # autofaiss
#  # autoflake
#  autograd
#  autoit-ripper
#  autologging
#  automat
#  automate-home
#  autopage
#  autopep8
#  av
#  avahi
#  avea
##  avion
##  avro
#  avro-python3
##  avro3k
#  awacs
##  awesome-slugify
##  awesomeversion
##  awkward
#  # awkward-cpp
#  awkward0
#  aws-adfs
#  aws-lambda-builders
#  aws-sam-translator
#  aws-xray-sdk
#  awscrt
#  awsiotpythonsdk
#  awslambdaric
#  axis
#  azure-appconfiguration
#  azure-applicationinsights
#  azure-batch
#  azure-common
#  azure-containerregistry
#  azure-core
#  azure-cosmos
#  azure-cosmosdb-nspkg
##  azure-cosmosdb-table
#  azure-data-tables
#  azure-datalake-store
#  azure-eventgrid
#  azure-eventhub
#  azure-functions-devops-build
#  azure-graphrbac
#  azure-identity
#  azure-keyvault
#  azure-keyvault-administration
#  azure-keyvault-certificates
#  azure-keyvault-keys
#  azure-keyvault-nspkg
#  azure-keyvault-secrets
#  azure-loganalytics
#  azure-mgmt-advisor
#  azure-mgmt-apimanagement
#  azure-mgmt-appconfiguration
#  azure-mgmt-applicationinsights
#  azure-mgmt-authorization
#  azure-mgmt-batch
#  azure-mgmt-batchai
#  azure-mgmt-billing
#  azure-mgmt-botservice
#  azure-mgmt-cdn
#  azure-mgmt-cognitiveservices
#  azure-mgmt-commerce
#  azure-mgmt-common
#  azure-mgmt-compute
#  azure-mgmt-consumption
#  azure-mgmt-containerinstance
#  azure-mgmt-containerregistry
#  azure-mgmt-containerservice
#  azure-mgmt-core
#  azure-mgmt-cosmosdb
#  azure-mgmt-databoxedge
#  azure-mgmt-datafactory
#  azure-mgmt-datalake-analytics
#  azure-mgmt-datalake-nspkg
#  azure-mgmt-datalake-store
#  azure-mgmt-datamigration
#  azure-mgmt-deploymentmanager
#  azure-mgmt-devspaces
#  azure-mgmt-devtestlabs
#  azure-mgmt-dns
#  azure-mgmt-eventgrid
#  azure-mgmt-eventhub
#  azure-mgmt-extendedlocation
#  azure-mgmt-hanaonazure
#  azure-mgmt-hdinsight
#  azure-mgmt-imagebuilder
#  azure-mgmt-iotcentral
#  azure-mgmt-iothub
#  azure-mgmt-iothubprovisioningservices
#  azure-mgmt-keyvault
#  azure-mgmt-kusto
#  azure-mgmt-loganalytics
#  azure-mgmt-logic
#  azure-mgmt-machinelearningcompute
#  azure-mgmt-managedservices
#  azure-mgmt-managementgroups
#  azure-mgmt-managementpartner
#  azure-mgmt-maps
#  azure-mgmt-marketplaceordering
#  azure-mgmt-media
#  azure-mgmt-monitor
#  azure-mgmt-msi
#  azure-mgmt-netapp
#  azure-mgmt-network
#  azure-mgmt-notificationhubs
#  azure-mgmt-nspkg
#  azure-mgmt-policyinsights
##  azure-mgmt-powerbiembedded
#  azure-mgmt-privatedns
#  azure-mgmt-rdbms
#  azure-mgmt-recoveryservices
#  azure-mgmt-recoveryservicesbackup
#  azure-mgmt-redhatopenshift
#  azure-mgmt-redis
#  azure-mgmt-relay
#  azure-mgmt-reservations
#  azure-mgmt-resource
##  azure-mgmt-scheduler
#  azure-mgmt-search
#  azure-mgmt-security
#  azure-mgmt-servicebus
#  azure-mgmt-servicefabric
#  azure-mgmt-servicefabricmanagedclusters
#  azure-mgmt-servicelinker
#  azure-mgmt-signalr
#  azure-mgmt-sql
#  azure-mgmt-sqlvirtualmachine
#  azure-mgmt-storage
#  azure-mgmt-subscription
#  azure-mgmt-synapse
#  azure-mgmt-trafficmanager
#  azure-mgmt-web
#  azure-multiapi-storage
#  azure-nspkg
#  azure-servicebus
#  azure-servicefabric
#  azure-servicemanagement-legacy
##  azure-storage
#  azure-storage-blob
#  azure-storage-common
#  azure-storage-file
#  azure-storage-file-share
#  azure-storage-nspkg
#  azure-storage-queue
#  azure-synapse-accesscontrol
#  azure-synapse-artifacts
#  azure-synapse-managedprivateendpoints
#  azure-synapse-spark
#  b2sdk
#  babel
#  babelfish
#  babelgladeextractor
#  backcall
#  backoff
#  backports-cached-property
##  backports-datetime-fromisoformat
##  backports-entry-points-selectable
##  backports-shutil-which
#  # backports-zoneinfo
##  backports_csv
##  backports_functools_lru_cache
##  backports_shutil_get_terminal_size
##  backports_tempfile
##  backports_unittest-mock
##  backports_weakref
##  bacpypes
#
#  bagit
#  banal
#  bandit
#  bap
#  baron
#  base36
#  base58
#  base58check
#  baseline
#  baselines
#  basemap
#  basemap-data
#  bash_kernel
#  bashlex
#  basiciw
#  batchgenerators
#  batchspawner
#  batinfo
#  bayesian-optimization
#  bayespy
#  bbox
#  bc-python-hcl2
#  bcdoc
#  bcrypt
##  beaker
#  beancount
#  # beancount-black
#  # beancount-parser
#  beancount_docverif
#  beanstalkc
#  beartype
#  beautifulsoup4
#  beautifultable
#  bech32
##  bedup
#  behave
#  bellows
##  bencoder
#  beniget
#  bespon
#  betacode
#  betamax
#  betamax-matchers
#  betamax-serializers
#  betterproto
#  bibtexparser
#  bidict
#  bids-validator
#  biliass
#  billiard
#  bimmer-connected
#  binaryornot
#  bincopy
#  binho-host-adapter
#  # binwalk
#  binwalk-full
#  biopython
##  bip_utils
#  biplist
#  bitarray
#  bitbox02
#  # bitcoin-price-api
#
#
#  bitcoin-utils-fork-minimal
#  bitcoinlib
#  bitcoinrpc
#  bite-parser
#  bitlist
#  bitmath
#  bitstring
#  bitstruct
#  bitvavo-aio
#  bizkaibus
#  bjoern
#  bkcharts
#  black
#  black-macchiato
#  bleach
#  bleach-allowlist
#  bleak
#  bleak-retry-connector
#  blebox-uniapi
#  bless
#  blessed
#  blessings
#  blinker
#  blinkpy
#  blis
#  block-io
#  blockchain
#  blockdiag
##  blockdiagcontrib-cisco
#  blocksat-cli
#  blspy
#  bluemaestro-ble
#  bluepy
#  bluepy-devices
#  bluetooth-adapters
#  bluetooth-auto-recovery
#  bluetooth-data-tools
#  bluetooth-sensor-state-data
#  blurhash
#  bme280spi
#  bme680
#  bokeh
#  boltons
#  boltztrap2
#  bond-api
#  bond-async
##  bonsai
#  boolean-py
#  booleanoperations
#  boost
#  boost-histogram
##  bootstrapped-pip
#  boschshcpy
#  boto
#  boto3
#  botocore
#  bottle
#  bottleneck
#  boxx
#  bpycv
#  bpython
#  braceexpand
#  bracex
#  braintree
#  branca
#  bravado-core
#  bravia-tv
#  breathe
#  breezy
#  brelpy
#  broadlink
##  brother
#  brother-ql
#  brotli
#  brotlicffi
#  brotlipy
#  brottsplatskartan
#  browser-cookie3
#  brunt
#  bsblan
#  bsddb3
#  bsdiff4
##  bson
#  bsuite
#  bt-proximity
#  bt_proximity
#  btchip
#  bthome-ble
#  btrfs
#  btrfsutil
#  # btsmarthub_devicelist
#  btsocket
#  bucketstore
#  bugsnag
#  bugwarrior
#  bugz
#  bugzilla
#  buienradar
#  build
#
#
#  buildPythonApplication
#  buildPythonPackage
#  buildSetupcfg
##  buildbot
#  buildbot-full
##  buildbot-pkg
#  # buildbot-plugins
##  buildbot-ui
#  buildbot-worker
#  buildcatrust
#
#
#
#  bumps
#  bunch
#  bundlewrap
#  bwapy
#  bx-python
#  bytecode
#  bz2file
#  cachecontrol
#  cached-property
#  cachelib
#  cachetools
#  cachey
#  cachy
##  cadquery
##  caffe
##  caffeWithCuda
#  caio
#  cairo-lang
#  cairocffi
#  cairosvg
#  caldav
#  callPackage
#  callee
#  calmjs-parse
#  calver
##  camel-converter
#  can
#  canmatrix
#  canonicaljson
#  canopen
#  capstone
#  capturer
#  carbon
##  carrot
#  cart
#  cartopy
#  casa-formats-io
#  casbin
#  case
#  cassandra-driver
#  castepxbin
##  casttube
#  catalogue
#  catboost
##  catppuccin
#  cattrs
##  cbeams
#  cbor
#  cbor2
#  cccolutils
#  cchardet
#  cdcs
#  celery
#  celery-redbeat
#  cement
#  censys
#  cepa
#  cerberus
#  cert-chain-resolver
#  certauth
#  certbot
#  certbot-dns-cloudflare
#  certbot-dns-google
#  certbot-dns-inwx
#  certbot-dns-rfc2136
#  certbot-dns-route53
#  certifi
#  certipy
#  certomancer
#  certvalidator
#  cexprtk
#  cffi
#  cffsubr
#  cfgv
#  cfn-flip
#  cfn-lint
#  cfscrape
#  cftime
#  cgen
#  cgroup-utils
#  chacha20poly1305
#  chacha20poly1305-reuseable
#  chai
#  chainer
#  chainmap
#  chalice
#  chameleon
#  channels
#  channels-redis
#  characteristic
#  chardet
#  charset-normalizer
#  chart-studio
#  chat-downloader
#  check-manifest
#  cheetah3
#  cheroot
#  cherrypy
#  chess
#  chevron
#  chex
#  chia-rs
#  chiabip158
#  chiapos
#  chiavdf
#  chirpstack-api
#  chispa
##  chromaprint
#  ci-info
#  ci-py
#  cinemagoer
#  circuit-webhook
#  circuitbreaker
#  cirq
#  cirq-aqt
#  cirq-core
#  cirq-google
#  cirq-ionq
#  cirq-pasqal
#  cirq-rigetti
#  cirq-web
#  ciscoconfparse
#  ciscomobilityexpress
#  ciso8601
#  citeproc-py
#  cjkwrap
#  ckcc-protocol
#  claripy
#  class-registry
#  classify-imports
#  cld2-cffi
#  cle
#  cleo
#  clevercsv
#  clf
#  cli-helpers
#  click
##  click-command-tree
#  click-completion
#  click-configfile
#  click-datetime
#  click-default-group
#  click-didyoumean
#  click-help-colors
#  click-log
#  click-option-group
#  click-plugins
#  click-repl
#  click-shell
#  click-spinner
#  click-threading
#  clickclick
#  clickgen
#  clickhouse-cityhash
#  clickhouse-cli
#  clickhouse-driver
#  cliff
#  clifford
#  cligj
#  clikit
#  clint
#  clintermission
#  clip
#  clize
#  clldutils
#  cloudflare
#  cloudpickle
#  cloudscraper
#  cloudsmith-api
#  cloudsplaining
#  cloup
#  clustershell
#  clvm
#  clvm-rs
#  clvm-tools
#  clvm-tools-rs
#  cma
#  cmarkgfm
#  cmd2
#  cmdline
#  cmigemo
#  cmsis-pack-manager
#  cmsis-svd
##  cntk
#  cnvkit
#  co2signal
#  coapthon3
#  cock
#  coconut
#  cocotb
#  cocotb-bus
#  codecov
#  codepy
###  codespell
#  cogapp
#  coincurve
#  coinmetrics-api-client
#  colander
#  collections-extended
#  colorama
#  colorcet
#  colorclass
#  colored
#  colored-traceback
#  coloredlogs
#  colorful
#  colorlog
#  colorlover
#  colormath
#  colorspacious
#  colorthief
#  colorzero
#  colour
#  cometblue-lite
##  comm
#  commandparse
#  commentjson
#  commoncode
#  compiledb
#  compreffor
#  concurrent-log-handler
##  conda
#  condaInstallHook
#  condaUnpackHook
#  confection
#  configargparse
#  configclass
#  confight
#  configobj
#  configparser
#  configshell
#  configupdater
#  confluent-kafka
#  confuse
#  connect-box
#  connection-pool
#  connexion
#  connio
#  cons
#  consonance
#  constantly
#  construct
##  construct-classes
#  consul
#  container-inspector
#  contexter
#  contextlib2
#  contexttimer
##  contourpy
#  convertdate
#  cookiecutter
#  cookies
#  coordinates
#  coqpit
#  coreapi
#  coreschema
#  cornice
#  coronavirus
#  corsair-scan
#  cot
#  covCore
#  coverage
#  coveralls
##  cozy
#  cppe
#  cppheaderparser
#  cppy
#  cpyparsing
#  cram
#  cramjam
#  crashtest
#  crate
#  crayons
#  crc16
#  crc32c
#  crccheck
#  crcmod
#  credstash
#  criticality-score
##  crocoddyl
#  cron-descriptor
#  croniter
#  cronsim
#  crossplane
#  crownstone-cloud
#  crownstone-core
#  crownstone-sse
#  crownstone-uart
##  cryptacular
#  cryptg
#  cryptography
#  cryptography_vectors
#  cryptolyzer
#  cryptoparser
#  crysp
#  crytic-compile
#  csrmesh
#  css-html-js-minify
#  css-parser
#  csscompressor
#  cssmin
#  cssselect
#  cssselect2
#  cssutils
#  csvw
##  cu2qu
#  cucumber-tag-expressions
#  cufflinks
##  cupy
#  curio
#  curtsies
#  curve25519-donna
#  cvelib
##  cvss
#  cvxopt
#  cvxpy
#  cwcwidth
##  cwl-upgrader
##  cwl-utils
##  cwlformat
##  cx_Freeze
##  cx_oracle
#  cxxfilt
#  cycler
##  cyclonedx-python-lib
#  cymem
#  cypari2
#  cypherpunkpay
#  cysignals
##  cython
##  cython_3
#  cytoolz
#  d2to1
#  dacite
#  daemonize
#  daemonocle
#  dalle-mini
#  daphne
#  dasbus
#  dash
#  dash-core-components
#  dash-html-components
#  dash-renderer
#  dash-table
#  dask
#  dask-gateway
#  dask-gateway-server
#  dask-glm
#  dask-image
#  dask-jobqueue
#  dask-ml
#  dask-mpi
##  dask-xgboost
##  dask-yarn
#  databases
#  databricks-cli
##  databricks-connect
#  databricks-sql-connector
#  dataclasses-json
#  dataclasses-serialization
#  datadiff
#  datadog
#  datafusion
#  datamodeldict
#  datapoint
#  dataset
#  datasets
#  datasette
#  datasette-publish-fly
#  datasette-template-sql
#  datashader
#  datashape
#  datatable
#  datauri
#  dateparser
#  dateutil
#  dateutils
#  datrie
#  dawg-python
#  db-dtypes
#  dbf
#  dbfread
#  dbus-client-gen
#  dbus-fast
#  dbus-next
#  dbus-python
#  dbus-python-client-gen
#  dbus-signature-pyparsing
#  dbutils
##  dcmstack
#  ddt
#  deal
#  deal-solver
#  deap
#  debian
#  debian-inspector
#  debtcollector
#  debts
#  debuglater
#  debugpy
#  decli
#  decopatch
#  decorator
#  deemix
#  deep-chainmap
#  deep-translator
#  deep_merge
#  deepdiff


  deepdish
  deepmerge
  deeptoolsintervals
  deepwave
  deezer-py
#  deezer-python
  defcon
  deform
  defusedxml
  delegator-py
  delorean
  deltachat
  deluge-client
  demetriek
#  demjson
  demjson3
  dendropy
  denonavr
  dependency-injector
  deploykit
  deprecated
  deprecation
  derpconf
#  descartes
  desktop-notifier
  detect-secrets
#  detox
#  devito
  devolo-home-control-api
  devolo-plc-api
  devpi-common
  devtools
#  dftfit
  diagrams
  diceware
#  dicom-numpy
  dicom2nifti
  dict2xml
  dictdiffer
  dictionaries
  dictpath
  dicttoxml
  dicttoxml2
  diff-cover
  diff-match-patch
  diff_cover
  digi-xbee
  digital-ocean
  dill
  dinghy
  dingz
  diofant
  dipy
  directv
  dirty-equals
  disabled
  disabledIf
  discid
  discogs-client
  discogs_client
  discordpy
  discovery30303
  diskcache
  dissect
  dissect-cim
  dissect-clfs
  dissect-cstruct
  dissect-esedb
  dissect-etl
  dissect-eventlog
  dissect-evidence
  dissect-extfs
  dissect-fat
  dissect-ffs
  dissect-hypervisor
  dissect-ntfs
  dissect-ole
  dissect-regf
  dissect-shellitem
  dissect-sql
  dissect-target
#  dissect-thumbcache
  dissect-util
  dissect-vmfs
  dissect-volume
  dissect-xfs
  dissononce
  distlib
  distorm3
#  distrax
  distributed
  distro
  distutils_extra
  dj-database-url
  dj-email-url
  dj-rest-auth
  dj-search-url
  django

#  django-admin-sortable2
  django-allauth
  django-annoying
  django-anymail
  django-appconf
  django-auth-ldap
  django-autocomplete-light
  django-cache-url
  django-cacheops
  django-celery-beat
  django-celery-email
##  django-celery-results
  django-cleanup
  django-compressor
  django-configurations
  django-cors-headers
  django-crispy-forms
  django-cryptography
  django-csp
  django-debug-toolbar
  django-discover-runner
  django-dynamic-preferences
  django-encrypted-model-fields
  django-environ
  django-extensions
  django-filter
  django-formtools
#  django-graphiql-debug-toolbar
  django-gravatar2
  django-guardian
  django-haystack
  django-hcaptcha
  django-health-check
#  django-import-export
  django-ipware
  django-jinja
  django-js-asset
  django-js-reverse
  django-logentry-admin
#  django-login-required-middleware
  django-mailman3
  django-maintenance-mode
  django-model-utils
  django-modelcluster
  django-mptt
  django-multiselectfield
  django-oauth-toolkit
  django-otp
  django-paintstore
  django-pglocks
#  django-phonenumber-field
  django-picklefield
  django-polymorphic
  django-postgresql-netfields
  django-prometheus
  django-q
  django-ranged-response
  django-raster
  django-redis
  django-rest-auth
  django-rest-polymorphic
#  django-rest-registration
  django-reversion
  django-rq
#  django-sampledatahelper
#  django-scim2
  django-scopes
  django-sesame
  django-simple-captcha
  django-sites
  django-sr
  django-statici18n
  django-storages
  django-stubs
  django-stubs-ext
  django-tables2
  django-taggit
  django-tastypie
  django-timezone-field
  django-versatileimagefield
#  django-vite
  django-webpack-loader
  django-widget-tweaks
#  django_2
#  django_3
#  django_4
#  django_appconf
  django_classytags
#  django_colorful
  django_compat
  django_contrib_comments
  django_environ
  django_extensions
  django_guardian
  django_hijack
#  django_hijack_admin
  django_modelcluster
  django_nose
  django_polymorphic
  django_redis
  django_reversion
  django_silk
  django_tagging
  django_taggit
  django_treebeard
  djangoql
  djangorestframework
  djangorestframework-camel-case
  djangorestframework-dataclasses
  djangorestframework-guardian
  djangorestframework-jwt
  djangorestframework-recursive
  djangorestframework-simplejwt
  djmail
  dkimpy
  dlib
  dlinfo
  dlms-cosem
  dlx
  dm-env
  dm-haiku
#  dm-sonnet
  dm-tree
  dmenu-python
  dnachisel
#  dnfile
  dns
  dnslib
  dnspython
  doc8
  docformatter
  docker
#  docker-py
  docker_pycreds
  dockerfile-parse
  dockerpty
  dockerspawner
  docloud
  docopt
  docopt-ng
  docplex
  docrep
  docstring-parser
  docstring-to-markdown
  doctest-ignore-unicode
  docutils
  docx2python
  docx2txt
  dodgy
  dogpile-cache
#  dogpile-core
  dogpile_cache
  dogtail
  doit
  doit-py
  domeneshop
  dominate
  doorbirdpy
  dopy
  dot2tex
  dotmap
  dotty-dict
  downloader-cli
  dparse
  dparse2
  dpath
  dpcontracts
  dpkt
  dragonfly
#  drawille
#  drawilleplot
  dremel3dpy
  drf-jwt
  drf-nested-routers
  drf-spectacular
  drf-spectacular-sidecar
  drf-writable-nested
  drf-yasg
  drivelib
  drms
  dropbox
  ds-store
  ds4drv
  dsinternals
  dsmr-parser
  dtlssocket
  ducc0
  duckdb
  duckdb-engine
  duecredit
  duet
  dufte
  dugong
  dulwich
  dunamai
  dungeon-eos
  duo-client
  durus
  dvc-data
  dvc-objects
  dvc-render
  dvc-task


  ])); in customPython3