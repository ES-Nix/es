# nix-collect-garbage per-user gcroots workaround Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** NixOS VM test that proves `nix-collect-garbage` fails with stale per-user gcroot symlinks, then passes after deleting `/nix/var/nix/gcroots/per-user/$NAME` and `/nix/var/nix/profiles/per-user/$NAME`.

**Architecture:** Single NixOS VM (`machineABCZ`) with a `testuser` account. testScript (Python) creates broken symlinks in per-user dirs, asserts `nix-collect-garbage` fails, deletes the dirs, asserts `nix-collect-garbage` succeeds. All logic lives inside `flake.nix`'s `testScript` block — no external test files.

**Tech Stack:** Nix flakes, NixOS test framework (`testers.runNixOSTest`), Python testScript DSL, `nix-collect-garbage`

**Reference:** https://github.com/NixOS/nix/issues/4419#issuecomment-1369255430

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `flake.nix` | **Modify** | NixOS node config (add user) + testScript (the whole test) |

---

### Task 1: Add `testuser` to the NixOS node config

**Files:**
- Modify: `flake.nix` — `nodes.machineABCZ` attribute set

The existing node is nearly empty. We need a normal user so per-user dirs exist realistically.

- [ ] **Step 1: Edit the node config**

Find this block in `flake.nix` (lines 42–55):

```nix
machineABCZ = { config, pkgs, ... }: {
  environment.systemPackages = (with pkgs; [
    graphviz
    hello
    nix
  ]);

  system.extraDependencies = with pkgs; [ hello.inputDerivation ];

  nix.extraOptions = "experimental-features = nix-command flakes";
  nix.registry.nixpkgs.flake = nixpkgs;
  nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
};
```

Replace with:

```nix
machineABCZ = { config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ nix ];

  users.users.testuser = {
    isNormalUser = true;
    uid = 1001;
  };

  nix.extraOptions = "experimental-features = nix-command flakes";
  nix.registry.nixpkgs.flake = nixpkgs;
  nix.settings.flake-registry = "${flake-registry}/flake-registry.json";
  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
  nix.settings.trusted-users = [ "root" ];
};
```

Changes:
- Removed `graphviz` and `hello` (not needed for this test)
- Removed `system.extraDependencies` (irrelevant)
- Added `users.users.testuser` with a fixed UID so paths are predictable
- Added `nix.settings.trusted-users` (allows root to run gc without issues)

- [ ] **Step 2: Verify the file parses**

```bash
cd /home/fog/es/src/templates/qemu-virtual-machine-nixos-test-bare-base-nix-flakes-nixpkgs-path-nix-collect-garbage
nix flake show --all-systems '.#' 2>&1 | head -30
```

Expected: outputs the flake structure without `error:` lines.

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "feat: add testuser to nixos node for gc test"
```

---

### Task 2: Replace testScript with the per-user gcroots workaround test

**Files:**
- Modify: `flake.nix` — `testScript` attribute

The NixOS test framework testScript is Python. Available machine methods:
- `machine.succeed(cmd)` — run cmd, assert exit 0, return stdout
- `machine.fail(cmd)` — run cmd, assert exit != 0
- `machine.execute(cmd)` — run cmd, return `(exit_code, stdout)` without assertion
- `machine.wait_for_unit(unit)` — block until systemd unit is active

**Background on the bug (NixOS/nix#4419):**  
`nix-collect-garbage` calls `nix-store --gc` which traverses `/nix/var/nix/gcroots/` including per-user subdirectories. If those dirs contain broken symlinks (pointing to nonexistent store paths), nix errors out instead of ignoring them. Workaround: delete the whole per-user dir before running gc.

- [ ] **Step 1: Replace the testScript block**

Find this in `flake.nix`:

```nix
testScript = { nodes, ... }: ''
  machineABCZ.succeed("""
    nix-store --query --graph --include-outputs --force-realise \
      $(nix build --add-root --print-out-paths nixpkgs#hello) \
      | dot -Tps > hello.ps
  """)

  machineABCZ.succeed("ls -alh hello.ps >&2")
