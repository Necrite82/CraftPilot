"""AllTheThings' WoW Forever source database (MIT), read as data when the catalog is built.

AllTheThings writes its database as Lua source: calls such as n(npc, {...}), i(item, {...}), r(spell), q(quest, {...})
nested in tables, plus shared lists assigned to names (ALCHEMY_RECIPES = { APPRENTICE = {...}, ... }) that zone and
vendor files reference. This module parses that subset of Lua into a tree (it never runs it) and answers:

  favor()        {recipe item: (Merchant's Favor, standing, {vendor NPCs})}
  trainer_tiers(){profession: {tier: {recipe spell}}}   tier = APPRENTICE / JOURNEYMAN / EXPERT / ARTISAN
  sources()      {item: {'vendor': {npc}, 'drop': {npc}, 'quest': {quest}, 'object': {object}}}
  known_spells() {spell}  every r(spell) anywhere (recipes AllTheThings knows to exist in Forever)
  profession_db(){profession: {'trainer': {spell}, 'quest': {spell}, 'item': {spell: item},
                   'unknown': {spell: item}, 'unreleased': {spell: item}}}  from its "profession db" lists
  skill_levels() {spell: skill}  the skill each recipe is learned at, as AllTheThings exports it
  spell_quests() {spell: {quest}} quests that teach a recipe outright
"""
import gzip
import io
import re
import tarfile
from collections import defaultdict
from pathlib import Path

TOKEN = re.compile(r'''
    (?P<ws>\s+)
  | (?P<comment>--\[(?P<eq>=*)\[.*?\](?P=eq)\]|--[^\n]*)
  | (?P<str>"(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*'|\[\[.*?\]\])
  | (?P<num>0x[0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+)
  | (?P<name>[A-Za-z_][A-Za-z_0-9]*)
  | (?P<sym>\.\.\.|\.\.|==|~=|<=|>=|[-+*/%^#<>=(){}\[\];:,.])
''', re.S | re.X)

STANDINGS = {'HATED': 1, 'HOSTILE': 2, 'UNFRIENDLY': 3, 'NEUTRAL': 4, 'FRIENDLY': 5, 'HONORED': 6, 'REVERED': 7,
             'EXALTED': 8}
TIERS = ('APPRENTICE', 'JOURNEYMAN', 'EXPERT', 'ARTISAN')
FAVOR_CURRENCY = 3402  # Merchant's Favor


class Call:
    __slots__ = ('func', 'args')

    def __init__(self, func, args):
        self.func, self.args = func, args

    def __repr__(self):
        return f'{self.func}({self.args!r})'


class Name:
    __slots__ = ('path',)

    def __init__(self, path):
        self.path = path

    def __repr__(self):
        return self.path


class Table:
    __slots__ = ('items', 'fields')

    def __init__(self):
        self.items, self.fields = [], {}

    def __repr__(self):
        return f'T({self.items!r}, {self.fields!r})'


class ParseError(Exception):
    pass


