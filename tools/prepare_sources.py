"""Build a quarantined, reproducible reference dataset; never edit runtime data."""
import argparse
import hashlib
import json
import re
from pathlib import Path
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'research' / 'next-data'
BUILD = '1.60.1.70862'
PROFESSIONS = {'Engineering', 'Mining', 'Blacksmithing', 'Enchanting',
               'Tailoring', 'Leatherworking', 'Alchemy', 'Herbalism'}

def digest(data):
    return hashlib.sha256(data).hexdigest()

def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode()

def catalog():
    """Read only the documented generated, one-recipe-per-line catalog format."""
    recipes, items, npcs = {}, set(), set()
    for path in sorted((ROOT / 'ThirdParty' / 'CraftLadder').glob('*.lua')):
        in_recipes = False
        for line in path.read_text(encoding='utf-8').splitlines():
            if line == '  recipes = {':
                in_recipes = True
            elif line == '  },':
                in_recipes = False
            match = re.match(r'    \[(\d+)\] = \{ name = ', line) if in_recipes else None
            if match:
                spell = int(match[1])
                learn = re.search(r'\blearn = (\d+)', line)
                if not learn:
                    raise ValueError('Unsupported catalog recipe format')
                recipes[spell] = {'profession': path.stem, 'learn': int(learn[1])}
                for key in ('item',):
                    items.update(map(int, re.findall(r'\b' + key + r' = (\d+)', line)))
                mats = re.search(r'\bmats = \{([^}]*)\}', line)
                if mats:
                    items.update(map(int, re.findall(r'\[(\d+)\]', mats[1])))
            npcs.update(map(int, re.findall(r'\bnpc = (\d+)', line)))
            for group in re.findall(r'\btrainers = \{([^}]*)\}', line):
                npcs.update(map(int, re.findall(r'\d+', group)))
    if len(recipes) < 100:
        raise ValueError('Catalog format changed or catalog missing')
    return recipes, items, npcs

def select_eg(trainers, vendors, recipes, item_ids):
    selected_t, selected_v = {}, {}
    for npc, value in trainers.items():
        if not value.get('tradeskill'):
            continue
        services = {key: service for key, service in value.get('services', {}).items()
                    if int(key) in recipes or service.get('skill') in PROFESSIONS
                    or service.get('profession') in PROFESSIONS}
        if services:
            # Preserve evidence counts, level=0, prices, conditions and source positions.
            selected_t[npc] = {**value, 'services': services}
    for npc, value in vendors.items():
        entries = {key: entry for key, entry in value.get('entries', {}).items()
                   if entry.get('itemId') in item_ids}
        if entries:
            selected_v[npc] = {**value, 'entries': entries}
    return selected_t, selected_v

def validate_eg(data, kind):
    meta = data['meta']
    if (meta['product'], meta['clientBuild'], meta['schemaVersion'], meta['license'], meta['dataset']) != (
            'wowf', BUILD, 1, 'CC BY 4.0', kind):
        raise ValueError('Unexpected EG dataset identity/license/schema')
    for npc, record in data[kind].items():
        if not npc.isdecimal() or int(npc) <= 0 or record['sources'] < 1:
            raise ValueError('Invalid NPC or evidence count')
        for pos in record.get('positions', []):
            if not (0 <= pos['mapX'] <= 1 and 0 <= pos['mapY'] <= 1 and pos['uiMap'] > 0):
                raise ValueError('Invalid EG map position')
        for key, entry in record.get('services' if kind == 'trainers' else 'entries', {}).items():
            if entry['sources'] < 1:
                raise ValueError('Invalid service evidence count')
            if kind == 'trainers' and str(entry['spellId']) != key:
                raise ValueError('Spell ID/key mismatch')

def blocks(text):
    """Extract top-level numeric records from pfQuest's generated table only."""
    return {int(m[1]): m[0] for m in re.finditer(
        r'^  \[(\d+)\] = \{\n.*?^  \},?[ \t]*$', text, re.M | re.S)}

def lua_subset(header, records):
    return ('-- pfQuest Classic reference subset, modified by filtering records.\n'
            '-- Copyright (c) 2017-2021 Eric Mauser (Shagu); MIT, see pfQuest-LICENSE.\n'
            + header + ' = {\n' + '\n'.join(records[k].rstrip() for k in sorted(records))
            + '\n}\n').encode()

