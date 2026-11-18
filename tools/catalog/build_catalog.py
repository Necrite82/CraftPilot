"""Build CraftPilot's own recipe catalog for WoW Forever.

    python3 tools/catalog/build_catalog.py --inputs DIR --classicdb FILE.sql.gz [--out Data/Catalog] [--only alchemy]

Inputs (all pinned by SHA-256 in the written SOURCES.json):
  - the Forever client's own tables (DB2 via wago.tools; the `catalog-inputs` branch, see fetch_inputs.py):
    which spells are recipes, their skill colours, materials, product and count, tools, cooldowns, the recipe items
    that teach them (with skill, reputation and specialization they ask for), vendor prices, names
  - CMaNGOS classic-db (GPL-3.0): which trainer teaches which recipe, at which skill and for how much
  - QuestieDB's Forever release package (GPL-3.0): who sells, drops or rewards a recipe item; NPC names and places
  - AllTheThings' Forever database (MIT): Merchant's Favor prices and standings, the recipes Forever's trainers teach

Output: one Lua file per profession that sets CP.CatalogData[key]; the field meanings are documented in the header
of every generated file. Nothing in it is copied text from any of the sources: only ids, numbers and names.
"""
import argparse
import hashlib
import json
import statistics
import sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import allthethings  # noqa: E402
import sources  # noqa: E402
from sources import num  # noqa: E402

# key: (skill line, catalog name, AllTheThings "profession db" file)
PROFESSIONS = {
    'alchemy': (171, 'Alchemy', 'alchemy'),
    'blacksmithing': (164, 'Blacksmithing', 'blacksmithing'),
    'enchanting': (333, 'Enchanting', 'enchanting'),
    'engineering': (202, 'Engineering', 'engineering'),
    'leatherworking': (165, 'Leatherworking', 'leatherworking'),
    'tailoring': (197, 'Tailoring', 'tailoring'),
    'mining': (186, 'Mining', 'mining'),
}
RANK_CAPS = (75, 150, 225, 300)
RANK_NAMES = ('Apprentice', 'Journeyman', 'Expert', 'Artisan')

CREATE_ITEM, ENCHANT_ITEM, LEARN_SPELL = 24, 53, 36
TEACHES = 6                      # ItemEffect.TriggerType: on use, learn ItemEffect.SpellID
ACQUIRE_ON_LEARN = 1             # SkillLineAbility.AcquireMethod: known as soon as the profession is learned
GUESS_BELOW_YELLOW = 15          # a recipe nothing is known to teach: assumed learnable this far below yellow
COOLDOWN_MIN = 3600              # seconds; shorter cooldowns don't matter for planning
TRAINERS_LISTED = 3              # a recipe only this many trainers teach names them
CLASS_RECIPE = 9                 # Item.ClassID of recipe items


