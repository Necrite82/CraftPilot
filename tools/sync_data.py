"""Keep the trainer list (ThirdParty/Trainers) and the gathering zones (ThirdParty/Gathering) current.

  --check    verify the bundled files equal what their pinned inputs produce
  --update   pin the newest QuestieDB release and CMaNGOS classic-db, regenerate, report changes

Trainers: QuestieDB (which NPCs train in Forever) and CMaNGOS classic-db (the ranks they teach), pinned in
ThirdParty/Trainers/SOURCES.json. Gathering zones: QuestieDB, pinned in ThirdParty/Gathering/SOURCES.json.
The recipe catalog has its own pipeline: tools/catalog.
"""
import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]


def sha(data):
    return hashlib.sha256(data).hexdigest()


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
    parser.add_argument('--cache', default=str(ROOT / 'work' / 'data-inputs'))
    parser.add_argument('--report', help='write a Markdown change summary here')
    parser.add_argument('--force', action='store_true', help='regenerate even if already pinned')
    parser.add_argument('--github-output', help='append changed=true|false for GitHub Actions')
    args = parser.parse_args()
    if args.check:
        check_trainers(args)
        check_gathering(args)
        return
    changed = False
    for report in (update_trainers(args), update_gathering(args)):
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
