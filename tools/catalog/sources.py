"""Readers for the inputs of CraftPilot's own recipe catalog.

  ClientTables  the WoW Forever client's DB2 tables (catalog-inputs branch, see fetch_inputs.py)
  LuaReader     a reader for Lua table constructors (QuestieDB's data files, generated catalogs)
  QuestieDB     items, NPCs, quests and zones from the QuestieDB addon's Forever data (GPL-3.0)
  trainers()    which trainer teaches which spell, at which skill and for how much: CMaNGOS classic-db (GPL-3.0)

Only facts are read here; nothing of these files is copied into the addon as is.
"""
import csv
import gzip
import io
import json
import re
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
import import_trainers  # noqa: E402  (CMaNGOS SQL reader shared with the trainer list)


class ClientTables:
    def __init__(self, folder):
        self.folder = Path(folder)
        self.manifest = json.loads((self.folder / 'manifest.json').read_text())
        self._cache = {}

    @property
    def build(self):
        return self.manifest['build']

    def rows(self, name):
        if name not in self._cache:
            with gzip.open(self.folder / f'{name}.csv.gz', 'rb') as f:
                text = f.read().decode('utf-8-sig')
            self._cache[name] = list(csv.DictReader(io.StringIO(text)))
        return self._cache[name]

    def by_id(self, name, key='ID'):
        return {int(r[key]): r for r in self.rows(name)}

    def grouped(self, name, key):
        out = {}
        for r in self.rows(name):
            out.setdefault(int(r[key]), []).append(r)
        return out


def num(value, default=0):
    try:
        f = float(value)
    except (TypeError, ValueError):
        return default
    return int(f) if f == int(f) else f


# --- Lua table constructors ------------------------------------------------------------------------------------

TOKEN = re.compile(r'''\s*(?:
    (?P<comment>--\[\[.*?\]\]|--[^\n]*)
  | (?P<str>"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')
  | (?P<num>-?(?:0x[0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+))
  | (?P<name>[A-Za-z_][A-Za-z_0-9]*)
  | (?P<sym>[{}\[\]=,;])
)''', re.S | re.X)
ESC = {'n': '\n', 't': '\t', '\\': '\\', '"': '"', "'": "'", '\n': '\n'}


def _unquote(s):
    body, out, i = s[1:-1], [], 0
    while i < len(body):
        c = body[i]
        if c == '\\' and i + 1 < len(body):
            nxt = body[i + 1]
            if nxt.isdigit():
                m = re.match(r'\d{1,3}', body[i + 1:])
                out.append(chr(int(m.group(0))))
                i += 1 + len(m.group(0))
                continue
            out.append(ESC.get(nxt, nxt))
            i += 2
            continue
        out.append(c)
        i += 1
    return ''.join(out)


class LuaReader:
    """Reads one Lua value (a table constructor and what it holds) starting at a position in a text."""

    def __init__(self, text):
        self.tokens = []
        pos = 0
        while pos < len(text):
            m = TOKEN.match(text, pos)
            if not m or m.end() == pos:
                if text[pos:].strip() == '':
                    break
                raise ValueError('Lua: cannot read at %r' % text[pos:pos + 40])
            pos = m.end()
            kind = m.lastgroup
            if kind == 'comment':
                continue
            self.tokens.append((kind, m.group(kind)))
        self.i = 0

    def peek(self, k=0):
        return self.tokens[self.i + k] if self.i + k < len(self.tokens) else (None, None)

    def take(self):
        tok = self.tokens[self.i]
        self.i += 1
        return tok

    def value(self):
        kind, text = self.take()
        if kind == 'str':
            return _unquote(text)
        if kind == 'num':
            return int(text, 16) if text.lower().startswith('0x') else num(text)
        if kind == 'name':
            return {'nil': None, 'true': True, 'false': False}.get(text, text)
        if text == '{':
            return self.table()
        raise ValueError('Lua: unexpected %r' % text)

    def table(self):
        array, hashed, n = [], {}, 0
        while True:
            kind, text = self.peek()
            if text == '}':
                self.take()
                break
            if text == '[':
                self.take()
                key = self.value()
                self.take()  # ]
                self.take()  # =
                hashed[key] = self.value()
            elif kind == 'name' and self.peek(1)[1] == '=':
                key = self.take()[1]
                self.take()
                hashed[key] = self.value()
            else:
                n += 1
                v = self.value()
                if v is not None:
                    hashed[n] = v
                array.append(v)
            if self.peek()[1] in (',', ';'):
                self.take()
        if hashed and set(hashed) == set(range(1, len(array) + 1)) and len(array) == n:
            return array
        if not hashed:
            return array
        return hashed


