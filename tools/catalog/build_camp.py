"""Build Data/Catalog/Camp.lua: WoW Forever's camps (campfires and camp features), from the client's own tables.

    python3 tools/catalog/build_camp.py --inputs DIR [--out Data/Catalog]

A campfire holds a number of camp features; sitting near it gives each feature's buff. Each camp item's spell
description says what it does: the buff by player level (written as $?$PL<24[6]?$PL<38[11][$1230172s1]), what it
doesn't stack with, and which feature an upgrade replaces ("May be placed over a Mana Well to replace it").
This builder renders those descriptions for every level 1-60 and keeps where the value changes. The recipe that
makes each item, its profession and materials come from the recipe tables. Nothing comes from other addons.
"""
import argparse
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import sources  # noqa: E402
from build_catalog import lua  # noqa: E402
from sources import num  # noqa: E402

FIRST, LAST = 279940, 279990          # the camp items
MAX_LEVEL = 60
CREATE_ITEM = 24
SKILL_KEYS = {164: 'blacksmithing', 165: 'leatherworking', 171: 'alchemy', 197: 'tailoring', 202: 'engineering',
              333: 'enchanting', 186: 'mining', 182: 'herbalism', 393: 'skinning', 356: 'fishing', 185: 'cooking',
              129: 'firstaid'}
# what a feature's buff is, by a word in what it gives (checked in this order)
KINDS = (('Attack Power', 'ap'), ('Strength', 'str'), ('Mana every', 'mp5'), ('Intellect', 'int'), ('% stats', 'stats'),
         ('Stamina', 'sta'), ('Spirit', 'spi'), ('Armor', 'armor'), ('Rested', 'rested'), ('critical strike', 'crit'),
         ('reagents', 'vendor'))


class Spells:
    def __init__(self, client):
        self.desc = {int(r['ID']): r['Description_lang'] for r in client.rows('Spell')}
        self.effects = {}
        for e in client.rows('SpellEffect'):
            self.effects.setdefault(int(e['SpellID']), {})[num(e['EffectIndex'])] = num(e['EffectBasePointsF'])
        durations = {int(r['ID']): num(r['Duration']) for r in client.rows('SpellDuration')}
        self.duration = {}
        for r in client.rows('SpellMisc'):
            if num(r['DifficultyID']) == 0 and num(r['DurationIndex']):
                self.duration[num(r['SpellID'])] = durations.get(num(r['DurationIndex']), 0)

    def value(self, spell, index):
        return self.effects.get(spell, {}).get(index, 0)

    def duration_text(self, spell):
        ms = self.duration.get(spell, 0)
        if ms <= 0:
            return ''
        seconds = ms // 1000
        for unit, size in (('hour', 3600), ('min', 60)):
            if seconds >= size and seconds % size == 0:
                n = seconds // size
                return f'{n} {unit}' + ('s' if unit == 'hour' and n > 1 else '')
        return f'{seconds} sec'


def render(text, spell, level, spells):
    """Resolve a spell description for one player level: $?$PL<N[a]?$PL>M[b][c], $Ns1, $s1, $Nd, $d."""
    out, i = [], 0
    while i < len(text):
        if text.startswith('$?', i):
            i += 1
            chosen, decided = '', False
            while i < len(text) and text[i] == '?':
                m = re.match(r'\?\$PL([<>])(\d+)', text[i:])
                if not m:
                    break
                i += m.end()
                body, i = _bracket(text, i)
                op, n = m.group(1), int(m.group(2))
                if not decided and ((op == '<' and level < n) or (op == '>' and level > n)):
                    chosen, decided = body, True
            if i < len(text) and text[i] == '[':
                body, i = _bracket(text, i)
                if not decided:
                    chosen = body
            out.append(render(chosen, spell, level, spells))
            continue
        m = re.match(r'\$(\d*)([sd])(\d?)', text[i:])
        if m:
            target = int(m.group(1)) if m.group(1) else spell
            if m.group(2) == 's':
                out.append(str(int(spells.value(target, int(m.group(3) or 1) - 1))))
            else:
                out.append(spells.duration_text(target))
            i += m.end()
            continue
        out.append(text[i])
        i += 1
    return ''.join(out)