def lua(value, indent=''):
    if value is None:
        return 'nil'
    if value is True:
        return 'true'
    if value is False:
        return 'false'
    if isinstance(value, (int, float)):
        return repr(int(value)) if float(value) == int(value) else repr(round(value, 4))
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    if isinstance(value, (list, tuple)):
        return '{ ' + ', '.join(lua(v) for v in value) + ' }' if value else '{}'
    if isinstance(value, dict):
        if not value:
            return '{}'
        parts = []
        for k, v in value.items():
            key = k if isinstance(k, str) and k.isidentifier() else '[%s]' % lua(k)
            parts.append('%s = %s' % (key, lua(v)))
        return '{ ' + ', '.join(parts) + ' }'
    raise TypeError(type(value))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class Context:
    """Everything the profession builds share, read once."""

    def __init__(self, inputs, classicdb):
        self.inputs = Path(inputs)
        self.client = sources.ClientTables(inputs)
        self.questie = sources.load_questiedb(inputs)
        self.att = allthethings.AllTheThings.from_tar(self.inputs / 'att-forever.tar.gz')
        self.classicdb_path = Path(classicdb)
        c = self.client
        self.spell_names = {int(r['ID']): r['Name_lang'] for r in c.rows('SpellName')}
        self.effects = c.grouped('SpellEffect', 'SpellID')
        self.reagents = {int(r['SpellID']): r for r in c.rows('SpellReagents')}
        self.totems = {int(r['SpellID']): r for r in c.rows('SpellTotems')}
        self.cooldowns = {}
        for r in c.rows('SpellCooldowns'):
            ms = max(num(r['RecoveryTime']), num(r['CategoryRecoveryTime']))
            if ms:
                self.cooldowns[int(r['SpellID'])] = ms // 1000
        self.levels = {int(r['SpellID']): num(r['BaseLevel']) or num(r['SpellLevel'])
                       for r in c.rows('SpellLevels') if num(r['DifficultyID']) == 0}
        self.items = c.by_id('ItemSparse')
        self.item_class = {int(r['ID']): (num(r['ClassID']), num(r['SubclassID'])) for r in c.rows('Item')}
        self.totem_kinds = {int(r['ID']): r['Name_lang'] for r in c.rows('TotemCategory')}
        self.factions = {int(r['ID']): r['Name_lang'] for r in c.rows('Faction')}
        # recipe item -> spell it teaches, and back
        effect_rows = c.by_id('ItemEffect')
        self.teaches = defaultdict(set)
        for r in c.rows('ItemXItemEffect'):
            e = effect_rows.get(int(r['ItemEffectID']))
            if e and num(e['TriggerType']) == TEACHES and num(e['SpellID']):
                self.teaches[num(e['SpellID'])].add(int(r['ItemID']))
        # Classic Era: teaching spell -> the recipe it teaches, and old colours
        self.era_teach = {}
        for r in c.rows('era-SpellEffect'):
            if num(r['Effect']) == LEARN_SPELL and num(r['EffectTriggerSpell']):
                self.era_teach[int(r['SpellID'])] = num(r['EffectTriggerSpell'])
        self.era_colors = {int(r['Spell']): (num(r['TrivialSkillLineRankLow']), num(r['TrivialSkillLineRankHigh']))
                           for r in c.rows('era-SkillLineAbility')}
        self.trainer_rows = sources.trainers(classicdb)
        self.trainer_lessons = defaultdict(list)   # recipe spell -> [(trainer npc, row)]
        for npc, rows in self.trainer_rows.items():
            for row in rows:
                recipe = self.era_teach.get(num(row['spell']))
                if recipe:
                    self.trainer_lessons[recipe].append((npc, row))
        self.favor = self.att.favor()
        self.profession_db = self.att.profession_db()
        self.skill_levels = self.att.skill_levels()
        self.spell_quests = {k: set(v) for k, v in self.att.spell_quests().items()}
        # CMaNGOS quests that teach a recipe (reward spell, or a cast teaching spell), kept when Forever has the quest
        for quest, row in sources.classic_quests(classicdb).items():
            for column in ('RewSpell', 'RewSpellCast'):
                spell = num(row[column])
                spell = self.era_teach.get(spell, spell)
                if spell and self.questie.has('Quest', quest):
                    self.spell_quests.setdefault(spell, set()).add(quest)
        self.att_sources = self.att.sources()
        # where reagents are sold: QuestieDB vendors
        self.npc_used = set()

    def item_name(self, item):
        row = self.items.get(item)
        return row['Display_lang'] if row else None

    def npc_entry(self, npc):
        q = self.questie
        if not q.has('Npc', npc):
            return None
        entry = {'name': q.npc(npc, 'name'), 'faction': q.npc_side(npc) or 'AH'}
        place = q.npc_place(npc)
        if place:
            entry['map'], entry['zone'], entry['x'], entry['y'] = place
        return entry