def lua_value(text):
    return LuaReader(text).value()


def lua_assignments(text):
    """`name = {...}` and `ns.NAME = {...}` at the top level of a file -> {NAME: value}."""
    out = {}
    for m in re.finditer(r'^(?:[A-Za-z_][\w.]*\.)?([A-Za-z_]\w*)\s*=\s*\{', text, re.M):
        start = m.end() - 1
        reader = LuaReader(text[start:])
        out[m.group(1)] = reader.value()
    return out


# --- QuestieDB --------------------------------------------------------------------------------------------------

def _questie_block(path, var):
    text = Path(path).read_text(encoding='utf-8')
    m = re.search(r'QuestieDB\.' + var + r' = \[(=*)\[return (\{.*\})\]\1\]', text, re.S)
    if not m:
        raise SystemExit(f'QuestieDB: no {var} in {path}')
    return lua_value(m.group(2))


def _at(row, index):
    """QuestieDB rows are arrays (1-based in Lua); missing trailing fields are nil."""
    if isinstance(row, dict):
        return row.get(index)
    return row[index - 1] if index - 1 < len(row) else None


class QuestieDB:
    ITEM = {'name': 1, 'npcDrops': 2, 'objectDrops': 3, 'questRewards': 6, 'flags': 7, 'requiredLevel': 10,
            'class': 12, 'subClass': 13, 'vendors': 14}
    NPC = {'name': 1, 'minLevel': 4, 'maxLevel': 5, 'rank': 6, 'spawns': 7, 'zoneID': 9, 'factionID': 12,
           'friendlyToFaction': 13, 'subName': 14, 'npcFlags': 15}
    QUEST = {'name': 1, 'startedBy': 2, 'requiredLevel': 4, 'questLevel': 5, 'requiredRaces': 6,
             'requiredSkill': 18, 'requiredMinRep': 19, 'specialFlags': 24}

    def __init__(self, checkout):
        root = Path(checkout)
        data = root / 'data' / 'Forever'
        self.items = _questie_block(data / 'foreverItemDB.lua', 'itemData')
        self.npcs = _questie_block(data / 'foreverNpcDB.lua', 'npcData')
        self.quests = _questie_block(data / 'foreverQuestDB.lua', 'questData')
        self.zones = import_trainers.zone_maps(
            (root / 'support' / 'Forever' / 'Zones' / 'areaIdToUiMapId.lua').read_bytes().decode('utf-8'))

    def item(self, item, field):
        row = self.items.get(item)
        return _at(row, self.ITEM[field]) if row else None

    def npc(self, npc, field):
        row = self.npcs.get(npc)
        return _at(row, self.NPC[field]) if row else None

    def quest(self, quest, field):
        row = self.quests.get(quest)
        return _at(row, self.QUEST[field]) if row else None

    def npc_side(self, npc):
        friendly = self.npc(npc, 'friendlyToFaction')
        return friendly if friendly in ('A', 'H', 'AH') else None

    def npc_place(self, npc):
        """(UiMapID, zone name, x, y) of an NPC's first spawn, or None."""
        spawns = self.npc(npc, 'spawns')
        if not isinstance(spawns, dict):
            return None
        for area in sorted(spawns, key=lambda a: (a != self.npc(npc, 'zoneID'), a)):
            coords = spawns[area]
            if area in self.zones and coords and isinstance(coords[0], list) and len(coords[0]) >= 2:
                ui, name = self.zones[area]
                return ui, name, round(float(coords[0][0]), 1), round(float(coords[0][1]), 1)
        return None

    RACES_ALLIANCE = 1 | 4 | 8 | 64 | 1024   # Human, Dwarf, Night Elf, Gnome, Draenei-era bits (Forever: classic four)
    RACES_HORDE = 2 | 16 | 32 | 128 | 512

    def quest_side(self, quest):
        races = self.quest(quest, 'requiredRaces') or 0
        if not races:
            return 'AH'
        a, h = races & self.RACES_ALLIANCE, races & self.RACES_HORDE
        return 'AH' if (a and h) or (not a and not h) else ('A' if a else 'H')


# --- CMaNGOS classic-db trainers -------------------------------------------------------------------------------

def trainers(sql_gz_path):
    """{trainer NPC: [npc_trainer rows: spell, spellcost, reqskill, reqskillvalue, reqlevel]}"""
    return import_trainers.classicdb(Path(sql_gz_path).read_bytes())
