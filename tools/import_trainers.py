"""Build ThirdParty/Trainers/Trainers.lua: every profession trainer in WoW Forever with position and rank.

Who is a trainer and where they stand: QuestieDB's Forever NPC data (name, sub name, NPC flags, faction, spawns)
and its Forever area -> UiMap table. Which ranks a trainer teaches: CMaNGOS classic-db's npc_trainer tables
(the rank lessons Apprentice/Journeyman/Expert/Artisan). Both inputs are pinned in ThirdParty/Trainers/SOURCES.json
by commit and SHA-256.

    python3 tools/import_trainers.py --questiedb DIR --classicdb FILE.sql.gz [--check]
"""
import argparse
import gzip
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ThirdParty' / 'Trainers'
NPC_FILE = 'data/Forever/foreverNpcDB.lua'
ZONE_FILE = 'support/Forever/Zones/areaIdToUiMapId.lua'

SKILL = {164: 'blacksmithing', 171: 'alchemy', 333: 'enchanting', 202: 'engineering', 165: 'leatherworking',
         197: 'tailoring', 186: 'mining', 182: 'herbalism', 393: 'skinning', 185: 'cooking', 129: 'firstaid',
         356: 'fishing'}
# The trainer spells that teach a rank (CMaNGOS npc_trainer.spell) -> profession and the cap that rank allows.
RANK = {
    2020: ('blacksmithing', 75), 2021: ('blacksmithing', 150), 3539: ('blacksmithing', 225), 9786: ('blacksmithing', 300),
    2155: ('leatherworking', 75), 2154: ('leatherworking', 150), 3812: ('leatherworking', 225), 10663: ('leatherworking', 300),
    2275: ('alchemy', 75), 2280: ('alchemy', 150), 3465: ('alchemy', 225), 11612: ('alchemy', 300),
    3911: ('tailoring', 75), 3912: ('tailoring', 150), 3913: ('tailoring', 225), 12181: ('tailoring', 300),
    4039: ('engineering', 75), 4040: ('engineering', 150), 4041: ('engineering', 225), 12657: ('engineering', 300),
    7414: ('enchanting', 75), 7415: ('enchanting', 150), 7416: ('enchanting', 225), 13921: ('enchanting', 300),
    2581: ('mining', 75), 2582: ('mining', 150), 3568: ('mining', 225), 10249: ('mining', 300),
    2372: ('herbalism', 75), 2373: ('herbalism', 150), 3571: ('herbalism', 225), 11994: ('herbalism', 300),
    8615: ('skinning', 75), 8619: ('skinning', 150), 8620: ('skinning', 225), 10769: ('skinning', 300),
    2551: ('cooking', 75), 3412: ('cooking', 150),          # Expert is a book, Artisan a quest
    3279: ('firstaid', 75), 3280: ('firstaid', 150),        # Expert is a book, Artisan a quest
    7733: ('fishing', 75), 7734: ('fishing', 150), 18249: ('fishing', 300),
}
TABLES = ('npc_trainer', 'npc_trainer_template', 'creature_template')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def sql_rows(text):
    """Rows of an INSERT's VALUES part as lists of strings (quotes removed, escapes undone)."""
    rows, row, value, quoted, i = [], None, [], False, 0
    while i < len(text):
        c = text[i]
        if quoted:
            if c == '\\':
                i += 1
                value.append(text[i])
            elif c == "'":
                quoted = False
            else:
                value.append(c)
        elif c == "'":
            quoted = True
        elif c == '(' and row is None:
            row, value = [], []
        elif c == ',' and row is not None:
            row.append(''.join(value).strip())
            value = []
        elif c == ')' and row is not None:
            row.append(''.join(value).strip())
            rows.append(row)
            row, value = None, []
        elif row is not None:
            value.append(c)
        i += 1
    return rows


def classicdb(data):
    columns, lines, table = {}, {t: [] for t in TABLES}, None
    for line in gzip.decompress(data).decode('utf-8', 'replace').splitlines():
        m = re.match(r'CREATE TABLE `(\w+)`', line)
        if m:
            table = m.group(1) if m.group(1) in TABLES else None
            if table:
                columns[table] = []
            continue
        if table and line.startswith('  `'):
            columns[table].append(line.split()[0].strip('`'))
        elif line.startswith(')'):
            table = None
        m = re.match(r'INSERT INTO `(\w+)`', line)
        if m and m.group(1) in TABLES:
            lines[m.group(1)].append(line)

    def records(name):
        for line in lines[name]:
            for values in sql_rows(line[line.index('VALUES') + 6:]):
                yield dict(zip(columns[name], values))
    creatures = {int(r['Entry']): r for r in records('creature_template')}
    direct, by_template = {}, {}
    for r in records('npc_trainer'):
        direct.setdefault(int(r['entry']), []).append(r)
    for r in records('npc_trainer_template'):
        by_template.setdefault(r['entry'], []).append(r)
    taught = {}
    for entry, c in creatures.items():
        rows = direct.get(entry, []) + by_template.get(c.get('TrainerTemplateId', '0'), [])
        if rows:
            taught[entry] = rows
    return taught