def craft_effect(ctx, spell):
    """(product item or None, count) for a recipe spell, or None when the spell crafts nothing."""
    for e in sorted(ctx.effects.get(spell, []), key=lambda r: num(r['EffectIndex'])):
        effect = num(e['Effect'])
        if effect == CREATE_ITEM and num(e['EffectItemType']):
            return num(e['EffectItemType']), max(1, int(num(e['EffectBasePointsF'], 1)))
        if effect == ENCHANT_ITEM:
            return None, 1
    return None


def build_profession(ctx, key):
    skill_line, display, att_file = PROFESSIONS[key]
    c = ctx.client
    abilities = [r for r in c.rows('SkillLineAbility') if num(r['SkillLine']) == skill_line]
    att = ctx.profession_db.get(att_file, {'trainer': set(), 'quest': set(), 'item': {}, 'unknown': {},
                                           'unreleased': {}, 'spec': {}})
    att_known = att['trainer'] | att['quest'] | set(att['item']) | set(att['unknown']) | set(att['unreleased'])

    recipes, report = {}, defaultdict(list)
    trainer_costs = []  # (learn, cost) of trainer recipes with a known fee, to guess the others
    pending_guess = []
    vendor_items = set()
    for row in abilities:
        spell = num(row['Spell'])
        low, high = num(row['TrivialSkillLineRankLow']), num(row['TrivialSkillLineRankHigh'])
        name = ctx.spell_names.get(spell)
        made = craft_effect(ctx, spell)
        start = num(row['AcquireMethod']) == ACQUIRE_ON_LEARN
        if not name or made is None or high <= 0:
            report['skipped'].append((spell, name, 'no name' if not name else 'crafts nothing' if made is None else 'no colours'))
            continue
        unconfirmed = False
        if not start and spell not in att_known and spell not in ctx.skill_levels:
            # Still in the client (Season of Discovery, Classic leftovers) but not in AllTheThings' Forever lists:
            # kept, as unavailable, only when QuestieDB knows where its recipe item comes from.
            q = ctx.questie
            if not any(q.item(i, 'vendors') or q.item(i, 'npcDrops') or q.item(i, 'questRewards')
                       for i in ctx.teaches.get(spell, ())):
                report['notInForever'].append((spell, name, 'not listed by AllTheThings'))
                continue
            unconfirmed = True
        makes, count = made
        recipe = {'name': name}
        mats = {}
        r = ctx.reagents.get(spell)
        if r:
            for i in range(8):
                item, n = num(r.get(f'Reagent_{i}')), num(r.get(f'ReagentCount_{i}'))
                if item > 0 and n > 0:
                    mats[item] = mats.get(item, 0) + n
        recipe['mats'] = mats
        if makes:
            recipe['makes'] = makes
            if count > 1:
                recipe['yield'] = count
        tools = []
        t = ctx.totems.get(spell)
        if t:
            for i in (0, 1):
                kind = num(t.get(f'RequiredTotemCategoryID_{i}'))
                if kind:
                    tools.append(kind)
        if tools:
            recipe['tools'] = tools
        cd = ctx.cooldowns.get(spell, 0)
        if cd >= COOLDOWN_MIN:
            recipe['cooldown'] = cd
        if spell >= 1000000 or (spell not in ctx.era_colors and spell not in ctx.trainer_lessons):
            recipe['forever'] = True
        if spell in att['unknown'] and not unconfirmed:
            # AllTheThings isn't sure: available when anything is known to teach it in Forever
            q = ctx.questie
            known = any(q.item(i, 'vendors') or q.item(i, 'npcDrops') or q.item(i, 'questRewards')
                        or ctx.att_sources.get(i) for i in set(ctx.teaches.get(spell, ())) | {att['unknown'][spell]} if i)
            if not known and not ctx.spell_quests.get(spell):
                recipe['unavailable'] = True
        if spell in att['unreleased'] or unconfirmed:
            recipe['unavailable'] = True

        if spell in att['spec']:
            recipe['spec'] = att['spec'][spell]
        # AllTheThings' learn skill where it says more than the colours: below yellow. Equal to yellow it is
        # mostly a placeholder, except for recipes whose colours span a few points only (Mana Well: 20/20/20/20).
        listed = ctx.skill_levels.get(spell)
        fits = listed is not None and (not low or listed < low or (listed == low and high - low <= 5))
        get, learn = [], listed if fits else None
        lessons = ctx.trainer_lessons.get(spell, [])
        # 1) known when the profession is learned
        if start:
            get.append({'kind': 'start'})
            learn = 1
        # 2) Forever's trainers (AllTheThings); skill and fee from CMaNGOS where Classic taught it too
        elif spell in att['trainer'] or (spell in att['quest'] and not ctx.spell_quests.get(spell)):
            source = {'kind': 'trainer'}
            if lessons:
                skills = sorted(num(rw['reqskillvalue']) for _, rw in lessons)
                costs = sorted(num(rw['spellcost']) for _, rw in lessons)
                levels = sorted(num(rw['reqlevel']) for _, rw in lessons)
                source['cost'] = costs[0]
                if levels[0] > 0:
                    source['reqLevel'] = levels[0]
                learn = skills[0]   # CMaNGOS' trainer skill, moved as Forever moved the colours
                era = ctx.era_colors.get(spell)
                if era and era[0] and low and era[0] != low:
                    learn = max(1, learn + (low - era[0]))
                    source['classicSkill'] = learn
                trainer_costs.append((learn, costs[0]))
                npcs = sorted({npc for npc, _ in lessons if ctx.questie.has('Npc', npc)})
                if npcs and len(npcs) <= TRAINERS_LISTED:
                    recipe['trainers'] = npcs
            else:
                source['costGuess'] = True
                pending_guess.append(recipe)
            get.append(source)
        # 3) quests that teach it outright
        for quest in sorted(ctx.spell_quests.get(spell, ())):
            if ctx.questie.has('Quest', quest):
                get.append({'kind': 'quest', 'quest': quest, 'questName': ctx.questie.quest(quest, 'name'),
                            'faction': ctx.questie.quest_side(quest)})
        # 4) recipe items: vendors, drops, quests
        items = set(ctx.teaches.get(spell, ()))
        for listed in (att['item'].get(spell), att['unknown'].get(spell), att['unreleased'].get(spell)):
            if listed:
                items.add(listed)
        for item in sorted(items):
            sparse = ctx.items.get(item)
            if not sparse:
                continue
            recipe.setdefault('item', item)
            need = num(sparse['RequiredSkillRank'])
            if need:  # the client's own requirement on the recipe item
                learn = need if learn is None or not lessons else min(learn, need)
            faction, standing = num(sparse['MinFactionID']), num(sparse['MinReputation'])
            if faction and standing:
                recipe['rep'] = {'faction': faction, 'standing': standing}
            ability = num(sparse['RequiredAbility'])
            if ability:
                recipe['spec'] = ability
            if num(sparse['RequiredLevel']) > 1:
                recipe['reqLevel'] = num(sparse['RequiredLevel'])
            if not recipe.get('unavailable'):
                get.extend(item_sources(ctx, item, sparse, vendor_items))
        # 5) nothing known: trainers assumed below yellow, marked as a guess
        if not get and not recipe.get('unavailable'):
            recipe['guess'] = True
            pending_guess.append(recipe)
            get.append({'kind': 'trainer', 'costGuess': True})
            if learn is None:
                learn = max(1, (low or 1) - GUESS_BELOW_YELLOW)
        if learn is None:  # no skill known from any source: learnable this far below yellow
            learn = max(1, (low or 1) - GUESS_BELOW_YELLOW)
        recipe['learn'] = learn
        green = (low + high) // 2 if low else high
        recipe['colors'] = [learn, low or learn, green, high]
        recipe['get'] = get
        recipes[spell] = recipe

    # guessed trainer fees: the median fee of known trainer recipes within 25 skill points
    for recipe in pending_guess:
        near = [cost for at, cost in trainer_costs if abs(at - recipe['learn']) <= 25] or [cost for _, cost in trainer_costs]
        guess = int(statistics.median(near)) if near else 0
        for source in recipe['get']:
            if source.get('costGuess'):
                source['cost'] = guess

    # ranks: the rank spells of the profession and what CMaNGOS trainers ask for them
    ranks = rank_list(ctx, key, abilities)
    vendor_prices, sell, names = {}, {}, {}
    used_items = set()
    for recipe in recipes.values():
        used_items.update(recipe['mats'])
        if recipe.get('makes'):
            used_items.add(recipe['makes'])
        if recipe.get('item'):
            used_items.add(recipe['item'])
    for item in sorted(used_items):
        sparse = ctx.items.get(item)
        if not sparse:
            continue
        names[item] = sparse['Display_lang']
        if num(sparse['SellPrice']):
            sell[item] = num(sparse['SellPrice'])
    for recipe in recipes.values():
        for item in recipe['mats']:
            price = reagent_vendor_price(ctx, item)
            if price:
                vendor_prices[item] = price
    tool_kinds = {}
    for recipe in recipes.values():
        for kind in recipe.get('tools', []):
            tool_kinds[kind] = {'name': ctx.totem_kinds.get(kind, str(kind)),
                                'items': sorted(i for i, r in ctx.items.items() if num(r.get('TotemCategoryID')) == kind)}
    npcs = {}
    for recipe in recipes.values():
        for source in recipe['get']:
            if source.get('npc'):
                entry = ctx.npc_entry(source['npc'])
                if entry:
                    npcs[source['npc']] = entry
        for npc in recipe.get('trainers', []):
            entry = ctx.npc_entry(npc)
            if entry:
                npcs[npc] = entry
    quests = {}
    for recipe in recipes.values():
        for source in recipe['get']:
            if source.get('quest'):
                quests[source['quest']] = quest_entry(ctx, source['quest'])
    factions = {}
    for recipe in recipes.values():
        if recipe.get('rep'):
            faction = recipe['rep']['faction']
            factions[faction] = ctx.factions.get(faction, str(faction))
    data = {'built': c.manifest['fetched'][:10], 'build': c.build, 'ranks': ranks, 'toolKinds': tool_kinds,
            'recipes': recipes, 'npcs': npcs, 'quests': quests, 'vendorPrices': vendor_prices, 'sell': sell,
            'factions': factions, 'items': names}
    return data, report


