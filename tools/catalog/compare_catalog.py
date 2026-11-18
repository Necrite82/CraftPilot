"""Compare CraftPilot's own catalog (Data/Catalog) with the bundled Craft Ladder snapshot (ThirdParty/CraftLadder).

    python3 tools/catalog/compare_catalog.py [--ours Data/Catalog] [--theirs ThirdParty/CraftLadder] [--out FILE.md]

Used while CraftPilot moves to its own catalog: it shows, per profession, recipes only one side has and recipes whose
colours, learn skill, product, materials or way to learn differ. Writes Markdown.
"""
import argparse
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import sources  # noqa: E402

FILES = {'alchemy': 'Alchemy', 'blacksmithing': 'Blacksmithing', 'enchanting': 'Enchanting',
         'engineering': 'Engineering', 'leatherworking': 'Leatherworking', 'tailoring': 'Tailoring'}
EXAMPLES = 12


def load(path, key=None):
    assigned = sources.lua_assignments(Path(path).read_text(encoding='utf-8'))
    if key and key in assigned:
        return assigned[key]
    return next(v for k, v in assigned.items() if isinstance(v, dict) and 'recipes' in v)


def kinds(recipe):
    out = set()
    for s in recipe.get('get') or []:
        kind = s.get('kind')
        if kind == 'trainer' and (s.get('costGuess') or recipe.get('guess')):
            kind = 'trainer?'
        out.add(kind)
    return out


def trainer_cost(recipe):
    for s in recipe.get('get') or []:
        if s.get('kind') == 'trainer' and not s.get('costGuess'):
            return s.get('cost')
    return None


def favors(recipe):
    return sorted((s.get('npc'), s.get('favor')) for s in recipe.get('get') or [] if s.get('favor'))


def as_map(mats):
    if isinstance(mats, list):
        return {i + 1: v for i, v in enumerate(mats) if v is not None}
    return dict(mats or {})


def compare(key, ours, theirs):
    a, b = ours['recipes'], theirs['recipes']
    only_ours = sorted(set(a) - set(b))
    only_theirs = sorted(set(b) - set(a))
    both = sorted(set(a) & set(b))
    diffs = {k: [] for k in ('colors', 'learn', 'makes', 'yield', 'mats', 'get', 'trainerCost', 'favor', 'item')}
    for spell in both:
        x, y = a[spell], b[spell]
        if list(x.get('colors') or [])[1:] != list(y.get('colors') or [])[1:]:
            diffs['colors'].append((spell, x.get('colors'), y.get('colors')))
        if x.get('learn') != y.get('learn'):
            diffs['learn'].append((spell, x.get('learn'), y.get('learn')))
        if (x.get('makes') or None) != (y.get('makes') or None):
            diffs['makes'].append((spell, x.get('makes'), y.get('makes')))
        if (x.get('yield') or 1) != (y.get('yield') or 1):
            diffs['yield'].append((spell, x.get('yield'), y.get('yield')))
        if as_map(x.get('mats')) != as_map(y.get('mats')):
            diffs['mats'].append((spell, as_map(x.get('mats')), as_map(y.get('mats'))))
        if kinds(x) != kinds(y):
            diffs['get'].append((spell, sorted(kinds(x)), sorted(kinds(y))))
        if trainer_cost(x) and trainer_cost(y) and trainer_cost(x) != trainer_cost(y):
            diffs['trainerCost'].append((spell, trainer_cost(x), trainer_cost(y)))
        if favors(x) != favors(y) and (favors(x) or favors(y)):
            diffs['favor'].append((spell, favors(x), favors(y)))
        if (x.get('item') or None) != (y.get('item') or None):
            diffs['item'].append((spell, x.get('item'), y.get('item')))
    return only_ours, only_theirs, both, diffs


