#!/usr/bin/env python3
"""
Executa allTests em todos os templates que o definem.
Roda GC agressivo como root quando o disco ultrapassar o threshold.

Uso:
    python3 run-all-tests.py
"""

import os
import subprocess
import shutil

TEMPLATES_ROOT = os.path.join(os.path.dirname(__file__), 'src/templates')
GC_THRESHOLD = 70  # % de uso do disco para disparar o GC


def disk_pct():
    s = shutil.disk_usage('/')
    return s.used * 100 // s.total


def run_gc():
    print('[gc] Rodando GC agressivo como root...', flush=True)
    gc_cmd = (
        'nix store gc --verbose'
        ' --option keep-build-log false'
        ' --option keep-derivations false'
        ' --option keep-env-derivations false'
        ' --option keep-failed false'
        ' --option keep-going false'
        ' --option keep-outputs false'
        ' && nix-collect-garbage --delete-old'
        ' && nix store optimise --verbose'
        ' && du -cksh /nix'
    )
    subprocess.run(['sudo', 'su', '-', '-c', gc_cmd])


def maybe_gc():
    pct = disk_pct()
    print(f'[disk] {pct}% usado', flush=True)
    if pct >= GC_THRESHOLD:
        run_gc()


dirs = sorted([
    d for d in os.listdir(TEMPLATES_ROOT)
    if d != 'default.nix'
    and os.path.isdir(os.path.join(TEMPLATES_ROOT, d))
    and os.path.isfile(os.path.join(TEMPLATES_ROOT, d, 'flake.nix'))
])

print(f'Templates com flake.nix: {len(dirs)}', flush=True)
maybe_gc()

failed = []
skipped = []

for name in dirs:
    path = os.path.join(TEMPLATES_ROOT, name)

    check = subprocess.run(
        ['nix', 'eval', '.#apps.x86_64-linux.allTests'],
        capture_output=True, text=True, cwd=path
    )
    if check.returncode != 0:
        skipped.append(name)
        print(f'SKIP (no allTests): {name}', flush=True)
        continue

    print(f'\n=== {name} ===', flush=True)
    maybe_gc()
    result = subprocess.run(['nix', 'run', '.#allTests'], cwd=path)
    if result.returncode != 0:
        failed.append(name)
        print(f'FAILED: {name}', flush=True)

print()
print('=== SUMMARY ===')
print(f'Total:   {len(dirs)}')
print(f'Skipped: {len(skipped)}')
print(f'Failed ({len(failed)}): {failed}')
maybe_gc()
