"""Download the WoW Forever client tables CraftPilot's own recipe catalog is built from.

The tables are the game client's own DB2 files as wago.tools publishes them (CSV, one per table and build).
They are written gzipped (deterministic: no timestamps) with a manifest.json that records the build and the
SHA-256 of every table, so a build of the catalog can name exactly what it was made from.

    python3 tools/catalog/fetch_inputs.py --out DIR [--build 1.60.1.xxxxx] [--era-build 1.15.x.xxxxx]

Runs in GitHub Actions (tools/../.github/workflows/catalog-inputs.yml), which publishes DIR as the orphan
branch `catalog-inputs`. Nothing here is shipped with the addon.
"""
import argparse
import datetime
import gzip
import hashlib
import io
import json
import os
import sys
import tarfile
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

UA = 'CraftPilot-catalog/1.0 (+https://github.com/Necrite82/CraftPilot)'
BUILDS = 'https://wago.tools/api/builds'
DB2 = 'https://wago.tools/db2/{table}/csv?build={build}'

# The Forever client's tables the catalog reads.
TABLES = [
    'SkillLine',          # professions and their sub-lines
    'SkillLineAbility',   # which spell belongs to which profession, at which skill, and its colours
    'SpellName',          # recipe names
    'SpellEffect',        # what a recipe makes (and how many), what a recipe item teaches
    'SpellReagents',      # the materials
    'SpellMisc',          # icons and attributes
    'SpellCooldowns',     # crafts with a cooldown (Mooncloth, transmutes)
    'SpellTotems',        # tools a recipe needs (Blacksmith Hammer, ...)
    'TotemCategory',      # tool kinds
    'SpellLevels',        # character level a spell asks for
    'ItemSparse',         # item names, vendor prices, required skill / reputation of recipe items
    'Item',               # item class (recipe, consumable, ...)
    'ItemEffect',         # what using an item does (the spell a recipe item casts)
    'ItemXItemEffect',    # item -> its effects
    'Faction',            # reputation names
    'AreaTable',          # zone names
]
# The Classic Era client still has the teaching spells trainers use (CMaNGOS lists those); Forever's no longer.
ERA_TABLES = ['SkillLineAbility', 'SpellEffect', 'SpellName']


def get(url, tries=4):
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=300) as r:
                return r.read()
        except Exception as err:  # network hiccups: retry with a pause, then give up loudly
            if attempt == tries - 1:
                raise
            print(f'  retry {attempt + 1} for {url}: {err}', file=sys.stderr)
            time.sleep(5 * (attempt + 1))


def version_key(version):
    return tuple(int(x) for x in version.split('.'))


def newest(builds, branches, prefix):
    found = [b['version'] for branch in branches for b in builds.get(branch, []) if b['version'].startswith(prefix)]
    if not found:
        raise SystemExit(f'wago.tools lists no {prefix}* build on {branches}; branches: {sorted(builds)}')
    return max(found, key=version_key)


def gz(data):
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode='wb', mtime=0, compresslevel=9) as f:
        f.write(data)
    return buf.getvalue()


def fetch(table, build, out, prefix=''):
    data = get(DB2.format(table=table, build=build))
    if not data.strip() or data.lstrip()[:1] == b'<':
        raise SystemExit(f'wago.tools sent no CSV for {table} @ {build}')
    name = f'{prefix}{table}.csv.gz'
    (out / name).write_bytes(gz(data))
    text = data.decode('utf-8-sig')
    header = text.split('\n', 1)[0].strip()
    rows = text.count('\n') - 1
    print(f'  {name}: {rows} rows, {len(data)} bytes')
    print(f'    columns: {header}')
    return name, {'sha256': hashlib.sha256(data).hexdigest(), 'rows': rows, 'bytes': len(data), 'columns': header}


QUESTIE_REPO = 'Questie/QuestieDB'
# The baked Forever database (every correction folded in, as players have it installed) and the zone table.
QUESTIE_FILES = {'QuestieDB_Forever.toc': 'questiedb-Forever.toc.gz',
                 'support/Forever/Zones/areaIdToUiMapId.lua': 'questiedb-areaIdToUiMapId.lua.gz'}