def item_sources(ctx, item, sparse, vendor_items):
    q, out = ctx.questie, []
    buy = num(sparse['BuyPrice'])
    favor = ctx.favor.get(item)
    vendors = set(q.item(item, 'vendors') or []) | set(ctx.att_sources.get(item, {}).get('vendor', set()))
    if favor:
        vendors |= favor[2]
    for npc in sorted(vendors):
        if not q.has('Npc', npc):
            continue
        source = {'kind': 'vendor', 'npc': npc, 'npcName': q.npc(npc, 'name'), 'faction': q.npc_side(npc) or 'AH'}
        if favor and npc in favor[2]:
            source['favor'] = favor[0]
            if favor[1] > allthethings.STANDINGS['NEUTRAL']:
                source['favorStanding'] = favor[1]
        elif buy:
            source['cost'] = buy
        else:
            source['otherCost'] = True
        vendor_items.add(item)
        out.append(source)
    drops = set(q.item(item, 'npcDrops') or []) | set(ctx.att_sources.get(item, {}).get('drop', set()))
    drops = {npc for npc in drops if npc not in vendors}
    if drops:
        out.append({'kind': 'drop', 'npcs': len(drops), 'npcIDs': sorted(drops)})
    objects = set(q.item(item, 'objectDrops') or []) | set(ctx.att_sources.get(item, {}).get('object', set()))
    if objects:
        out.append({'kind': 'drop', 'objects': len(objects)})
    quests = set(q.item(item, 'questRewards') or []) | set(ctx.att_sources.get(item, {}).get('quest', set()))
    for quest in sorted(quests):
        if q.has('Quest', quest):
            out.append({'kind': 'quest', 'quest': quest, 'questName': q.quest(quest, 'name'),
                        'faction': q.quest_side(quest)})
    return out


