"""Readers for the inputs of CraftPilot's own recipe catalog.

  ClientTables  the WoW Forever client's DB2 tables (catalog-inputs branch, see fetch_inputs.py)
  LuaReader     a reader for Lua table constructors (QuestieDB's data files, generated catalogs)
  QuestieDB     items, NPCs, quests and zones from the QuestieDB addon's Forever data (GPL-3.0)
  trainers()    which trainer teaches which spell, at which skill and for how much: CMaNGOS classic-db (GPL-3.0)

Only facts are read here; nothing of these files is copied into the addon as is.
"""
import base64
import csv
import gzip
import io
import json
import re
import struct
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

def cbor(data, i=0):
    """Decode one CBOR item (RFC 8949) at data[i]; returns (value, next index)."""
    head = data[i]
    major, info = head >> 5, head & 31
    i += 1
    if major == 7:
        if info == 20:
            return False, i
        if info == 21:
            return True, i
        if info in (22, 23):
            return None, i
        if info == 25:
            return struct.unpack('>e', data[i:i + 2])[0], i + 2
        if info == 26:
            return struct.unpack('>f', data[i:i + 4])[0], i + 4
        if info == 27:
            return struct.unpack('>d', data[i:i + 8])[0], i + 8
        raise ValueError('CBOR simple value %d' % info)
    if info < 24:
        arg = info
    elif info in (24, 25, 26, 27):
        size = 1 << (info - 24)
        arg = int.from_bytes(data[i:i + size], 'big')
        i += size
    else:
        raise ValueError('CBOR indefinite length not supported')
    if major == 0:
        return arg, i
    if major == 1:
        return -1 - arg, i
    if major == 2:
        return bytes(data[i:i + arg]), i + arg
    if major == 3:
        return data[i:i + arg].decode('utf-8'), i + arg
    if major == 4:
        out = []
        for _ in range(arg):
            value, i = cbor(data, i)
            out.append(value)
        return out, i
    if major == 5:
        out = {}
        for _ in range(arg):
            key, i = cbor(data, i)
            out[key], i = cbor(data, i)
        return out, i
    return cbor(data, i)  # major 6: a tag; the tagged value is what counts


def _text(value):
    """QuestieDB stores strings as CBOR byte strings: decode them, everywhere in a value."""
    if isinstance(value, bytes):
        return value.decode('utf-8', 'replace')
    if isinstance(value, list):
        return [_text(v) for v in value]
    if isinstance(value, dict):
        return {_text(k): _text(v) for k, v in value.items()}
    return value


ENTITY_LINE = re.compile(r'^## X-(Item|Npc|Quest|Object)-(\d+)-([\w-]+): (.*)$')


