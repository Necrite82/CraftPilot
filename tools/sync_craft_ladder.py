"""Sync the bundled Craft Ladder data with a pinned upstream release.

All third-party data in ThirdParty/CraftLadder comes from one upstream revision recorded in
ThirdParty/CraftLadder/UPSTREAM.json (tag, commit, client build, SHA-256 of every input).

  --check               verify the bundled files equal what the pinned inputs produce
  --update [--ref TAG]  pin the newest upstream release (or TAG), regenerate every bundled file
                        and the focused subsets, and refresh CAMP_SOURCES.json
  --report FILE         write a Markdown summary of recipe changes (with --update)

The trainer list (ThirdParty/Trainers) is synced too: the newest QuestieDB release for Forever positions and the
current CMaNGOS classic-db for the ranks each trainer teaches, pinned in ThirdParty/Trainers/SOURCES.json.

Inputs come from --upstream-dir (a craft-ladder checkout at the pinned commit) or are downloaded
from raw.githubusercontent.com and verified against the lock. Nothing else is fetched.
"""
import argparse
import datetime
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'ThirdParty' / 'CraftLadder'
LOCK = DATA / 'UPSTREAM.json'
CAMP_LOCK = DATA / 'CAMP_SOURCES.json'
REPO = 'https://github.com/saintmodx/craft-ladder'
RAW = 'https://raw.githubusercontent.com/saintmodx/craft-ladder/{rev}/CraftLadder/{path}'

# Bundled verbatim: upstream file -> file in ThirdParty/CraftLadder.
VERBATIM = {f'Data/{p}.lua': f'{p}.lua' for p in
            ['Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Leatherworking', 'Tailoring', 'Camp']}
VERBATIM['CREDITS.txt'] = 'CREDITS.txt'
# Read only to derive focused subsets.
DERIVED_INPUTS = ['Data/Mining.lua', 'Data/Cooking.lua', 'Data/FirstAid.lua', 'Data/Fishing.lua']
CAMP_INPUTS = ['Camp.lua', 'Cooking.lua', 'FirstAid.lua', 'Fishing.lua']
PROFESSIONS = ['Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Leatherworking', 'Tailoring']
SUBSET_TOOLS = ['import_camping.py', 'import_skill_ranges.py', 'import_vendor_recipes.py']


def sha(data):
    return hashlib.sha256(data).hexdigest()


def latest_release():
    """Newest vX.Y.Z tag and its commit, via git (works without API access)."""
    out = subprocess.run(['git', 'ls-remote', '--tags', REPO], check=True,
                         capture_output=True, text=True).stdout
    tags = {}
    for line in out.splitlines():
        commit, ref = line.split('\t')
        m = re.fullmatch(r'refs/tags/(v(\d+)\.(\d+)\.(\d+))(\^\{\})?', ref)
        if not m:
            continue
        key = m.group(1)
        # Annotated tags list the tag object first and the commit as ^{}; prefer the commit.
        if m.group(5) or key not in tags:
            tags[key] = (tuple(map(int, m.group(2, 3, 4))), commit)
    if not tags:
        raise SystemExit('No release tags found upstream')
    tag = max(tags, key=lambda t: tags[t][0])
    return tag, tags[tag][1]


def resolve(ref):
    out = subprocess.run(['git', 'ls-remote', REPO, ref, ref + '^{}'], check=True,
                         capture_output=True, text=True).stdout.split()
    if not out:
        raise SystemExit(f'Unknown upstream ref: {ref}')
    return out[-2]


def fetch(rev, path, upstream_dir):
    if upstream_dir:
        return subprocess.run(['git', '-C', str(upstream_dir), 'show', f'{rev}:CraftLadder/{path}'],
                              check=True, capture_output=True).stdout
    with urlopen(RAW.format(rev=rev, path=path), timeout=60) as response:
        return response.read()


def header_value(text, pattern):
    m = re.search(pattern, text)
    return m.group(1) if m else None