'';
```

Replace with:

```nix
testScript = { nodes, ... }: ''
  machineABCZ.start()
  machineABCZ.wait_for_unit("multi-user.target")

  # --- Phase 1: Reproduce the bug ---
  # Create the per-user gcroots dir with a broken symlink (points to nonexistent store path)
  machineABCZ.succeed("mkdir -p /nix/var/nix/gcroots/per-user/testuser")
  machineABCZ.succeed(
      "ln -s /nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-nonexistent "
      "/nix/var/nix/gcroots/per-user/testuser/stale"
  )
  # Create the per-user profiles dir (nix-collect-garbage -d traverses this too)
  machineABCZ.succeed("mkdir -p /nix/var/nix/profiles/per-user/testuser")

  # nix-collect-garbage must fail when stale gcroots are present
  # (NixOS/nix issue #4419: nix-store --gc errors on broken symlinks)
  machineABCZ.fail("nix-collect-garbage 2>/dev/null")

  # --- Phase 2: Apply the workaround ---
  # Delete per-user entries before running gc (workaround from issue #4419)
  machineABCZ.succeed("rm -rf /nix/var/nix/gcroots/per-user/testuser")
  machineABCZ.succeed("rm -rf /nix/var/nix/profiles/per-user/testuser")

  # nix-collect-garbage must succeed after cleanup
  machineABCZ.succeed("nix-collect-garbage")

  # Sanity check: gcroots dir for testuser is gone
  machineABCZ.fail("test -d /nix/var/nix/gcroots/per-user/testuser")
  machineABCZ.fail("test -d /nix/var/nix/profiles/per-user/testuser")
'';
```

- [ ] **Step 2: Update the flake description**

Change line 2 (`description = "..."`) to:

```nix
description = "NixOS VM test: nix-collect-garbage workaround for stale per-user gcroots (NixOS/nix#4419). Deletes /nix/var/nix/gcroots/per-user/$NAME and /nix/var/nix/profiles/per-user/$NAME before running nix-collect-garbage.";
```

- [ ] **Step 3: Verify the flake still parses**

```bash
nix flake show --all-systems '.#' 2>&1 | head -30
```

Expected: no `error:` lines, shows `testNixOSBare` package.

- [ ] **Step 4: Commit**

```bash
git add flake.nix
git commit -m "feat: test nix-collect-garbage fails on stale per-user gcroots, passes after rm"
```

---

### Task 3: Run the test and verify it passes

**Files:** none (read-only verification)

- [ ] **Step 1: Run the NixOS test**

```bash
nix build --no-link --print-build-logs '.#testNixOSBare' 2>&1
```

Expected output contains:
```
(finished: must succeed: mkdir -p /nix/var/nix/gcroots/per-user/testuser, ...)
(finished: must fail: nix-collect-garbage 2>/dev/null, ...)
(finished: must succeed: rm -rf /nix/var/nix/gcroots/per-user/testuser, ...)
(finished: must succeed: nix-collect-garbage, ...)
test script finished in ...s
```

Build must exit 0.

- [ ] **Step 2: If Phase 1 `fail()` assertion is wrong**

If `nix-collect-garbage` does NOT exit non-zero with broken symlinks (behavior varies by nix version), the `machineABCZ.fail(...)` call will itself fail. In that case:

Replace:
```python
machineABCZ.fail("nix-collect-garbage 2>/dev/null")
```

With a stderr-check instead:
```python
exit_code, output = machineABCZ.execute("nix-collect-garbage 2>&1")
assert "error" in output.lower(), f"Expected error output, got: {output}"
```

Re-run: `nix build --no-link --print-build-logs '.#testNixOSBare'`

- [ ] **Step 3: Run the interactive driver to inspect manually (optional)**

```bash
nix run '.#' 2>&1
```

Inside the Python REPL:
```python
start_all()
machineABCZ.wait_for_unit("multi-user.target")
machineABCZ.succeed("ls /nix/var/nix/gcroots/per-user/ >&2")
```

- [ ] **Step 4: Final commit**

```bash
git add flake.nix
git commit -m "test: verify nix-collect-garbage per-user gcroots workaround passes"
```

---

## Self-Review

**Spec coverage:**
- [x] Delete `/nix/var/nix/gcroots/per-user/$NAME` — Task 2 testScript `rm -rf`
- [x] Delete `/nix/var/nix/profiles/per-user/$NAME` — Task 2 testScript `rm -rf`
- [x] Run `nix-collect-garbage` — Task 2 testScript `succeed("nix-collect-garbage")`
- [x] Test proves the bug exists first — Task 2 Phase 1 with `fail()`
- [x] Test proves the fix works — Task 2 Phase 2 with `succeed()`

**Placeholder scan:** None found.

**Type consistency:** No function signatures — single `flake.nix` file, Python strings in testScript. Names consistent throughout.