class Parser:
    def __init__(self, text):
        self.toks = []
        for m in TOKEN.finditer(text):
            kind = m.lastgroup
            if kind in ('ws', 'comment', 'eq'):
                continue
            self.toks.append((kind, m.group(kind), m.start()))
        self.toks.append((None, None, len(text)))
        self.i = 0

    def peek(self, k=0):
        return self.toks[min(self.i + k, len(self.toks) - 1)]

    def take(self, want=None):
        tok = self.toks[self.i]
        if want is not None and tok[1] != want:
            raise ParseError(f'expected {want!r}, got {tok[1]!r}')
        self.i += 1
        return tok

    # expressions: enough for data files (no function bodies)
    def expr(self):
        left = self.unary()
        while self.peek()[1] in ('+', '-', '*', '/', '..', 'or', 'and', '==', '~=', '<', '>', '<=', '>='):
            self.take()
            self.unary()
        return left

    def unary(self):
        kind, text, _ = self.peek()
        if text in ('-', 'not', '#'):
            self.take()
            value = self.unary()
            return -value if text == '-' and isinstance(value, (int, float)) else value
        return self.primary()

    def primary(self):
        kind, text, _ = self.take()
        if kind == 'num':
            value = int(text, 16) if text.lower().startswith('0x') else (float(text) if '.' in text or 'e' in text.lower() else int(text))
        elif kind == 'str':
            value = text[2:-2] if text.startswith('[[') else text[1:-1]
        elif text == '{':
            value = self.table()
        elif text == '(':
            value = self.expr()
            self.take(')')
        elif text == 'function':
            raise ParseError('function body')
        elif kind == 'name':
            if text in ('nil', 'true', 'false'):
                return {'nil': None, 'true': True, 'false': False}[text]
            path = text
            while self.peek()[1] in ('.', ':') and self.peek(1)[0] == 'name':
                self.take()
                path += '.' + self.take()[1]
            while self.peek()[1] == '[':
                self.take()
                self.expr()
                self.take(']')
            value = Name(path)
            while self.peek()[1] in ('(', '{') or self.peek()[0] == 'str':
                if self.peek()[1] == '(':
                    self.take()
                    args = []
                    while self.peek()[1] != ')':
                        args.append(self.expr())
                        if self.peek()[1] == ',':
                            self.take()
                    self.take(')')
                elif self.peek()[1] == '{':
                    self.take()
                    args = [self.table()]
                else:
                    args = [self.take()[1][1:-1]]
                value = Call(path, args)
        else:
            raise ParseError(f'unexpected {text!r}')
        return value

    def table(self):
        t = Table()
        while self.peek()[1] != '}':
            kind, text, _ = self.peek()
            if text == '[':
                self.take()
                key = self.expr()
                self.take(']')
                self.take('=')
                t.fields[key] = self.expr()
            elif kind == 'name' and self.peek(1)[1] == '=' and self.peek(2)[1] != '=':
                self.take()
                self.take('=')
                t.fields[text] = self.expr()
            else:
                t.items.append(self.expr())
            if self.peek()[1] in (',', ';'):
                self.take()
        self.take('}')
        return t

    def statements(self):
        """Top-level `[local] NAME = expr` and call statements; anything else is skipped."""
        out = []
        while self.peek()[0] is not None:
            start = self.i
            try:
                if self.peek()[1] == 'local':
                    self.take()
                kind, text, _ = self.peek()
                if kind == 'name' and text not in ('if', 'for', 'while', 'return', 'end', 'do', 'function'):
                    target = self.primary()
                    if self.peek()[1] == '=':
                        self.take()
                        out.append(('assign', target.path if isinstance(target, Name) else None, self.expr()))
                    elif isinstance(target, Call):
                        out.append(('call', None, target))
                    else:
                        self.take()
                else:
                    self.take()
                if self.peek()[1] == ';':
                    self.take()
            except (ParseError, IndexError):
                self.i = start + 1
                # skip to the next statement that starts a line at column 0
                while self.peek()[0] is not None:
                    pos = self.peek()[2]
                    if self.peek()[0] == 'name' and (pos == 0 or self.text_at(pos - 1) == '\n'):
                        break
                    self.i += 1
        return out

    def text_at(self, pos):
        return self._text[pos] if 0 <= pos < len(self._text) else '\n'


def parse(text):
    p = Parser(text)
    p._text = text
    return p.statements()