def build(cache, lock):
    raw = {}
    for source, spec in lock['sources'].items():
        for name, expected in spec['files'].items():
            data = (cache / source / name).read_bytes()
            if digest(data) != expected:
                raise ValueError(f'Source checksum mismatch: {source}/{name}')
            raw[source, name] = data
    recipes, item_ids, catalog_npcs = catalog()
    eg = {}
    for kind in ('trainers', 'vendors'):
        eg[kind] = json.loads(raw['eg', f'data/wowf/{BUILD}/{kind}.json'])
        validate_eg(eg[kind], kind)
    trainers, vendors = select_eg(eg['trainers']['trainers'], eg['vendors']['vendors'], recipes, item_ids)
    units = blocks(raw['pf', 'db/units.lua'].decode())
    pf_items = blocks(raw['pf', 'db/items.lua'].decode())
    vendor_links = {}
    for item in sorted(item_ids & pf_items.keys()):
        match = re.search(r'\["V"\] = \{(.*?)\n    \}', pf_items[item], re.S)
        if match:
            vendor_links[str(item)] = {npc: int(value) for npc, value in
                                      re.findall(r'\[(\d+)\] = (-?\d+),', match[1])}
    wanted = catalog_npcs | set(map(int, trainers)) | set(map(int, vendors))
    wanted |= {int(npc) for links in vendor_links.values() for npc in links}
    unit_subset = {npc: units[npc] for npc in wanted & units.keys()}
    for block in unit_subset.values():
        for x, y, zone in re.findall(r'= \{ ([\d.]+), ([\d.]+), (\d+), [\d.]+ \}', block):
            if not (0 <= float(x) <= 100 and 0 <= float(y) <= 100 and int(zone) > 0):
                raise ValueError('Invalid pfQuest legacy coordinate')
    products = {}
    for lang in ('enUS', 'deDE'):
        text = raw['pf', f'db/{lang}/units.lua'].decode()
        lines = {int(m[1]): m[0] for m in re.finditer(r'^  \[(\d+)\] = .*,$', text, re.M)}
        products[f'pfQuest-units-{lang}.lua'] = lua_subset(
            f'pfDB["units"]["{lang}"]', {npc: lines[npc] for npc in unit_subset if npc in lines})
    products['pfQuest-units.lua'] = lua_subset('pfDB["units"]["data"]', unit_subset)
    products['pfQuest-vendors.json'] = encode({'license': 'MIT', 'reference': 'Classic; not Forever-verified',
                                               'items': vendor_links})
    comparisons = []
    for npc, trainer in trainers.items():
        for spell, service in trainer['services'].items():
            old = recipes.get(int(spell))
            if old:
                comparisons.append({'npc': int(npc), 'spell': int(spell), 'catalog': old,
                                    'observedSkill': service.get('skillRank'),
                                    'sameSkill': old['learn'] == service.get('skillRank'),
                                    'sources': service['sources']})
    for kind, selected in [('trainers', trainers), ('vendors', vendors)]:
        products[f'eg-{kind}.json'] = encode({
            'meta': eg[kind]['meta'], 'modifications': 'Filtered to CraftPilot catalog/professions; fields preserved.',
            kind: selected})
    products['eg-LICENSE'] = raw['eg', 'LICENSE']
    products['eg-README.md'] = raw['eg', 'README.md']
    products['pfQuest-LICENSE'] = raw['pf', 'LICENSE']
    products['questie-LICENSE-review.md'] = raw['questie', 'LICENSE.md']
    report = {
        'runtimeLoaded': False, 'gameClientTested': False,
        'catalogRecipes': len(recipes), 'relevantItems': len(item_ids),
        'egTrainerNpcs': len(trainers), 'egServices': sum(len(t['services']) for t in trainers.values()),
        'egVendorNpcs': len(vendors), 'egVendorEntries': sum(len(v['entries']) for v in vendors.values()),
        'egMultiSourceServices': sum(s['sources'] >= 2 for t in trainers.values() for s in t['services'].values()),
        'pfQuestNpcs': len(unit_subset), 'pfQuestVendorItems': len(vendor_links),
        'pfQuestMissingNpcIds': sorted(wanted - units.keys()),
        'skillComparisons': comparisons,
        'skillDisagreements': sum(not c['sameSkill'] for c in comparisons),
        'limitations': ['EG sources count files, not independent confirmation of every field.',
                        'EG positions are player positions when opening windows.',
                        'EG zero level is unknown, not proof of no requirement.',
                        'No absence inference from missing observations.',
                        'pfQuest coords retain legacy zone IDs and percent scale; never UiMapIDs.',
                        'pfQuest vendor values retained verbatim; not normalized to prices.',
                        'No new QuestieDB data imported: historical license coverage unresolved.']}
    products['validation.json'] = encode(report)
    manifest = {'schemaVersion': 1, 'reviewedOn': '2026-11-08', 'sources': lock['sources'],
                'catalogBase': 'daecfb866ed34d512ed0885e60d9dfa706459674',
                'outputs': {name: digest(data) for name, data in products.items()}}
    products['manifest.json'] = encode(manifest)
    return products

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-dir', type=Path, required=True)
    parser.add_argument('--download', action='store_true', help='Fetch only pinned, hash-checked source files')
    parser.add_argument('--check', action='store_true', help='Compare without writing outputs')
    args = parser.parse_args()
    lock = json.loads((OUT / 'sources.lock.json').read_text())
    if args.download:
        for source, spec in lock['sources'].items():
            for name, expected in spec['files'].items():
                path = args.source_dir / source / name
                if path.exists() and digest(path.read_bytes()) == expected:
                    continue
                url = f"https://raw.githubusercontent.com/{spec['repository']}/{spec['revision']}/{name}"
                with urlopen(url, timeout=60) as response:
                    data = response.read()
                if digest(data) != expected:
                    raise ValueError(f'Download checksum mismatch: {source}/{name}')
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
    products = build(args.source_dir, lock)
    for name, data in products.items():
        path = OUT / name
        if args.check:
            if path.read_bytes() != data:
                raise ValueError(f'Non-reproducible output: {name}')
        else:
            path.write_bytes(data)
    print(f'PASS: {len(products)} reference files {"verified" if args.check else "prepared"}; runtime untouched')

if __name__ == '__main__':
    main()