def _bracket(text, i):
    """The text inside [ ... ] starting at text[i] == '[', nested brackets included; returns (body, next index)."""
    assert text[i] == '['
    depth, j = 0, i
    while j < len(text):
        if text[j] == '[':
            depth += 1
        elif text[j] == ']':
            depth -= 1
            if depth == 0:
                return text[i + 1:j], j + 1
        j += 1
    return text[i + 1:], len(text)


def first_sentence(text):
    return re.split(r'\.(?:\s|$)', text.replace('\r', ''), maxsplit=1)[0]


def benefit(text):
    """'+6 Strength', '+10 Mana every 5 sec', 'Purchase reagents' ... from a rendered description."""
    m = re.search(r'nearby (?:to )?(.+?)(?:, mutually exclusive with [^.]+)?\.(?:\s|$)', text.replace('\r', ''))
    if not m:
        return None
    clause = m.group(1)
    clause = re.sub(r'^(gain|regenerate) ', '', clause)
    m2 = re.match(r'increase (Rested experience) to (.+)', clause)
    if m2:
        return f'{m2.group(1)} up to {m2.group(2)}'
    clause = clause.replace('increase to ', '').replace('increased ', '')
    clause = re.sub(r'(^|, and |, | and )(\d+%?)', lambda x: x.group(1) + '+' + x.group(2), clause)
    clause = re.sub(r'\s+', ' ', clause).strip()
    return clause[:1].upper() + clause[1:] if not clause.startswith('+') else clause


def adds_text(text, name):
    """What an upgrade or other camp object adds, from its first sentence: 'Usable for recipes that require it'."""
    sentence = first_sentence(text)
    lower = sentence.lower()
    at = lower.find(name.lower())
    rest = sentence[at + len(name):] if at >= 0 else ''
    rest = re.sub(r',? and provides all (?:of )?the benefits of .*$', '', rest).strip(' ,')
    rest = re.sub(r'^(that|which) ', '', rest)
    return rest[:1].upper() + rest[1:] if rest else ''


def gives_by_level(text, spell, spells):
    steps = []
    for level in range(1, MAX_LEVEL + 1):
        value = benefit(render(text, spell, level, spells))
        if steps and steps[-1][1] == value:
            steps[-1][0] = level
        else:
            steps.append([level, value])
    return [[lv, v] for lv, v in steps if v]