def smelting_subset(mining):
    """The smelting recipes of Mining.lua, unchanged line by line; nodes and zones are omitted."""
    src = mining.decode('utf-8').splitlines()
    start = src.index('  recipes = {')
    out = ["-- CraftPilot smelting subset, derived from Craft Ladder's Mining.lua (GPL-3.0).",
           '-- Original copyright, credits and upstream revision: see ThirdParty/CraftLadder/CREDITS.txt',
           '-- and ThirdParty/CraftLadder/SOURCE.md. Other mining data (nodes, coordinates, etc.) omitted.',
           'local _, ns = ...', 'ns.MINING = {', '  recipes = {']
    for line in src[start + 1:]:
        if line.startswith('  }'):
            break
        out.append(line)
    out += ['  },', '}']
    return ('\n'.join(out) + '\n').encode('utf-8')


def recipes(text):
    """recipe id -> (name, record text) for lines inside the recipes table."""
    found, inside = {}, False
    for line in text.splitlines():
        if line == '  recipes = {':
            inside = True
            continue
        if inside and line.startswith('  }'):
            break
        m = inside and re.match(r'^    \[(\d+)\] = \{ name = "([^"]*)"(.*)$', line)
        if m:
            found[int(m.group(1))] = (m.group(2), m.group(3))
    return found


def field(record, key):
    m = re.search(r'\b' + key + r' = (\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|[^,]+)', record)
    return m.group(1) if m else None


def change_report(old_files, new_files):
    lines = ['| Beruf | Rezepte | neu | entfernt | Lernstufe | Farben | Materialien | Bezugsquelle |',
             '|---|---|---|---|---|---|---|---|']
    details = []
    for prof in PROFESSIONS + ['MiningSmelting']:
        old = recipes(old_files.get(prof, b'').decode('utf-8'))
        new = recipes(new_files[prof].decode('utf-8'))
        added = sorted(new[i][0] for i in set(new) - set(old))
        removed = sorted(old[i][0] for i in set(old) - set(new))
        changed = {k: [] for k in ['learn', 'colors', 'mats', 'get']}
        for i in set(old) & set(new):
            for k in changed:
                if field(old[i][1], k) != field(new[i][1], k):
                    changed[k].append(new[i][0])
        lines.append(f'| {prof} | {len(new)} | {len(added)} | {len(removed)} | ' +
                     ' | '.join(str(len(changed[k])) for k in ['learn', 'colors', 'mats', 'get']) + ' |')
        for label, names in [('neu', added), ('entfernt', removed), ('Materialien geändert', changed['mats']),
                             ('Lernstufe geändert', changed['learn']), ('Farben geändert', changed['colors'])]:
            if names:
                shown = ', '.join(sorted(set(names))[:12]) + (' …' if len(set(names)) > 12 else '')
                details.append(f'- **{prof} · {label}:** {shown}')
    return '\n'.join(lines) + '\n\n' + '\n'.join(details) + '\n'


