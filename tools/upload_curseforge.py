#!/usr/bin/env python3
"""Upload dist/CraftPilot-<version>.zip to CurseForge (project 1812811, WoW Forever).

    CF_API_TOKEN=... python3 tools/upload_curseforge.py v1.0.1 [--dry-run]

The changelog is docs/RELEASE_<version>.md. QuestieDB is attached as a required dependency. The release type is
"release" so the CurseForge app offers the file to everyone. Game version: WoW Forever 1.60.1 (CurseForge ID 17053, the same ID QuestieDB uploads with).
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
API = 'https://wow.curseforge.com/api'
PROJECT_ID = '1812811'
FOREVER_GAME_VERSION = 17053


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('tag')
    p.add_argument('--dry-run', action='store_true')
    args = p.parse_args()
    m = re.fullmatch(r'v(\d+\.\d+\.\d+)', args.tag)
    if not m:
        raise SystemExit('Tag must look like v1.2.3')
    version = m.group(1)
    archive = ROOT / 'dist' / f'CraftPilot-{version}.zip'
    notes = ROOT / 'docs' / f'RELEASE_{version}.md'
    if not archive.is_file() or not notes.is_file():
        raise SystemExit(f'Missing {archive.name} or {notes.name}')
    metadata = {
        'displayName': f'CraftPilot {version}',
        'releaseType': 'release',
        'changelog': notes.read_text(encoding='utf-8'),
        'changelogType': 'markdown',
        'gameVersions': [FOREVER_GAME_VERSION],
        'relations': {'projects': [{'slug': 'questiedb', 'type': 'requiredDependency'}]},
    }
    if args.dry_run:
        print(json.dumps({k: v for k, v in metadata.items() if k != 'changelog'}, indent=2))
        print(f'Dry run: would upload {archive.name}')
        return
    token = os.environ.get('CF_API_TOKEN')
    if not token:
        raise SystemExit('CF_API_TOKEN is required')
    result = subprocess.run(
        ['curl', '-sS', '--fail-with-body', '--connect-timeout', '30', '--max-time', '600',
         '-H', f'X-Api-Token: {token}', '--form-string', f'metadata={json.dumps(metadata)}',
         '-F', f'file=@{archive}', f'{API}/projects/{PROJECT_ID}/upload-file'],
        capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit(f'Upload failed: {result.stdout or result.stderr}')
    print(f'Uploaded {archive.name}: {result.stdout.strip()}')


if __name__ == '__main__':
    main()
