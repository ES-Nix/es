

```bash
nix run --impure 'github:ES-Nix/es/?dir=src/templates/nginx'
```



```bash
nix fmt \
&& nix flake show --impure '.#' \
&& nix flake metadata --impure '.#' \
&& nix build --impure --no-link --print-build-logs --print-out-paths '.#' \
&& nix develop --impure '.#' --command sh -c 'true' \
&& nix flake check --impure --verbose '.#'
```


```nix
  services.nginx.enable = true;
  services.nginx.virtualHosts."fooo" = {
    locations."/" = {
      root = "${pkgs.runCommand "testdir" {} ''
          mkdir "$out"
          echo '<h2>hello world</h2>' > "$out/index.html"
          echo '<h3>574e9081-0cf3-435c-afd9-f0d2c16e409a</h3>' >> "$out/index.html"
        ''
      }";
    };
  };
```


TODO: write NixOS tests!
```bash
127.0.0.1
127.0.0.1/
http://127.0.0.1
http://127.0.0.1/

localhost
localhost/
http://localhost
http://localhost/
```


```nix
# May be good to use
services.nginx.recommendedGzipSettings = true;
services.nginx.recommendedOptimisation = true;
services.nginx.recommendedProxySettings = true;
services.nginx.recommendedTlsSettings = true;
```

```nix
services.nginx.logError = ''stderr emerg'';
```

Or
```nix
services.nginx.logError = ''/dev/null emerg'';
```
Refs.:
- https://nixos.wiki/wiki/Talk:Nginx



TODO: Substitute the html package rendered:
```nix
root = "${pkgs.glowing-bear}";
```


TODO: make custom package using overlays.


TODO:
make multi machine nginx test
https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html#tests-with-multiple-virtual-machines
https://nix.dev/tutorials/nixos/binary-cache-setup#set-up-services



## 


List:
- https://thenewstack.io/nixos-a-combination-linux-os-and-package-manager/
- https://joshrosso.com/c/nix-k8s/
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=82&end=112&version=3), 
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1532&end=1950&version=3), ?
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1950&end=2052&version=3), start=1950&end=2052
- [Nix Kubernetes and the Pursuit of Reproducibility - Josh Rosso, Reddit](https://www.youtube.com/embed/U-mSWU4see0?start=1997&end=2052&version=3),


```bash
firefox localhost:8080

curl -k localhost:8080
curl -k 127.0.0.1:8080
curl -k 0.0.0.0:8080
```



```bash
python3 -m http.server 8090

lsof -t -i tcp:8090 -s tcp:listen
lsof -t -i tcp:8090 -s tcp:listen
```



```bash
ps -ww -fp $(lsof -t -i tcp:8080 -s tcp:listen)
```
Refs.:
- https://stackoverflow.com/questions/821837/how-to-get-the-command-line-args-passed-to-a-running-process-on-unix-linux-syste#comment639663_821889
-



## static compile nginx


1)
```bash
docker run -it --rm alpine:3.20.3
```

2)
```bash
cd \
&& apk add file g++ make \
&& wget -qO- http://nginx.org/download/nginx-1.9.9.tar.gz | tar zx --strip-components=1 \
&& ./configure --without-http_rewrite_module --without-http_gzip_module --with-cc-opt="-O2" --with-ld-opt="-s -static" \
&& make CFLAGS="-O2 -s" LDFLAGS="-static" -j$(nproc) \
&& file ./objs/nginx \
&& ! ldd ./objs/nginx
```
Refs.:
- https://stackoverflow.com/questions/71847448/static-build-of-nginx
- https://www.tecmint.com/install-nginx-from-source/
- 


```bash
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--impure \
--expr \
"$(cat <<- 'EOF'
  let
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/fe866c653c24adf1520628236d4e70bbb2fdd949"); 
    pkgs = import nixpkgs {};
  in
    (
      (pkgs.pkgsStatic.nginx.overrideAttrs (oldAttrs:
          {
            configureFlags = oldAttrs.configureFlags ++ [ " --without-http_rewrite_module" " --without-http_gzip_module" ];
          }
        )
      )
    )
EOF
)"
```






