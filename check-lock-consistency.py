#!/usr/bin/env python3
"""
Verifica se todos os templates usam os mesmos commits (rev) para cada input.

Lê todos os flake.lock em src/templates/*/flake.lock e agrupa por input name,
mostrando quais templates divergem do rev mais comum.

Uso:
    python3 check-lock-consistency.py
"""

import os
import json
from collections import defaultdict

TEMPLATES_ROOT = os.path.join(os.path.dirname(__file__), 'src/templates')

# input_name -> rev -> [template_name, ...]
by_input = defaultdict(lambda: defaultdict(list))

lock_files = sorted([
    (os.path.basename(os.path.dirname(p)), p)
    for d in os.listdir(TEMPLATES_ROOT)
    if os.path.isdir(os.path.join(TEMPLATES_ROOT, d))
    for p in [os.path.join(TEMPLATES_ROOT, d, 'flake.lock')]
    if os.path.isfile(p)
])

print(f'Lendo {len(lock_files)} flake.lock files...\n')

for template_name, lock_path in lock_files:
    with open(lock_path) as f:
        lock = json.load(f)

    nodes = lock.get('nodes', {})
    root_inputs = nodes.get('root', {}).get('inputs', {})

    for input_name, node_ref in root_inputs.items():
        # node_ref pode ser string (node name) ou lista (path para nó transitivo)
        if isinstance(node_ref, list):
            continue  # input transitivo, pula
        node = nodes.get(node_ref, {})
        rev = node.get('locked', {}).get('rev')
        if rev:
            by_input[input_name][rev].append(template_name)

# Relatório
divergent = []
consistent = []

for input_name in sorted(by_input):
    revs = by_input[input_name]
    if len(revs) == 1:
        consistent.append(input_name)
    else:
        divergent.append(input_name)

print(f'{"="*60}')
print(f'CONSISTENTES ({len(consistent)}): {", ".join(consistent)}')
print(f'{"="*60}\n')

if not divergent:
    print('Todos os inputs estão nos mesmos commits!')
else:
    print(f'DIVERGENTES ({len(divergent)}):')
    print(f'{"="*60}')
    for input_name in divergent:
        revs = by_input[input_name]
        # rev mais comum = majoritário
        majority_rev = max(revs, key=lambda r: len(revs[r]))
        majority_count = len(revs[majority_rev])
        total = sum(len(v) for v in revs.values())
        print(f'\n[{input_name}] — {len(revs)} revs diferentes, {total} templates')
        for rev, templates in sorted(revs.items(), key=lambda x: -len(x[1])):
            marker = '✓' if rev == majority_rev else '✗'
            print(f'  {marker} {rev[:16]}... ({len(templates)} templates)')
            if rev != majority_rev:
                for t in sorted(templates):
                    print(f'      - {t}')