def reagent_vendor_price(ctx, item):
    """{A=, H=} copper per unit when vendors on that side sell the reagent (QuestieDB vendors, client price)."""
    sparse = ctx.items.get(item)
    vendors = ctx.questie.item(item, 'vendors') or []
    if not sparse or not vendors or not num(sparse['BuyPrice']):
        return None
    per_unit = num(sparse['BuyPrice']) / max(1, num(sparse['VendorStackCount']) or 1)
    sides = set()
    for npc in vendors:
        side = ctx.questie.npc_side(npc)
        if side:
            sides.update(side)
    price = {s: int(round(per_unit)) for s in sorted(sides)}
    return price or None


def quest_entry(ctx, quest):
    q = ctx.questie
    entry = {'name': q.quest(quest, 'name') or 'quest %d' % quest, 'faction': q.quest_side(quest)}
    started = q.quest(quest, 'startedBy') or []
    if isinstance(started, dict):
        started = [started.get(1)]
    givers = started[0] if started and isinstance(started[0], list) else []
    if givers:
        npc = givers[0]
        entry['giver'] = npc
        entry['giverName'] = q.npc(npc, 'name')
        place = q.npc_place(npc)
        if place:
            entry['zone'], entry['x'], entry['y'] = place[1], place[2], place[3]
    if q.quest(quest, 'requiredLevel'):
        entry['reqLevel'] = q.quest(quest, 'requiredLevel')
    if q.quest(quest, 'questLevel'):
        entry['level'] = q.quest(quest, 'questLevel')
    req = q.quest(quest, 'requiredSkill')
    if isinstance(req, list) and len(req) >= 2:
        entry['skill'] = req[1]
    return entry