```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/nginx:alpine AS alpine-nginx

FROM docker.io/library/alpine:3.20.3

RUN apk add --no-cache tzdata \
    && mkdir /var/log/nginx /etc/nginx \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
# create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx     

COPY --from=alpine-nginx /docker-entrypoint.sh /
COPY --from=alpine-nginx /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY --from=alpine-nginx /docker-entrypoint.d/15-local-resolvers.envsh /docker-entrypoint.d
COPY --from=alpine-nginx /docker-entrypoint.d/20-envsubst-on-templates.sh /docker-entrypoint.d
COPY --from=alpine-nginx /docker-entrypoint.d/30-tune-worker-processes.sh /docker-entrypoint.d
COPY --from=alpine-nginx /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=alpine-nginx /etc/nginx/mime.types /etc/nginx/mime.types

COPY --from=alpine-nginx /usr/sbin/nginx /usr/sbin/nginx
COPY --from=alpine-nginx /usr/lib/libpcre2-8.so.0 /usr/lib/libpcre2-8.so.0
COPY --from=alpine-nginx /lib/libssl.so.3 /lib/libssl.so.30
COPY --from=alpine-nginx /lib/libcrypto.so.3 /lib/libcrypto.so.3
COPY --from=alpine-nginx /lib/libz.so.1 /lib/libz.so.1

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
EOF

docker \
build \
--file Containerfile \
--tag alpine-nginx \
.

docker run -it --rm alpine-nginx
```


--without-http_rewrite_module
--without-http_gzip_module

--with-file-aio \ ?

zlib-static
```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/nginx:alpine AS alpine-nginx

FROM docker.io/library/alpine:3.20.3 AS build

RUN wget -qO- http://nginx.org/download/nginx-1.27.1.tar.gz | tar zx --strip-components=1
RUN apk add g++ make pcre-dev zlib zlib-dev zlib-static openssl openssl-dev openssl-libs-static
RUN ./configure \
      --with-cc-opt="-O2" \
      --with-ld-opt="-s -static" \
      --http-log-path=/var/log/nginx/access.log \
      --error-log-path=/var/log/nginx/error.log \
      --conf-path=/etc/nginx/nginx.conf \
      --with-threads \
      --with-http_addition_module \
      --with-http_auth_request_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_mp4_module \
      --with-http_random_index_module \
      --with-http_realip_module \
      --with-http_secure_link_module \
      --with-http_slice_module \
      --with-http_ssl_module \
      --with-http_stub_status_module \
      --with-http_sub_module \
      --with-http_v2_module \
      --with-http_v3_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_realip_module \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
 && make CFLAGS="-O2 -s" LDFLAGS="-static" -j$(nproc) 

FROM docker.io/library/alpine:3.20.3

RUN apk add --no-cache tzdata \
    && mkdir /var/log/nginx /etc/nginx \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
# create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx     

COPY --from=alpine-nginx /docker-entrypoint.sh /
COPY --from=alpine-nginx /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY --from=alpine-nginx /docker-entrypoint.d/15-local-resolvers.envsh /docker-entrypoint.d
COPY --from=alpine-nginx /docker-entrypoint.d/20-envsubst-on-templates.sh /docker-entrypoint.d
COPY --from=alpine-nginx /docker-entrypoint.d/30-tune-worker-processes.sh /docker-entrypoint.d
COPY --from=alpine-nginx /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=alpine-nginx /etc/nginx/mime.types /etc/nginx/mime.types

COPY --from=build /objs/nginx /usr/sbin/nginx


ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
EOF

docker \
build \
--file Containerfile \
--tag alpine-nginx \
.

docker run -dit --rm -p=8000:80 alpine-nginx

firefox localhost:8000
```



docker run -dit --rm -p=8000:80 static-nginx
docker run -it --rm -p=8000:80 static-nginx

```bash
docker run -it --rm docker.io/library/alpine:3.20.3 
docker run -it --rm -p=8000:80 nginx:alpine-slim
```



