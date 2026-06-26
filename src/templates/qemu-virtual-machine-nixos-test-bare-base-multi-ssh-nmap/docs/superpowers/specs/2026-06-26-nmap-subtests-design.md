# Nmap Subtests Design

**Date:** 2026-06-26
**Project:** qemu-virtual-machine-nixos-test-bare-base-multi-ssh-nmap

## Context

Existing NixOS test uses `testers.runNixOSTest` with 3-machine VLAN topology:

- **machineA** (VLAN 1): SSH enabled, bind, traceroute
- **machineRouter** (VLANs 1 & 2): IP forwarding, no SSH, no DNS
- **machineB** (VLAN 2): SSH enabled, bind + DNS zone `example.test`, traceroute

Firewall disabled on all machines. Tests already cover: ping, routes, SSH keyscan, dig (15 asserts), traceroute (11 subtests).

## Goal

Add 17 nmap subtests covering host discovery, port scanning, service version detection, and negative cases — from all 3 nodes, including cross-VLAN scans.

## Flake Changes

Add `pkgs.nmap` to `systemPackages` on all 3 machines:

```nix
machineA:      [ pkgs.bind pkgs.traceroute pkgs.nmap ]
machineRouter: [ pkgs.traceroute pkgs.nmap ]
machineB:      [ pkgs.bind pkgs.traceroute pkgs.nmap ]
```

## Test Structure

Sequential subtests numbered `"Nmap 1: ..."` through `"Nmap 17: ..."`, consistent with existing traceroute subtest style.

Scan type: `-sT` (TCP connect scan) throughout — no raw socket privileges needed, reliable in VM environment. Service version subtests use `-sT -sV -p <port>`.

## Subtests

### Block 1 — Tool Availability + Host Discovery

**Nmap 1: tool available**
- `machineA.succeed("nmap --version 2>&1 | grep -i Nmap")`

**Nmap 2: machineA discovers machineB is up (cross-VLAN)**
- `machineA.succeed(f"nmap -sn {MACHINEB_IP} | grep -q 'Host is up'")`

**Nmap 3: machineA discovers machineRouter VLAN1 IP is up**
- `machineA.succeed(f"nmap -sn {ROUTER_VLAN1_IP} | grep -q 'Host is up'")`

**Nmap 4: machineA subnet sweep finds ≥2 hosts on VLAN1**
- Run `nmap -sn 192.168.1.0/24`, count lines matching `"Host is up"`, assert `>= 2`

**Nmap 5: machineRouter discovers machineA via VLAN1**
- `machineRouter.succeed(f"nmap -sn {MACHINEA_IP} | grep -q 'Host is up'")`

### Block 2 — Port Scanning (-sT)

**Nmap 6: machineA localhost → port 22 open**
- `machineA.succeed("nmap -sT -p 22 127.0.0.1 | grep -q '22/tcp open'")`

**Nmap 7: machineA localhost → port 53 NOT open (no DNS on A)**
- Run scan, assert output does NOT contain `"53/tcp open"` (port will appear as closed or filtered)

**Nmap 8: machineA → machineB port 22 open (cross-VLAN)**
- `machineA.succeed(f"nmap -sT -p 22 {MACHINEB_IP} | grep -q '22/tcp open'")`

**Nmap 9: machineA → machineB port 53 open (DNS cross-VLAN)**
- `machineA.succeed(f"nmap -sT -p 53 {MACHINEB_IP} | grep -q '53/tcp open'")`

**Nmap 10: machineA → machineRouter port 22 NOT open (no SSH on router)**
- Run scan, assert output does NOT contain `"22/tcp open"`

**Nmap 11: machineB localhost → ports 22 and 53 both open**
- `machineB.succeed("nmap -sT -p 22,53 127.0.0.1 | grep -c 'open'")` assert count == 2

**Nmap 12: machineRouter → machineA port 22 open (cross-VLAN from router)**
- `machineRouter.succeed(f"nmap -sT -p 22 {MACHINEA_IP} | grep -q '22/tcp open'")`

### Block 3 — Service Version Detection (-sV)

**Nmap 13: machineA → machineB:22 → service is OpenSSH**
- `machineA.succeed(f"nmap -sT -sV -p 22 {MACHINEB_IP} | grep -qi OpenSSH")`

**Nmap 14: machineA → machineB:53 → service is domain**
- `machineA.succeed(f"nmap -sT -sV -p 53 {MACHINEB_IP} | grep -q 'domain'")`

**Nmap 15: machineB → machineA:22 → OpenSSH (reverse cross-VLAN)**
- `machineB.succeed(f"nmap -sT -sV -p 22 {MACHINEA_IP} | grep -qi OpenSSH")`

### Block 4 — Negative / Boundary

**Nmap 16: machineA → machineB:80 → port 80 NOT open (no HTTP)**
- Run scan, assert output does NOT contain `"80/tcp open"`

**Nmap 17: machineA → unreachable host 10.99.99.99 → 0 hosts up**
- `rc, out = machineA.execute("nmap -sn --host-timeout 3s 10.99.99.99 2>&1")`, assert `"0 hosts up"` in out or count of "Host is up" == 0

## Open Questions

None. All requirements confirmed.

## Constraints

- `-sT` used throughout (no raw socket needed)
- `--host-timeout 3s` on unreachable-host test to keep CI fast
- No new Python imports needed (existing `re` already imported)
- All IPs come from already-established `MACHINEA_IP`, `MACHINEB_IP`, `ROUTER_VLAN1_IP`, `ROUTER_VLAN2_IP` variables