def rank_list(ctx, key, abilities):
    """The profession's rank spells in order (each supersedes the one before) with trainer fee and level."""
    skill_line = PROFESSIONS[key][0]
    name = PROFESSIONS[key][1]
    rank_spells = [num(r['Spell']) for r in abilities if ctx.spell_names.get(num(r['Spell'])) == name
                   and num(r['TrivialSkillLineRankHigh']) == 0]
    supersedes = {num(r['Spell']): num(r['SupercedesSpell']) for r in abilities}
    order = []
    current = next((s for s in rank_spells if not supersedes.get(s)), None)
    while current and current not in order:
        order.append(current)
        current = next((s for s in rank_spells if supersedes.get(s) == current), None)
    # CMaNGOS: the trainer lesson whose teaching spell teaches the rank spell
    lessons = {}
    for spell in order:
        rows = [rw for rw_list in ctx.trainer_rows.values() for rw in rw_list
                if ctx.era_teach.get(num(rw['spell'])) == spell]
        if rows:
            lessons[spell] = rows
    ranks = []
    for index, spell in enumerate(order[:4]):
        entry = {'name': RANK_NAMES[index], 'cap': RANK_CAPS[index], 'spell': spell, 'how': 'trainer'}
        rows = lessons.get(spell)
        if rows:
            entry['cost'] = min(num(r['spellcost']) for r in rows)
            level = min(num(r['reqlevel']) for r in rows)
            if level > 0:
                entry['charLevel'] = level
            entry['learnAt'] = min(num(r['reqskillvalue']) for r in rows)
        ranks.append(entry)
    return ranks