def update(args):
    lock_old = json.loads(LOCK.read_text()) if LOCK.exists() else {}
    if not lock_old and CAMP_LOCK.exists():
        lock_old = {'tag': json.loads(CAMP_LOCK.read_text())['revision'][:7]}
    if args.ref:
        tag, commit = args.ref, resolve(args.ref)
    else:
        tag, commit = latest_release()
    if lock_old.get('commit') == commit and not args.force:
        print(f'Up to date: {tag} ({commit[:7]})')
        return False
    inputs = {path: fetch(commit, path, args.upstream_dir) for path in list(VERBATIM) + DERIVED_INPUTS}
    camp_text = inputs['Data/Camp.lua'].decode('utf-8')
    build = header_value(camp_text, r'build (1\.\d+\.\d+\.\d+)')
    camp_date = header_value(camp_text, r'built = "(\d{4}-\d{2}-\d{2})"')
    old_files = {p.stem: p.read_bytes() for p in DATA.glob('*.lua')}

    for path, target in VERBATIM.items():
        (DATA / target).write_bytes(inputs[path])
    (DATA / 'MiningSmelting.lua').write_bytes(smelting_subset(inputs['Data/Mining.lua']))

    files = {}
    for path, data in inputs.items():
        text = data.decode('utf-8', 'replace')
        files[path] = {'sha256': sha(data),
                       'generated': header_value(text, r'GENERATED by \S+ on (\d{4}-\d{2}-\d{2})'),
                       'build': header_value(text, r'build (1\.\d+\.\d+\.\d+)')}
    LOCK.write_text(json.dumps({
        'source': REPO, 'tag': tag, 'commit': commit, 'build': build,
        'syncedOn': datetime.date.today().isoformat(), 'license': 'GPL-3.0',
        'files': files}, indent=2) + '\n')
    CAMP_LOCK.write_text(json.dumps({
        'revision': commit, 'build': build, 'generatedOn': camp_date, 'license': 'GPL-3.0',
        'inputs': {name: {'url': RAW.format(rev=commit, path='Data/' + name),
                          'sha256': files['Data/' + name]['sha256']} for name in CAMP_INPUTS}},
        indent=2) + '\n')

    # The focused subsets keep their own importers; feed them the same verified inputs.
    cache = Path(args.cache)
    cache.mkdir(parents=True, exist_ok=True)
    for name in CAMP_INPUTS:
        (cache / name).write_bytes(inputs['Data/' + name])
    for tool in SUBSET_TOOLS:
        subprocess.run([sys.executable, str(ROOT / 'tools' / tool), '--source-dir', str(cache)], check=True)

    new_files = {p.stem: p.read_bytes() for p in DATA.glob('*.lua')}
    if args.report:
        old_tag = lock_old.get('tag') or 'unbekannter Stand'
        Path(args.report).write_text(
            f'## Craft Ladder {old_tag} → {tag}\n\n'
            f'Upstream-Commit [`{commit[:7]}`]({REPO}/commit/{commit}) · Client-Build **{build}**\n\n'
            + change_report(old_files, new_files))
    print(f'Synced Craft Ladder {tag} ({commit[:7]}), build {build}')
    return True


def check(args):
    lock = json.loads(LOCK.read_text())
    inputs = {}
    for path, spec in lock['files'].items():
        data = fetch(lock['commit'], path, args.upstream_dir)
        if sha(data) != spec['sha256']:
            raise SystemExit(f'Checksum mismatch: {path}')
        inputs[path] = data
    for path, target in VERBATIM.items():
        if (DATA / target).read_bytes().replace(b'\r\n', b'\n') != inputs[path]:
            raise SystemExit(f'Bundled file differs from pinned upstream: {target}')
    if (DATA / 'MiningSmelting.lua').read_bytes().replace(b'\r\n', b'\n') != smelting_subset(inputs['Data/Mining.lua']):
        raise SystemExit('MiningSmelting.lua differs from pinned upstream')
    camp = json.loads(CAMP_LOCK.read_text())
    if camp['revision'] != lock['commit']:
        raise SystemExit('CAMP_SOURCES.json is pinned to another revision')
    print(f"PASS: bundled Craft Ladder data equals {lock['tag']} ({lock['commit'][:7]}), build {lock['build']}")


# --- Trainers: QuestieDB (positions) and CMaNGOS classic-db (ranks) ------------------------------------------------
TRAINERS = ROOT / 'ThirdParty' / 'Trainers'
QUESTIEDB = 'https://github.com/Questie/QuestieDB'
CLASSICDB = 'https://github.com/cmangos/classic-db'
QUESTIE_FILES = ['data/Forever/foreverNpcDB.lua', 'support/Forever/Zones/areaIdToUiMapId.lua']
CLASSICDB_PATH = 'Full_DB/ClassicDB_1_12_1_z2815.sql.gz'


def raw_url(repo, commit, path):
    return repo.replace('https://github.com/', 'https://raw.githubusercontent.com/') + f'/{commit}/{path}'


def download(url):
    with urlopen(url, timeout=600) as response:
        return response.read()


