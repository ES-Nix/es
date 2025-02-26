




  # perf record -F99 -p $(pgrep -n node) -g -- sleep 3
  #
  boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
  boot.kernel.sysctl."kernel.kptr_restrict" = lib.mkForce 0;
  # so perf can find kernel modules
  systemd.tmpfiles.rules = [
    "L /lib - - - - /run/current/system/lib"
  ];


TODO:
https://nodejs.org/en/learn/diagnostics/flame-graphs
https://github.com/naugtur/node-example-flamegraph

https://discourse.nixos.org/t/how-do-i-set-perf-event-paranoid/15869/3
https://discourse.nixos.org/t/which-perf-package/22399/2



TODO: there is cargo-flamegraph in nixpkgs!
https://medium.com/@techhara/profiling-visualize-program-bottleneck-with-flamegraph-3e0c5855b2fe


Many tools have got deprecated:
https://unix.stackexchange.com/questions/563861/how-to-generate-pdf-from-complex-html

```nix
firefox
# chromium
google-chrome
inferno
inkscape
microsoft-edge
```

TODO: test it with selenium too
https://stackoverflow.com/a/61492627


```bash
cd $(mktemp -d)

perf script flamegraph -a -F 99 sleep 1

chromium --headless --disable-gpu --print-to-pdf flamegraph.html
google-chrome-stable --headless --disable-gpu --print-to-pdf flamegraph.html

pandoc flamegraph.html -o test.pdf --verbose

firefox flamegraph.html
okular test.pdf
```
Refs.:
- https://bugzilla.mozilla.org/show_bug.cgi?id=1407238
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/getting-started-with-flamegraphs_monitoring-and-managing-system-status-and-performance


```bash
cd $(mktemp -d)

perf record --call-graph dwarf sleep 1  | perf script | inferno-collapse-perf | inferno-flamegraph > profile.svg

rsvg-convert -f pdf -o profile.pdf profile.svg
rsvg-convert --format=pdf profile.svg > profile.pdf

okular profile.pdf
firefox profile.svg
```
Refs.:
- https://docs.rs/inferno/latest/inferno/#differential-flame-graphs


```bash
firefox profile.svg
google-chrome-stable profile.svg
```

```bash
google-chrome-stable \
--headless \
--disable-gpu \
--run-all-compositor-stages-before-draw \
--print-to-pdf profile.svg

okular output.pdf
```

```bash
inkscape --export-type="pdf" profile.svg
```


```bash
microsoft-edge \
--headless \
--print-to-pdf="flamegraph.pdf" \
--no-pdf-header-footer \
--run-all-compositor-stages-before-draw \
flamegraph.html

okular flamegraph.pdf
```
https://stackoverflow.com/a/77965915



TODO: https://unix.stackexchange.com/a/696162
```bash
libreoffice \
--headless \
--norestore \
--convert-to pdf:writer_pdf_Export \
MY_HTML_FILE.html
```
Refs.:
- https://unix.stackexchange.com/a/696162


TODO: 
https://discourse.nixos.org/t/nix-flamegraph-or-profiling-tool/33333/11


References
- https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/getting-started-with-flamegraphs_monitoring-and-managing-system-status-and-performance#getting-started-with-flamegraphs_monitoring-and-managing-system-status-and-performance
- https://arxiv.org/pdf/2301.08941
- https://stackoverflow.com/a/57432063



## 1 Billion Rows of Data

I Parsed 1 Billion Rows Of Text (It Sucked)
https://www.youtube.com/watch?v=e_9ziFKcEhw

How Fast can Python Parse 1 Billion Rows of Data?
https://www.youtube.com/watch?v=utTaPW32gKY

1 Billion Rows Challenge
https://www.youtube.com/watch?v=OO6l1DkYA0k

Java, How Fast Can You Parse 1 Billion Rows of Weather Data? • Roy van Rijn • GOTO 2024
https://www.youtube.com/watch?v=EFXxXFHpS0M