HEADER = '''-- CraftPilot recipe catalog: {display}. GENERATED by tools/catalog/build_catalog.py on {date} - do not edit by hand.
-- WoW Forever client build {build}. Inputs and their SHA-256: Data/Catalog/SOURCES.json.
-- Recipes, colours, materials, products, tools, cooldowns, recipe items and prices: the Forever client's own tables.
-- Trainer skill and fees: CMaNGOS classic-db (GPL-3.0). Vendors, drops, quests, NPC names and places: QuestieDB
-- (GPL-3.0). Merchant's Favor prices and Forever's trainer lists: AllTheThings (MIT).
-- colors = {{ orange, yellow, green, grey }} skill. learn = skill needed to learn. get = how to learn it:
--   start (known with the profession), trainer (cost; costGuess = fee estimated; classicSkill = skill moved from
--   Classic's as Forever moved the colours), vendor (npc, cost or favor + favorStanding = reputation
--   standing 5 Friendly .. 8 Exalted, otherCost = not for gold),
--   drop (npcs = how many NPCs drop it, npcIDs; objects = containers), quest (quest).
-- guess = nothing is known to teach it: assumed from trainers below yellow. forever = new in Forever.
-- makes/yield = product and count; mats = {{ [item] = count }}; tools = tool kinds; cooldown = seconds.
-- item = the recipe item; rep = {{ faction, standing }}; spec = specialization spell; trainers = the only trainers.
-- vendorPrices = reagents vendors sell (copper per unit, by side); sell = what a vendor pays. Costs in copper.
local _, CP = ...
CP.CatalogData = CP.CatalogData or {{}}
CP.CatalogData.{key} = '''


def write_lua(data, key, display, out_dir):
    lines = [HEADER.format(display=display, date=data['built'], build=data['build'], key=key).rstrip() + ' {']
    for field in ('built', 'build'):
        lines.append(f'  {field} = {lua(data[field])},')
    lines.append('  ranks = {')
    for rank in data['ranks']:
        lines.append(f'    {lua(rank)},')
    lines.append('  },')
    for section in ('toolKinds', 'recipes', 'npcs', 'quests', 'vendorPrices', 'sell', 'factions', 'items'):
        lines.append(f'  {section} = {{')
        entries = data[section]
        if section == 'recipes':
            order = sorted(entries, key=lambda s: (entries[s]['learn'], entries[s]['colors'][1], s))
        else:
            order = sorted(entries)
        for k in order:
            lines.append(f'    [{k}] = {lua(entries[k])},')
        lines.append('  },')
    lines.append('}')
    path = out_dir / f'{display}.lua'
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    return path


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--inputs', required=True, type=Path)
    ap.add_argument('--classicdb', required=True, type=Path)
    ap.add_argument('--out', type=Path, default=ROOT / 'Data' / 'Catalog')
    ap.add_argument('--only')
    args = ap.parse_args()
    ctx = Context(args.inputs, args.classicdb)
    args.out.mkdir(parents=True, exist_ok=True)
    manifest = ctx.client.manifest
    summary = {}
    for key in PROFESSIONS:
        if args.only and key != args.only:
            continue
        data, report = build_profession(ctx, key)
        path = write_lua(data, key, PROFESSIONS[key][1], args.out)
        kinds = defaultdict(int)
        for recipe in data['recipes'].values():
            for source in recipe['get']:
                kinds[source['kind'] + ('?' if source.get('costGuess') else '')] += 1
        summary[key] = {'recipes': len(data['recipes']), 'skipped': len(report['skipped']), 'sources': dict(kinds)}
        print(f'{key}: {len(data["recipes"])} recipes -> {path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}'
              f' {dict(kinds)}')
    sources_json = {
        'client': {'source': manifest['source'], 'build': manifest['build'], 'eraBuild': manifest['eraBuild'],
                   'tables': {k: v['sha256'] for k, v in sorted(manifest['tables'].items())}},
        'questiedb': manifest.get('questiedb'),
        'allthethings': manifest.get('allthethings'),
        'classicdb': {'source': 'https://github.com/cmangos/classic-db', 'sha256': sha(args.classicdb)},
        'summary': summary,
    }
    (args.out / 'SOURCES.json').write_text(json.dumps(sources_json, indent=2, sort_keys=True) + '\n')


if __name__ == '__main__':
    main()