def newest_tag(repo):
    out = subprocess.run(['git', 'ls-remote', '--tags', repo], check=True, capture_output=True, text=True).stdout
    tags = {}
    for line in out.splitlines():
        commit, ref = line.split('\t')
        m = re.fullmatch(r'refs/tags/(v(\d+)\.(\d+)\.(\d+))(\^\{\})?', ref)
        if m and (m.group(5) or m.group(1) not in tags):
            tags[m.group(1)] = (tuple(map(int, m.group(2, 3, 4))), commit)
    tag = max(tags, key=lambda k: tags[k][0])
    return tag, tags[tag][1]


def head(repo):
    return subprocess.run(['git', 'ls-remote', repo, 'HEAD'], check=True, capture_output=True,
                          text=True).stdout.split()[0]


def trainer_inputs(sources, cache):
    """Download the pinned trainer inputs into cache, verify them, and return the importer's arguments."""
    q = sources['questiedb']
    for path in QUESTIE_FILES:
        data = download(raw_url(QUESTIEDB, q['commit'], path))
        if sha(data) != q['files'][path]['sha256']:
            raise SystemExit('Checksum mismatch: QuestieDB ' + path)
        target = cache / 'questiedb' / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    c = sources['classicdb']
    data = download(raw_url(CLASSICDB, c['commit'], c['path']))
    if sha(data) != c['sha256']:
        raise SystemExit('Checksum mismatch: classic-db')
    (cache / 'classicdb.sql.gz').write_bytes(data)
    return ['--questiedb', str(cache / 'questiedb'), '--classicdb', str(cache / 'classicdb.sql.gz')]


def trainer_counts():
    counts = {}
    path = TRAINERS / 'Trainers.lua'
    if path.exists():
        for prof in re.findall(r'^  \{"(\w+)",', path.read_text(), re.M):
            counts[prof] = counts.get(prof, 0) + 1
    return counts


def update_trainers(args):
    """Pin the newest QuestieDB release and classic-db head; regenerate Trainers.lua. Returns a report or None."""
    sources_path = TRAINERS / 'SOURCES.json'
    old = json.loads(sources_path.read_text())
    tag, q_commit = newest_tag(QUESTIEDB)
    c_commit = head(CLASSICDB)
    if old['questiedb']['commit'] == q_commit and old['classicdb']['commit'] == c_commit and not args.force:
        print(f'Trainers up to date: QuestieDB {tag}, classic-db {c_commit[:7]}')
        return None
    before = trainer_counts()
    old_text, old_trainers = sources_path.read_text(), (TRAINERS / 'Trainers.lua').read_bytes()
    new = {'questiedb': {'source': QUESTIEDB, 'tag': tag, 'commit': q_commit,
                         'files': {p: {'sha256': sha(download(raw_url(QUESTIEDB, q_commit, p)))} for p in QUESTIE_FILES}},
           'classicdb': {'source': CLASSICDB, 'commit': c_commit, 'path': CLASSICDB_PATH,
                         'sha256': sha(download(raw_url(CLASSICDB, c_commit, CLASSICDB_PATH)))}}
    sources_path.write_text(json.dumps(new, indent=2) + '\n')
    cache = Path(args.cache) / 'trainers'
    subprocess.run([sys.executable, str(ROOT / 'tools' / 'import_trainers.py')] + trainer_inputs(new, cache), check=True)
    after = trainer_counts()
    if (TRAINERS / 'Trainers.lua').read_bytes() == old_trainers and not args.force:
        sources_path.write_text(old_text)  # newer inputs, same trainers: keep the old pin, no pull request
        print(f'Trainers unchanged by QuestieDB {tag} / classic-db {c_commit[:7]}')
        return None
    rows = ['| Beruf | vorher | jetzt |', '|---|---|---|']
    for prof in sorted(set(before) | set(after)):
        rows.append(f'| {prof} | {before.get(prof, 0)} | {after.get(prof, 0)} |')
    return (f'## Lehrer: QuestieDB {old["questiedb"].get("tag", old["questiedb"]["commit"][:7])} → {tag}, '
            f'classic-db {old["classicdb"]["commit"][:7]} → {c_commit[:7]}\n\n' + '\n'.join(rows) + '\n')