class AllTheThings:
    def __init__(self, files):
        """files: {relative path: text}"""
        self.files = files
        self.names = {}   # assigned name -> value (tables, and NAME.FIELD for fields of assigned tables)
        self.roots = []   # (path, call) top-level calls (root(...), profession(...))
        for path in sorted(files):
            for kind, target, value in parse(files[path]):
                if kind == 'assign' and target:
                    self.names[target] = value
                    if isinstance(value, Table):
                        for key, field in value.fields.items():
                            if isinstance(key, str):
                                self.names[f'{target}.{key}'] = field
                elif kind == 'call':
                    self.roots.append((path, value))

    @classmethod
    def from_tar(cls, path):
        files = {}
        with tarfile.open(fileobj=io.BytesIO(gzip.decompress(Path(path).read_bytes()))) as tar:
            for member in tar.getmembers():
                if member.isfile() and member.name.endswith('.lua'):
                    files[member.name] = tar.extractfile(member).read().decode('utf-8', 'replace')
        return cls(files)

    def resolve(self, value, seen=()):
        while isinstance(value, Name) and value.path in self.names and value.path not in seen:
            seen = seen + (value.path,)
            value = self.names[value.path]
        return value

    def children(self, value):
        """The things a value holds: a table's entries (and its groups/g field), a call's table arguments."""
        value = self.resolve(value)
        if isinstance(value, Table):
            out = list(value.items)
            for key in ('groups', 'g'):
                if key in value.fields:
                    out.append(value.fields[key])
            return out
        if isinstance(value, Call):
            return [a for a in value.args if isinstance(a, (Table, Name, Call))]
        return []

    @staticmethod
    def call_id(call):
        first = call.args[0] if call.args else None
        return first if isinstance(first, int) else None

    @staticmethod
    def fields(call):
        for a in call.args:
            if isinstance(a, Table):
                return a.fields
        return {}

    def walk(self, value, context, visit, depth=0, seen=None):
        """Depth-first over calls; context is a tuple of (func, id or name) for the enclosing calls."""
        if depth > 60:
            return
        seen = seen if seen is not None else set()
        if isinstance(value, Name):
            if value.path in seen:
                return
            seen = seen | {value.path}
        value = self.resolve(value)
        if isinstance(value, Call):
            ident = self.call_id(value)
            if ident is None and value.args and isinstance(value.args[0], Name):
                ident = value.args[0].path
            visit(value, context)
            context = context + ((value.func, ident),)
        for child in self.children(value):
            self.walk(child, context, visit, depth + 1, seen)

    def walk_roots(self, visit):
        for path, call in self.roots:
            self.walk(call, (('file', path),), visit)

    # --- answers -----------------------------------------------------------------------------------------------

    def favor(self):
        """{item: (favor, standing, {vendor npc})} from the bubbleDownClassicRep lists vendors reference."""
        lists = {}
        for name, value in self.names.items():
            if isinstance(value, Call) and value.func == 'bubbleDownClassicRep':
                table = next((a for a in value.args if isinstance(a, Table)), None)
                if not table:
                    continue
                entries = {}
                for level, group in enumerate(table.items, start=STANDINGS['NEUTRAL']):
                    def visit(call, ctx, level=level):
                        if call.func == 'i' and self.call_id(call):
                            cost = self.fields(call).get('cost')
                            favor = self._favor_cost(cost)
                            if favor:
                                entries[self.call_id(call)] = (favor, level)
                    self.walk(group, (), visit)
                lists[name] = entries
        out = {}

        def visit(call, ctx):
            if call.func == 'n' and self.call_id(call):
                groups = self.fields(call).get('groups')
                if isinstance(groups, Name) and groups.path in lists:
                    for item, (favor, level) in lists[groups.path].items():
                        entry = out.setdefault(item, [favor, level, set()])
                        entry[2].add(self.call_id(call))
        self.walk_roots(visit)

        # items a vendor sells for Merchant's Favor directly (cost and minReputation on the item itself)
        def direct(call, ctx):
            if call.func != 'i' or not self.call_id(call):
                return
            fields = self.fields(call)
            favor = self._favor_cost(fields.get('cost'))
            npc = next((ident for func, ident in reversed(ctx) if func == 'n' and isinstance(ident, int)), None)
            if not favor or not npc:
                return
            level = STANDINGS['NEUTRAL']
            rep = self.resolve(fields.get('minReputation'))
            if isinstance(rep, Table) and len(rep.items) >= 2 and isinstance(rep.items[1], Name):
                level = STANDINGS.get(rep.items[1].path, level)
            entry = out.setdefault(self.call_id(call), [favor, level, set()])
            entry[2].add(npc)
        self.walk_roots(direct)
        return {item: (v[0], v[1], v[2]) for item, v in out.items()}

    def _favor_cost(self, cost):
        cost = self.resolve(cost)
        if not isinstance(cost, Table):
            return None
        for entry in cost.items:
            entry = self.resolve(entry)
            if isinstance(entry, Table) and len(entry.items) >= 3 and entry.items[0] == 'c':
                currency = entry.items[1]
                currency = FAVOR_CURRENCY if isinstance(currency, Name) and currency.path == 'MERCHANTS_FAVOR' else currency
                if currency == FAVOR_CURRENCY and isinstance(entry.items[2], int):
                    return entry.items[2]
        return None

    def trainer_tiers(self):
        """{profession list name (ALCHEMY_RECIPES ...): {tier: {spell}}}"""
        out = defaultdict(dict)
        for name, value in self.names.items():
            m = re.fullmatch(r'([A-Z_]+_RECIPES)\.(' + '|'.join(TIERS) + ')', name)
            if not m:
                continue
            spells = set()

            def visit(call, ctx):
                if call.func == 'r' and self.call_id(call):
                    spells.add(self.call_id(call))
            self.walk(value, (), visit)
            out[m.group(1)][m.group(2)] = spells
        return dict(out)

    def known_spells(self):
        spells = set()

        def visit(call, ctx):
            if call.func == 'r' and self.call_id(call):
                spells.add(self.call_id(call))
        self.walk_roots(visit)
        for name, value in self.names.items():
            if '.' not in name:
                self.walk(value, (), visit)
        return spells

    def sources(self):
        """{item: {'vendor': {npc}, 'drop': {npc}, 'quest': {quest}, 'object': {object}}} from the world tree."""
        out = defaultdict(lambda: defaultdict(set))

        def visit(call, ctx):
            if call.func != 'i' or not self.call_id(call):
                return
            item = self.call_id(call)
            headers = [ident for func, ident in ctx if func == 'n' and isinstance(ident, str)]
            for func, ident in reversed(ctx):
                if func == 'q' and isinstance(ident, int):
                    out[item]['quest'].add(ident)
                    return
                if func == 'o' and isinstance(ident, int):
                    out[item]['object'].add(ident)
                    return
                if func == 'n' and isinstance(ident, int):
                    kind = 'vendor' if 'VENDORS' in headers else 'drop'
                    out[item][kind].add(ident)
                    return
        self.walk_roots(visit)
        return {item: dict(kinds) for item, kinds in out.items()}


