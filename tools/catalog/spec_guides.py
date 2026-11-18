"""Specialization guides (Weaponsmith, Armorsmith, Gnomish/Goblin Engineering, the Leatherworking ones), derived:

  - the quest that grants a specialization: CMaNGOS classic-db quest_template (RewSpell / RewSpellCast teaching it),
    kept when Forever has the quest (QuestieDB)
  - the quests before it: QuestieDB's prerequisites (preQuestSingle: any one of them, preQuestGroup: all of them),
    walked back to the first quest
  - what each step asks for: CMaNGOS ReqItemId/ReqItemCount; level and skill: the final quest's requirements
  - master specializations (Master Axesmith ...): the quests whose reward is a plan only that master can use

Output fields follow the catalog: specs = {spell: name}, specGuides = list of
{spec, icon, level, skill, steps = {{quests = {...}, items = {{item, n}}} | {pick = {{quests, items, spec}}}}}.
"""
import gzip
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import import_trainers  # noqa: E402

SPECS = {
    'blacksmithing': {'base': [9787, 9788], 'masters': {9787: [17041, 17040, 17039]}},
    'engineering': {'base': [20219, 20222], 'masters': {}},
    'leatherworking': {'base': [10656, 10658, 10660], 'masters': {}},
}
MAX_STEPS = 20


def quest_template(sql_gz_path):
    text = gzip.decompress(Path(sql_gz_path).read_bytes()).decode('utf-8', 'replace')
    m = re.search(r'CREATE TABLE `quest_template` \((.*?)\n\)', text, re.S)
    columns = [line.split()[0].strip('`') for line in m.group(1).splitlines() if line.strip().startswith('`')]
    out = {}
    for line in text.splitlines():
        if line.startswith('INSERT INTO `quest_template`'):
            for values in import_trainers.sql_rows(line[line.index('VALUES') + 6:]):
                row = dict(zip(columns, values))
                out[int(row['entry'])] = row
    return out


def required_items(row):
    items = []
    for i in range(1, 5):
        item, n = int(row.get(f'ReqItemId{i}') or 0), int(row.get(f'ReqItemCount{i}') or 0)
        if item and n:
            items.append({'item': item, 'n': n})
    return items


class SpecGuides:
    def __init__(self, ctx, sql_gz_path):
        self.ctx = ctx
        self.q = ctx.questie
        self.templates = quest_template(sql_gz_path)
        self.grants = {}
        for quest, row in self.templates.items():
            for column in ('RewSpell', 'RewSpellCast'):
                spell = int(row.get(column) or 0)
                spell = ctx.era_teach.get(spell, spell)
                if spell and self.q.has('Quest', quest):
                    self.grants.setdefault(spell, set()).add(quest)
        icons = {}
        for r in ctx.client.rows('SpellMisc'):
            if int(r['DifficultyID'] or 0) == 0 and int(r['SpellIconFileDataID'] or 0):
                icons.setdefault(int(r['SpellID']), int(r['SpellIconFileDataID']))
        self.icons = icons

    def items(self, quests):
        """What the step's quests ask for, when they all ask for the same (the Alliance and Horde versions)."""
        found = [required_items(self.templates[q]) for q in quests if q in self.templates]
        if found and all(f == found[0] for f in found):
            return found[0]
        return []

    def chain(self, finals):
        """Steps from the first quest to the finals: [[quests of step 1], ..., finals]."""
        steps, current, seen = [sorted(finals)], set(finals), set(finals)
        while len(steps) < MAX_STEPS:
            before = set()
            for quest in current:
                single = self.q.entity('Quest', quest).get(13) or []
                group = self.q.entity('Quest', quest).get(12) or []
                for p in list(single) + list(group):
                    if isinstance(p, int) and p not in seen and self.q.has('Quest', p):
                        before.add(p)
            if not before:
                break
            seen |= before
            steps.insert(0, sorted(before))
            current = before
        return steps

    def master_pick(self, master):
        """{quests, items, spec} for a master specialization: the quests whose reward is a plan only it can use."""
        plans = {item for item, row in self.ctx.items.items() if int(row.get('RequiredAbility') or 0) == master}
        quests = sorted(quest for quest, row in self.templates.items() if self.q.has('Quest', quest)
                        and any(int(row.get(f'RewItemId{i}') or 0) in plans for i in range(1, 5)))
        if not quests:
            return None
        return {'quests': quests, 'items': self.items(quests), 'spec': master}

    def build(self, key):
        config = SPECS.get(key)
        if not config:
            return {}, []
        names, guides = {}, []
        for spec in config['base']:
            finals = sorted(self.grants.get(spec, ()))
            if not finals:
                continue
            names[spec] = self.ctx.spell_names.get(spec, str(spec))
            guide = {'spec': spec}
            if self.icons.get(spec):
                guide['icon'] = self.icons[spec]
            level = max(self.q.quest(qq, 'requiredLevel') or 0 for qq in finals)
            skill = max((self.q.quest(qq, 'requiredSkill') or [0, 0])[1] for qq in finals)
            if level:
                guide['level'] = level
            if skill:
                guide['skill'] = skill
            steps = []
            for quests in self.chain(finals):
                step = {'quests': quests}
                items = self.items(quests)
                if items:
                    step['items'] = items
                steps.append(step)
            picks = []
            for master in config['masters'].get(spec, []):
                pick = self.master_pick(master)
                if pick:
                    names[master] = self.ctx.spell_names.get(master, str(master))
                    picks.append(pick)
            if picks:
                steps.append({'pick': picks})
            guide['steps'] = steps
            guides.append(guide)
        return names, guides