def check_trainers(args):
    sources = json.loads((TRAINERS / 'SOURCES.json').read_text())
    cache = Path(args.cache) / 'trainers'
    subprocess.run([sys.executable, str(ROOT / 'tools' / 'import_trainers.py'), '--check']
                   + trainer_inputs(sources, cache), check=True)


# --- Gathering zones: QuestieDB (items, objects, zones) ----------------------------------------------------------------
GATHERING = ROOT / 'ThirdParty' / 'Gathering'
GATHERING_FILES = ['data/Forever/foreverItemDB.lua', 'data/Forever/foreverObjectDB.lua', 'support/Forever/Zones/areaIdToUiMapId.lua']


def gathering_inputs(sources, cache):
    q = sources['questiedb']
    for path in GATHERING_FILES:
        data = download(raw_url(QUESTIEDB, q['commit'], path))
        if sha(data) != q['files'][path]['sha256']:
            raise SystemExit('Checksum mismatch: QuestieDB ' + path)
        target = cache / 'questiedb' / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    return ['--questiedb', str(cache / 'questiedb')]


def check_gathering(args):
    sources = json.loads((GATHERING / 'SOURCES.json').read_text())
    subprocess.run([sys.executable, str(ROOT / 'tools' / 'import_gathering.py'), '--check']
                   + gathering_inputs(sources, Path(args.cache) / 'gathering'), check=True)


def update_gathering(args):
    """Pin the newest QuestieDB release for the gathering zones. Returns a report or None."""
    sources_path = GATHERING / 'SOURCES.json'
    old = json.loads(sources_path.read_text())
    tag, commit = newest_tag(QUESTIEDB)
    if old['questiedb']['commit'] == commit and not args.force:
        print(f'Gathering zones up to date: QuestieDB {tag}')
        return None
    old_text, old_data = sources_path.read_text(), (GATHERING / 'Gathering.lua').read_bytes()
    new = {'questiedb': {'source': QUESTIEDB, 'tag': tag, 'commit': commit,
                         'files': {p: {'sha256': sha(download(raw_url(QUESTIEDB, commit, p)))} for p in GATHERING_FILES}}}
    sources_path.write_text(json.dumps(new, indent=2) + '\n')
    subprocess.run([sys.executable, str(ROOT / 'tools' / 'import_gathering.py')]
                   + gathering_inputs(new, Path(args.cache) / 'gathering'), check=True)
    if (GATHERING / 'Gathering.lua').read_bytes() == old_data and not args.force:
        sources_path.write_text(old_text)
        print(f'Gathering zones unchanged by QuestieDB {tag}')
        return None
    return f'## Sammelgebiete: QuestieDB {old["questiedb"].get("tag")} → {tag}\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--update', action='store_true')
    parser.add_argument('--ref', help='upstream tag or commit to pin (default: newest release)')
    parser.add_argument('--upstream-dir', type=Path, help='local craft-ladder checkout instead of downloading')
    parser.add_argument('--cache', default=str(ROOT / 'work' / 'craft-ladder-inputs'))
    parser.add_argument('--report', help='write a Markdown change summary here')
    parser.add_argument('--force', action='store_true', help='regenerate even if already pinned')
    parser.add_argument('--github-output', help='append changed=true|false for GitHub Actions')
    parser.add_argument('--skip-trainers', action='store_true', help='leave ThirdParty/Trainers alone')
    args = parser.parse_args()
    if args.check:
        check(args)
        if not args.skip_trainers:
            check_trainers(args)
            check_gathering(args)
        return
    changed = update(args)
    for report in ([] if args.skip_trainers else [update_trainers(args), update_gathering(args)]):
        if report:
            changed = True
            if args.report:
                with open(args.report, 'a') as out:
                    out.write('\n' + report)
    if args.github_output:
        with open(args.github_output, 'a') as out:
            out.write(f'changed={"true" if changed else "false"}\n')


if __name__ == '__main__':
    main()