PROFESSION_DB = 'profession db/'
DB_LINE = re.compile(r'^\s*i\(\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*[^,)]*?\s*(?:,\s*([A-Z_]+))?)?\s*\)')
# specializations: the spell that grants them (game facts), by AllTheThings' names and section titles
SPECS = {'ARMORSMITH': 9788, 'WEAPONSMITH': 9787, 'AXESMITH': 17041, 'HAMMERSMITH': 17040, 'SWORDSMITH': 17039,
         'GNOMISH_ENGINEERING': 20219, 'GOBLIN_ENGINEERING': 20222, 'DRAGONSCALE_LEATHERWORKING': 10656,
         'ELEMENTAL_LEATHERWORKING': 10658, 'TRIBAL_LEATHERWORKING': 10660, 'GNOMISH': 20219, 'GOBLIN': 20222,
         'DRAGONSCALE': 10656, 'ELEMENTAL': 10658, 'TRIBAL': 10660}


def _profession_db_text(text):
    """Sections of a "profession db" file. Lines inside --[[ ... ]] blocks count as unknown or unreleased."""
    out = {'trainer': set(), 'quest': set(), 'item': {}, 'unknown': {}, 'unreleased': {}, 'spec': {}}
    section, commented, spec = 'item', False, None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith('--[['):
            commented, section = True, 'unknown'
            continue
        if stripped.startswith('--]]') or stripped.startswith(']]'):
            commented, section = False, 'spec' if spec else 'item'
            continue
        marker = re.match(r'^---? ?([A-Z_ ]+?) ?---$', stripped)
        if marker:
            name = marker.group(1).strip().replace(' ', '_')
            if name in SPECS:
                spec, section = SPECS[name], 'spec'
                continue
            section = {'TRAINER': 'trainer', 'QUEST': 'quest', 'ITEM': 'item', 'UNKNOWN': 'unknown',
                       'UNRELEASED_CONTENT': 'unreleased', 'UNSURE': 'unknown'}.get(name, section)
            if section in ('trainer', 'quest', 'item'):
                spec = None
            continue
        m = DB_LINE.match(stripped)
        bare = re.match(r'^\s*r\(\s*(\d+)\s*\)', stripped)
        if not m and bare:   # r(spell): a recipe without an item
            spell = int(bare.group(1))
            if commented or section in ('unknown', 'unreleased'):
                out['unreleased' if section == 'unreleased' else 'unknown'][spell] = 0
            elif section == 'quest':
                out['quest'].add(spell)
            else:
                out['trainer'].add(spell)
            continue
        if not m:
            continue
        item, spell = int(m.group(1)), int(m.group(2))
        line_spec = SPECS.get(m.group(3) or '') or (spec if section == 'spec' else None)
        if line_spec:
            out['spec'][spell] = line_spec
        if commented and section not in ('unknown', 'unreleased'):
            section = 'unknown'
        if section == 'spec' and not commented:
            if item:
                out['item'][spell] = item
            else:
                out['trainer'].add(spell)
        elif section in ('trainer', 'quest') and not commented:
            out[section].add(spell)
            if item:
                out['item'][spell] = item
        elif section == 'item' and not commented:
            if item:
                out['item'][spell] = item
            else:             # i(0, spell) among the items: taught by (specialization) trainers
                out['trainer'].add(spell)
        else:
            out['unreleased' if section == 'unreleased' else 'unknown'][spell] = item
    return out


def _profession_db(self):
    out = {}
    for path, text in self.files.items():
        if path.startswith(PROFESSION_DB) and path.endswith('.lua'):
            out[path[len(PROFESSION_DB):-4]] = _profession_db_text(text)
    return out


def _skill_levels(self):
    text = self.files.get('.config/exports/Skill Level Requirements.lua', '')
    return {int(k): int(v) for k, v in re.findall(r'^\s*\[(\d+)\]\s*=\s*(\d+)', text, re.M)}


def _spell_quests(self):
    out = defaultdict(set)

    def visit(call, ctx):
        if call.func == 'r' and self.call_id(call):
            for func, ident in reversed(ctx):
                if func == 'q' and isinstance(ident, int):
                    out[self.call_id(call)].add(ident)
                    break
    self.walk_roots(visit)
    return dict(out)


AllTheThings.profession_db = _profession_db
AllTheThings.skill_levels = _skill_levels
AllTheThings.spell_quests = _spell_quests