def github(url):
    headers = {'User-Agent': UA, 'Accept': 'application/vnd.github+json'}
    token = os.environ.get('GITHUB_TOKEN')
    if token:
        headers['Authorization'] = 'Bearer ' + token
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=300) as r:
        return r.read()


def fetch_questiedb(out):
    """The newest QuestieDB release package: its baked QuestieDB_Forever.toc and the Forever zone table."""
    release = json.loads(github(f'https://api.github.com/repos/{QUESTIE_REPO}/releases/latest'))
    assets = sorted((a for a in release.get('assets', []) if a['name'].lower().endswith('.zip')),
                    key=lambda a: 'forever' not in a['name'].lower())
    print(f"QuestieDB {release['tag_name']}: assets {[a['name'] for a in release.get('assets', [])]}")
    if not assets:
        raise SystemExit('QuestieDB release has no zip package')
    data = get(assets[0]['browser_download_url'])
    info = {'tag': release['tag_name'], 'asset': assets[0]['name'], 'sha256': hashlib.sha256(data).hexdigest(),
            'files': {}}
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        names = z.namelist()
        for wanted, target in QUESTIE_FILES.items():
            match = [n for n in names if n.endswith('/' + wanted) or n == wanted]
            if not match:
                raise SystemExit(f'QuestieDB package lacks {wanted}; has e.g. {names[:15]}')
            raw = z.read(sorted(match, key=len)[0])
            (out / target).write_bytes(gz(raw))
            info['files'][target] = {'from': match[0], 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}
            print(f'  {target}: {len(raw)} bytes from {match[0]}')
    return info


ATT_REPO = 'ATTWoWAddon/AllTheThings'
ATT_DB = '.contrib/.db/forever/'


def fetch_att(out):
    """AllTheThings' Forever source database (MIT) at the newest commit, as one deterministic tar.gz."""
    head = json.loads(github(f'https://api.github.com/repos/{ATT_REPO}/commits/HEAD'))['sha']
    tree = json.loads(github(f'https://api.github.com/repos/{ATT_REPO}/git/trees/{head}?recursive=1'))
    paths = sorted(t['path'] for t in tree['tree'] if t['type'] == 'blob' and t['path'].startswith(ATT_DB)
                   and t['path'].endswith('.lua'))
    print(f'AllTheThings {head[:7]}: {len(paths)} Forever source files (tree truncated: {tree.get("truncated")})')
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode='w', format=tarfile.USTAR_FORMAT) as tar:
        for path in paths:
            raw = get('https://raw.githubusercontent.com/%s/%s/%s' % (
                ATT_REPO, head, urllib.parse.quote(path)))
            entry = tarfile.TarInfo(path[len(ATT_DB):])
            entry.size, entry.mtime, entry.mode = len(raw), 0, 0o644
            tar.addfile(entry, io.BytesIO(raw))
    data = buf.getvalue()
    (out / 'att-forever.tar.gz').write_bytes(gz(data))
    return {'commit': head, 'files': len(paths), 'sha256': hashlib.sha256(data).hexdigest()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--build')
    ap.add_argument('--era-build')
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    builds = json.loads(get(BUILDS))
    forever = {k: [b['version'] for b in v[:5]] for k, v in builds.items() if k in ('wowf', 'wow_classic_beta')}
    print('wago.tools Forever branches:', json.dumps(forever))
    build = args.build or newest(builds, ('wowf', 'wow_classic_beta'), '1.6')
    era = args.era_build or newest(builds, ('wow_classic_era',), '1.15')
    print(f'Forever build {build}, Classic Era build {era}')

    manifest = {'source': 'https://wago.tools', 'build': build, 'eraBuild': era,
                'fetched': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%MZ'), 'tables': {}}
    for table in TABLES:
        name, info = fetch(table, build, out)
        manifest['tables'][name] = info
    for table in ERA_TABLES:
        name, info = fetch(table, era, out, prefix='era-')
        manifest['tables'][name] = info
    manifest['questiedb'] = fetch_questiedb(out)
    manifest['allthethings'] = fetch_att(out)
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    # The fingerprint without the fetch time: the workflow republishes only when this changes.
    stable = {k: v for k, v in manifest.items() if k != 'fetched'}
    (out / 'FINGERPRINT').write_text(hashlib.sha256(json.dumps(stable, sort_keys=True).encode()).hexdigest() + '\n')


if __name__ == '__main__':
    main()
