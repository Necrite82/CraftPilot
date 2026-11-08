"""Extract only cooking/first-aid spell IDs and color thresholds from pinned inputs."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'ThirdParty/CraftLadder'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-dir', type=Path, required=True)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    lock = json.loads((DATA / 'CAMP_SOURCES.json').read_text())
    lines = ['-- Skill-range subset derived from Craft Ladder, GPL-3.0.',
             '-- Original copyright and notices retained in CREDITS.txt and SOURCE.md.',
             '-- Modified: spell IDs and four color thresholds only; no other recipe or gathering data.',
             '-- Build 1.60.1.70425, generated 2026-10-16; pinned inputs in CAMP_SOURCES.json.',
             'local _,CP=...', 'CP.SecondarySkillRanges={']
    count = 0
    for name in ['Cooking', 'FirstAid']:
        raw = (args.source_dir / (name + '.lua')).read_bytes()
        assert hashlib.sha256(raw).hexdigest() == lock['inputs'][name + '.lua']['sha256'], name
        inside = False
        records = {}
        for line in raw.decode('utf-8').splitlines():
            if re.match(r'  recipes = \{\s*$', line):
                inside = True
                continue
            if inside and re.match(r'  },', line):
                break
            if not inside:
                continue
            match = re.match(r'    \[(\d+)\] = \{.*?colors = \{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*}', line)
            if match:
                values = list(map(int, match.groups()[1:]))
                assert values == sorted(values) and max(values) <= 1000
                records[int(match[1])] = values
        assert records, name
        lines.append('  ' + name.lower() + '={')
        for spell, values in sorted(records.items()):
            lines.append('    [%d]={%s},' % (spell, ','.join(map(str, values))))
        lines.append('  },')
        count += len(records)
    lines.append('}')
    product = ('\n'.join(lines) + '\n').encode('utf-8')
    target = DATA / 'SecondarySkillRanges.lua'
    if args.check:
        assert target.read_bytes().replace(b'\r\n', b'\n') == product
    else:
        target.write_bytes(product)
    print(f'PASS: {count} secondary-profession skill-range records, pinned input hashes verified')

if __name__ == '__main__':
    main()