mkdir -v example-testing
cd example-testing
cp $(nix build --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/fe866c653c24adf1520628236d4e70bbb2fdd949#pkgsMusl.nginx.out')/bin/nginx .


ldd $(nix build --no-link --print-build-logs --print-out-paths \
'github:NixOS/nixpkgs/fe866c653c24adf1520628236d4e70bbb2fdd949#pkgsMusl.nginx.out')/bin/nginx \
| awk 'NF == 4 { system("cp " $3 " .") }'



```bash
docker run --interactive=true --rm=true --tty=true -v "$(pwd)":/code \
docker.io/library/debian:bullseye-20240926-slim
```



```bash
mkdir foo \
&& cd foo \
&& docker run --interactive=true --rm=true --tty=true -v "$(pwd)":/code -w /code \
nginx:1.27-alpine3.20-slim sh -c '
cp -v \
/usr/sbin/nginx \
/usr/lib/libpcre2-8.so.0.12.0 \
/lib/libssl.so.3 \
/lib/libcrypto.so.3 \
/lib/libz.so.1.3.1 \
/lib/ld-musl-x86_64.so.1 \
/etc/nginx/conf.d/default.conf \
/usr/share/nginx/html/index.html \
.
'

sudo chown -Rv "$(id -un)": foo


docker run --interactive=true --rm=true --tty=true -v "$(pwd)":/code -w /code \
alpine:3.20.0 sh 

mkdir -pv /etc/nginx/conf.d /usr/share/nginx/html

cp -v nginx /usr/sbin/nginx
cp -v libpcre2-8.so.0.12.0 /usr/lib/libpcre2-8.so.0.12.0
cp -v libssl.so.3 /lib/libssl.so.3
cp -v libcrypto.so.3 /lib/libcrypto.so.3
cp -v libz.so.1.3.1 /lib/libz.so.1.3.1
cp -v ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
cp -v default.conf /etc/nginx/conf.d/default.conf
cp -v index.html /usr/share/nginx/html/index.html
```




```bash
docker run \
--interactive=true \
--rm=true \
--tty=true \
-v "$(pwd)":/code \
-w /code \
docker.io/library/debian:bullseye-20240926-slim


mkdir -v /usr/lib/ /usr/sbin

cp -v nginx /usr/sbin/nginx
cp -v libpcre2-8.so.0.12.0 /usr/lib/libpcre2-8.so.0.12.0 
cp -v libssl.so.3 /lib/libssl.so.3
cp -v libcrypto.so.3 /lib/libcrypto.so.3
cp -v libz.so.1.3.1 /lib/libz.so.1.3.1
cp -v ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1


```

docker \
run \
--interactive=true \
--rm=true \
--tty=true \
-v "$(pwd)":/code \
-w /code \
-p=8000:80 \
docker.nix-community.org/nixpkgs/nix-flakes




```bash
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--impure \
--expr \
"$(cat <<- 'EOF'
  let
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/fe866c653c24adf1520628236d4e70bbb2fdd949"); 
    pkgs = import nixpkgs {};
  in
    (
      pkgs.pkgsMusl.nginx.overrideAttrs (oldAttrs:
          {
            configureFlags = pkgs.lib.lists.remove "--with-http_xslt_module" oldAttrs.configureFlags;
          }
        )
    )
EOF
)"
```


```bash
nix \
build \
--no-link \
--print-build-logs \
--print-out-paths \
--impure \
--expr \
"$(cat <<- 'EOF'
  let
    nixpkgs = (builtins.getFlake "github:NixOS/nixpkgs/78b848881f3b58b3c04c005a7999800d013fa9b7"); 
    pkgs = import nixpkgs {};
  in
    (
      pkgs.pkgsStatic.nginx.overrideAttrs (oldAttrs:
          {
            configureFlags = pkgs.lib.subtractLists [ 
              "--with-http_xslt_module" 
              "--disable-shared" 
              "--enable-static" 
            ] oldAttrs.configureFlags;
          }
        )
    )
EOF
)"
```