class QuestieDB:
    """The baked QuestieDB_Forever.toc of a QuestieDB release: every correction folded in, as players have it.

    Entities live in metadata lines `## X-<Entity>-<id>-<field>: <base64 CBOR>`; field S holds the small values
    as one map (or list). A long value is split: "~N~", then parts <field>-1 .. <field>-N.
    Field numbers are QuestieDB's schema (itemKeys, npcKeys, questKeys)."""
    ITEM = {'name': 1, 'npcDrops': 2, 'objectDrops': 3, 'questRewards': 6, 'flags': 7, 'requiredLevel': 10,
            'class': 12, 'subClass': 13, 'vendors': 14}
    NPC = {'name': 1, 'minLevel': 4, 'maxLevel': 5, 'rank': 6, 'spawns': 7, 'zoneID': 9, 'factionID': 12,
           'friendlyToFaction': 13, 'subName': 14, 'npcFlags': 15}
    QUEST = {'name': 1, 'startedBy': 2, 'requiredLevel': 4, 'questLevel': 5, 'requiredRaces': 6,
             'requiredSkill': 18, 'requiredMinRep': 19, 'specialFlags': 24}

    def __init__(self, toc_text, zones_text):
        self.raw = {}
        for line in toc_text.splitlines():
            m = ENTITY_LINE.match(line)
            if m:
                kind, eid, field, value = m.groups()
                self.raw.setdefault((kind, int(eid)), {})[field] = value.strip()
        self.zones = import_trainers.zone_maps(zones_text)
        self._cache = {}

    def ids(self, kind):
        return sorted(eid for k, eid in self.raw if k == kind)

    def entity(self, kind, eid):
        key = (kind, eid)
        if key not in self._cache:
            fields, out = self.raw.get(key, {}), {}
            for field, value in fields.items():
                if '-' in field:
                    continue
                m = re.fullmatch(r'~(\d+)~', value)
                if m:
                    value = ''.join(fields[f'{field}-{n}'] for n in range(1, int(m.group(1)) + 1))
                decoded = _text(cbor(base64.b64decode(value))[0])
                if field == 'S':
                    if isinstance(decoded, list):
                        out.update({n: v for n, v in enumerate(decoded, 1) if v is not None})
                    else:
                        out.update({k: v for k, v in decoded.items() if isinstance(k, int)})
                else:
                    out[int(field)] = decoded
            self._cache[key] = out
        return self._cache[key]

    def item(self, item, field):
        return self.entity('Item', item).get(self.ITEM[field])

    def npc(self, npc, field):
        return self.entity('Npc', npc).get(self.NPC[field])

    def quest(self, quest, field):
        return self.entity('Quest', quest).get(self.QUEST[field])

    def has(self, kind, eid):
        return (kind, eid) in self.raw

    def npc_side(self, npc):
        friendly = self.npc(npc, 'friendlyToFaction')
        return friendly if friendly in ('A', 'H', 'AH') else None

    def npc_place(self, npc):
        """(UiMapID, zone name, x, y) of an NPC's first spawn in a known zone, or None."""
        spawns = self.npc(npc, 'spawns')
        if not isinstance(spawns, dict):
            return None
        home = self.npc(npc, 'zoneID')
        for area in sorted(spawns, key=lambda a: (a != home, a)):
            coords = spawns[area]
            if area in self.zones and coords and isinstance(coords[0], (list, tuple)) and len(coords[0]) >= 2:
                ui, name = self.zones[area]
                return ui, name, round(float(coords[0][0]), 1), round(float(coords[0][1]), 1)
        return None

    ALLIANCE = 1 | 4 | 8 | 64     # Human, Dwarf, Night Elf, Gnome
    HORDE = 2 | 16 | 32 | 128     # Orc, Undead, Tauren, Troll

    def quest_side(self, quest):
        races = self.quest(quest, 'requiredRaces') or 0
        a, h = races & self.ALLIANCE, races & self.HORDE
        if not races or (a and h) or (not a and not h):
            return 'AH'
        return 'A' if a else 'H'


def load_questiedb(inputs):
    folder = Path(inputs)
    return QuestieDB(gzip.decompress((folder / 'questiedb-Forever.toc.gz').read_bytes()).decode('utf-8'),
                     gzip.decompress((folder / 'questiedb-areaIdToUiMapId.lua.gz').read_bytes()).decode('utf-8'))


# --- CMaNGOS classic-db trainers -------------------------------------------------------------------------------

def trainers(sql_gz_path):
    """{trainer NPC: [npc_trainer rows: spell, spellcost, reqskill, reqskillvalue, reqlevel]}"""
    return import_trainers.classicdb(Path(sql_gz_path).read_bytes())


def classic_quests(sql_gz_path):
    """CMaNGOS classic-db quest_template rows: {quest: {Title, MinLevel, QuestLevel, RequiredRaces, RewSpell, RewSpellCast}}"""
    text = gzip.decompress(Path(sql_gz_path).read_bytes()).decode('utf-8', 'replace')
    m = re.search(r'CREATE TABLE `quest_template` \((.*?)\n\)', text, re.S)
    columns = [line.split()[0].strip('`') for line in m.group(1).splitlines() if line.strip().startswith('`')]
    wanted = ('entry', 'Title', 'MinLevel', 'QuestLevel', 'RequiredRaces', 'RewSpell', 'RewSpellCast')
    out = {}
    for line in text.splitlines():
        if line.startswith('INSERT INTO `quest_template`'):
            for values in import_trainers.sql_rows(line[line.index('VALUES') + 6:]):
                row = dict(zip(columns, values))
                out[int(row['entry'])] = {k: row.get(k) for k in wanted}
    return out