def build(client):
    spells = Spells(client)
    items = client.by_id('ItemSparse')
    item_effects = client.by_id('ItemEffect')
    casts = {}
    for r in client.rows('ItemXItemEffect'):
        e = item_effects.get(int(r['ItemEffectID']))
        if e and num(e['TriggerType']) == 0 and num(e['SpellID']):
            casts.setdefault(int(r['ItemID']), num(e['SpellID']))
    # the recipe that makes an item: create-item effect + skill line + materials
    makes = {}
    for e in client.rows('SpellEffect'):
        if num(e['Effect']) == CREATE_ITEM and FIRST <= num(e['EffectItemType']) <= LAST:
            makes.setdefault(num(e['EffectItemType']), int(e['SpellID']))
    skill_of = {}
    for r in client.rows('SkillLineAbility'):
        if num(r['SkillLine']) in SKILL_KEYS:
            skill_of.setdefault(num(r['Spell']), SKILL_KEYS[num(r['SkillLine'])])
    reagents = {int(r['SpellID']): r for r in client.rows('SpellReagents')}
    names = {}

    def entry(item):
        spell = casts.get(item)
        maker = makes.get(item)
        if not spell or not maker or maker not in skill_of:
            return None
        name = items[item]['Display_lang']
        mats = {}
        r = reagents.get(maker)
        if r:
            for i in range(8):
                mat, n = num(r.get(f'Reagent_{i}')), num(r.get(f'ReagentCount_{i}'))
                if mat > 0 and n > 0:
                    mats[mat] = mats.get(mat, 0) + n
                    names[mat] = items[mat]['Display_lang'] if mat in items else str(mat)
        names[item] = name
        return {'item': item, 'spell': spell, 'name': name, 'maker': maker, 'prof': skill_of[maker], 'mats': mats}

    fires, bases, upgrades, others = [], {}, [], []
    for item in range(FIRST, LAST + 1):
        if item not in items:
            continue
        e = entry(item)
        if not e:
            continue
        text = spells.desc.get(e['spell'], '')
        if 'campfire that allows cooking' in text:
            e['name'] = re.sub(r' Kit$', '', e['name'])
            e['slots'] = int(spells.value(e['spell'], 0))
            fires.append(e)
            continue
        over = re.search(r'May be placed over an? (.+?) to replace it', text)
        if over:
            e['adds'] = adds_text(render(text, e['spell'], MAX_LEVEL, spells), e['name'])
            upgrades.append((over.group(1), e))
            continue
        if re.search(r'nearby (?:to |\$)', text):
            gives = gives_by_level(text, e['spell'], spells)
            e['kind'] = next((kind for word, kind in KINDS if any(word in g[1] for g in gives)), 'other')
            e['gives'] = gives
            exclusive = re.search(r'mutually exclusive with ([^.]+)\.', text)
            if exclusive:
                e['exclusive'] = exclusive.group(1)
            if 'members of the Horde' in text:
                e['faction'] = 'H'
            elif 'members of the Alliance' in text:
                e['faction'] = 'A'
            bases.setdefault(e['name'], []).append(e)
            continue
        e['adds'] = adds_text(render(text, e['spell'], MAX_LEVEL, spells), e['name'])
        others.append(e)
    for base_name, upgrade in upgrades:
        for base in bases.get(base_name, []):
            base.setdefault('upgrades', []).append(upgrade)
    features = [b for group in bases.values() for b in group]
    features.sort(key=lambda b: b['item'])
    for b in features:
        b.get('upgrades', []).sort(key=lambda u: u['item'])
    fires.sort(key=lambda f: f['slots'])
    return {'built': client.manifest['fetched'][:10], 'build': client.build, 'fires': fires, 'features': features,
            'others': others, 'items': dict(sorted(names.items()))}


HEADER = '''-- CraftPilot camp data. GENERATED by tools/catalog/build_camp.py - do not edit by hand.
-- From the WoW Forever client's own tables, build {build}: fires = the campfires (slots: how many features each
-- holds); features: a buff near a campfire, gives = {{ up to this level, what it gives }} as its description says,
-- kind = the buff, exclusive = the class buff it doesn't stack with, upgrades = what can replace it and what it adds;
-- others = camp objects with no buff. maker = the recipe (spell) that makes the item, prof = its profession,
-- mats = what that takes. items = the names of every item named here.
local _, CP = ...
CP.CAMP = '''


def write(data, out):
    lines = [HEADER.format(build=data['build']).rstrip() + ' {', f"  built = {lua(data['built'])},",
             f"  build = {lua(data['build'])},"]
    for section in ('fires', 'features', 'others'):
        lines.append(f'  {section} = {{')
        for row in data[section]:
            lines.append(f'    {lua(row)},')
        lines.append('  },')
    lines.append('  items = {')
    for item, name in data['items'].items():
        lines.append(f'    [{item}] = {lua(name)},')
    lines.append('  },')
    lines.append('}')
    path = out / 'Camp.lua'
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    return path


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--inputs', required=True, type=Path)
    ap.add_argument('--out', type=Path, default=ROOT / 'Data' / 'Catalog')
    args = ap.parse_args()
    data = build(sources.ClientTables(args.inputs))
    args.out.mkdir(parents=True, exist_ok=True)
    path = write(data, args.out)
    print(f"camp: {len(data['fires'])} fires, {len(data['features'])} features, "
          f"{sum(len(f.get('upgrades', [])) for f in data['features'])} upgrades, {len(data['others'])} others -> {path}")


if __name__ == '__main__':
    main()