def name(data, spell):
    r = data['recipes'].get(spell)
    return r.get('name') if r else '?'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ours', type=Path, default=ROOT / 'Data' / 'Catalog')
    ap.add_argument('--theirs', type=Path, default=ROOT / 'ThirdParty' / 'CraftLadder')
    ap.add_argument('--out', type=Path)
    args = ap.parse_args()
    lines = ['# Katalogvergleich: eigener Katalog vs. Craft Ladder', '']
    total = Counter()
    for key, display in FILES.items():
        ours_path, theirs_path = args.ours / f'{display}.lua', args.theirs / f'{display}.lua'
        if not ours_path.exists() or not theirs_path.exists():
            continue
        ours, theirs = load(ours_path), load(theirs_path, key.upper())
        only_ours, only_theirs, both, diffs = compare(key, ours, theirs)
        total.update({'ours': len(ours['recipes']), 'theirs': len(theirs['recipes']), 'both': len(both),
                      'onlyOurs': len(only_ours), 'onlyTheirs': len(only_theirs)})
        for k, v in diffs.items():
            total[k] += len(v)
        lines += [f'## {display}', '',
                  f'Rezepte: eigen {len(ours["recipes"])}, Craft Ladder {len(theirs["recipes"])}, gemeinsam {len(both)}',
                  '']
        get_ours = Counter(k for r in ours['recipes'].values() for k in kinds(r))
        get_theirs = Counter(k for r in theirs['recipes'].values() for k in kinds(r))
        lines.append('| Lernweg | eigen | Craft Ladder |')
        lines.append('|---|---|---|')
        for kind in sorted(set(get_ours) | set(get_theirs)):
            lines.append(f'| {kind} | {get_ours[kind]} | {get_theirs[kind]} |')
        lines.append('')
        if only_ours:
            lines.append(f'**Nur eigen ({len(only_ours)}):** ' + ', '.join(
                f'{s} {name(ours, s)}' for s in only_ours[:EXAMPLES]) + (' …' if len(only_ours) > EXAMPLES else ''))
            lines.append('')
        if only_theirs:
            lines.append(f'**Nur Craft Ladder ({len(only_theirs)}):** ' + ', '.join(
                f'{s} {name(theirs, s)}' for s in only_theirs[:EXAMPLES]) + (' …' if len(only_theirs) > EXAMPLES else ''))
            lines.append('')
        for k, rows in diffs.items():
            if rows:
                lines.append(f'**Abweichung {k} ({len(rows)}):**')
                for spell, x, y in rows[:EXAMPLES]:
                    lines.append(f'- {spell} {name(ours, spell)}: eigen `{x}` / CL `{y}`')
                lines.append('')
    labels = [('ours', 'Rezepte eigener Katalog'), ('theirs', 'Rezepte Craft Ladder'), ('both', 'gemeinsam'),
              ('onlyOurs', 'nur eigen'), ('onlyTheirs', 'nur Craft Ladder'), ('colors', 'abweichende Skillfarben'),
              ('learn', 'abweichende Lernstufe'), ('makes', 'abweichendes Ergebnis'), ('yield', 'abweichende Menge'),
              ('mats', 'abweichende Materialien'), ('item', 'abweichender Rezeptgegenstand'),
              ('get', 'abweichender Lernweg'), ('trainerCost', 'abweichende Lehrerkosten'),
              ('favor', 'abweichender Favor-Preis')]
    summary = ['| Kennzahl | Anzahl |', '|---|---|'] + [f'| {label} | {total[key]} |' for key, label in labels]
    lines[1:1] = [''] + summary + ['', 'Lernweg „trainer?“ = Lehrer mit geschätzten Kosten. Rezepte, die es laut '
                                   'AllTheThings in Forever (noch) nicht gibt, stehen im eigenen Katalog als '
                                   '`unavailable` ohne Lernweg.', '']
    text = '\n'.join(lines) + '\n'
    if args.out:
        args.out.write_text(text, encoding='utf-8')
    print(text)


if __name__ == '__main__':
    main()
