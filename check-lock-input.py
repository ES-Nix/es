#!/usr/bin/env python3
"""
Mostra os revs de um input específico em todos os templates,
agrupando por rev e indicando quais estão desatualizados.

Uso:
    python3 check-lock-input.py <input-name>

Exemplos:
    python3 check-lock-input.py nixpkgs
    python3 check-lock-input.py poetry2nix
    python3 check-lock-input.py home-manager
"""

import os
import json
import sys
from collections import defaultdict

if len(sys.argv) < 2:
    print(__doc__)
    sys.exit(1)

INPUT_NAME = sys.argv[1]
TEMPLATES_ROOT = os.path.join(os.path.dirname(__file__), 'src/templates')

by_rev = defaultdict(list)

for d in sorted(os.listdir(TEMPLATES_ROOT)):
    lock_path = os.path.join(TEMPLATES_ROOT, d, 'flake.lock')
    if not os.path.isfile(lock_path):
        continue
    with open(lock_path) as f:
        lock = json.load(f)
    nodes = lock.get('nodes', {})
    root_inputs = nodes.get('root', {}).get('inputs', {})
    if INPUT_NAME not in root_inputs:
        continue
    node_ref = root_inputs[INPUT_NAME]
    if isinstance(node_ref, list):
        continue  # transitivo
    rev = nodes.get(node_ref, {}).get('locked', {}).get('rev', 'unknown')
    by_rev[rev].append(d)

if not by_rev:
    print(f'Nenhum template usa "{INPUT_NAME}" como input direto.')
    sys.exit(0)

majority = max(by_rev, key=lambda r: len(by_rev[r]))
total = sum(len(v) for v in by_rev.values())

print(f'Input: {INPUT_NAME} — {total} templates, {len(by_rev)} revs diferentes\n')

for rev, templates in sorted(by_rev.items(), key=lambda x: -len(x[1])):
    marker = '✓ OK' if rev == majority else '✗ DESATUALIZADO'
    print(f'[{marker}] {rev}  ({len(templates)} templates)')
    for t in templates:
        print(f'    - {t}')
    print()