def questie_npcs(text):
    """npc id -> (name, fields after the name as Lua source)."""
    out = {}
    for m in re.finditer(r"^\[(\d+)\] = \{'((?:[^'\\]|\\.)*)',(.*)\},?\s*$", text, re.M):
        out[int(m.group(1))] = (m.group(2).replace("\\'", "'"), m.group(3))
    return out


def zone_maps(text):
    """area id -> (UiMapID, English name); the override table wins."""
    maps = {}
    for part in ('areaIdToUiMapId', 'areaIdToUiMapIdOverride'):
        m = re.search(r'ZoneDB\.private\.' + part + r' = \[\[return \{(.*?)\n\}\]\]', text, re.S)
        for area, ui, name in re.findall(r'\[(\d+)\]\s*=\s*(\d+),?\s*(?:--\s*([^\n]*))?', m.group(1) if m else ''):
            if int(ui) > 0:
                maps[int(area)] = (int(ui), (name or '').strip())
            else:
                maps.pop(int(area), None)
    return maps


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def build(npc_text, zone_text, cmangos, sources):
    npcs, maps, taught = questie_npcs(npc_text), zone_maps(zone_text), classicdb(cmangos)
    entries, skipped = [], {'notTrainer': 0, 'noRank': 0, 'noPosition': 0}
    for npc, rows in sorted(taught.items()):
        if npc not in npcs:
            continue
        name, rest = npcs[npc]
        tail = re.search(r',(nil|"[AH]+"),(nil|"(?:[^"\\]|\\.)*"),(nil|\d+)\s*$', rest)
        flags = int(tail.group(3)) if tail and tail.group(3) != 'nil' else 0
        if not flags & 16:
            skipped['notTrainer'] += 1
            continue
        caps = {}
        for r in rows:
            rank = RANK.get(int(r['spell']))
            if rank:
                caps[rank[0]] = max(caps.get(rank[0], 0), rank[1])
        if not caps:
            skipped['noRank'] += 1
            continue
        spawns = re.search(r'\{\[(\d+)\]=\{\{([\d.]+),([\d.]+)\}', rest)
        if not spawns or int(spawns.group(1)) not in maps:
            skipped['noPosition'] += 1
            continue
        ui, zone = maps[int(spawns.group(1))]
        side = {'"A"': 'Alliance', '"H"': 'Horde'}.get(tail.group(1), 'B')
        title = tail.group(2)[1:-1] if tail.group(2) != 'nil' else ''
        for prof, cap in sorted(caps.items()):
            entries.append((prof, npc, name, zone, ui, float(spawns.group(2)), float(spawns.group(3)), side, cap, title))
    entries.sort(key=lambda e: (e[0], e[7], -e[8], e[2]))
    lines = ['-- Profession trainers of WoW Forever. GENERATED by tools/import_trainers.py - do not edit by hand.',
             '-- Positions, factions and titles: QuestieDB Forever data (GPL-3.0, see SOURCE.md);',
             '-- ranks taught: CMaNGOS classic-db npc_trainer (GPL-3.0). Inputs pinned in SOURCES.json:',
             '-- QuestieDB %s, classic-db %s.' % (sources['questiedb']['commit'][:7], sources['classicdb']['commit'][:7]),
             '-- Fields: profession, npc, name, zone (English, the client name is used in game), UiMapID, x, y,',
             '-- faction, highest rank cap taught, sub name.',
             'local _, CP = ...', 'CP.GeneratedTrainers = {']
    for prof, npc, name, zone, ui, x, y, side, cap, title in entries:
        lines.append('  {%s,%d,%s,%s,%d,%.2f,%.2f,%s,%d,%s},' % (
            lua_str(prof), npc, lua_str(name), lua_str(zone), ui, x, y, lua_str(side), cap, lua_str(title)))
    lines.append('}')
    return ('\n'.join(lines) + '\n').encode('utf-8'), entries, skipped


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--questiedb', type=Path, required=True, help='QuestieDB checkout at the pinned commit')
    p.add_argument('--classicdb', type=Path, required=True, help='ClassicDB_1_12_1_z2815.sql.gz at the pinned commit')
    p.add_argument('--check', action='store_true')
    args = p.parse_args()
    sources = json.loads((OUT / 'SOURCES.json').read_text())
    npc_text = (args.questiedb / NPC_FILE).read_bytes()
    zone_text = (args.questiedb / ZONE_FILE).read_bytes()
    cmangos = args.classicdb.read_bytes()
    for name, data, spec in ((NPC_FILE, npc_text, sources['questiedb']['files'][NPC_FILE]),
                             (ZONE_FILE, zone_text, sources['questiedb']['files'][ZONE_FILE]),
                             ('classicdb', cmangos, sources['classicdb'])):
        if sha(data) != spec['sha256']:
            raise SystemExit('Checksum mismatch: ' + name)
    product, entries, skipped = build(npc_text.decode('utf-8'), zone_text.decode('utf-8'), cmangos, sources)
    target = OUT / 'Trainers.lua'
    if args.check:
        if target.read_bytes().replace(b'\r\n', b'\n') != product:
            raise SystemExit('Generated trainers differ from Trainers.lua')
    else:
        target.write_bytes(product)
    profs = sorted({e[0] for e in entries})
    print(f'PASS: {len(entries)} trainer entries for {len(profs)} professions, skipped {skipped}')


if __name__ == '__main__':
    main()
