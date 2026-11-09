"""Extract vendor crafting recipes and referenced NPCs from existing pinned secondary inputs."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'ThirdParty/CraftLadder'

def section(text,name):
    inside=False
    for line in text.splitlines():
        if line=='  '+name+' = {': inside=True;continue
        if inside and line=='  },': break
        if inside: yield line

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-dir',type=Path,required=True)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    lock=json.loads((DATA/'CAMP_SOURCES.json').read_text())
    lines=['-- Vendor recipe subset derived from Craft Ladder, GPL-3.0.',
           '-- Original copyright and notices: CREDITS.txt and SOURCE.md.',
           '-- Modified: only vendor crafting recipes and referenced NPC records.',
           '-- Build 1.60.1.70425; existing pinned input hashes in CAMP_SOURCES.json.',
           'local _,CP=...', 'CP.VendorRecipeCatalogs={']
    count=0
    for name in ['Cooking','FirstAid']:
        raw=(args.source_dir/(name+'.lua')).read_bytes()
        assert hashlib.sha256(raw).hexdigest()==lock['inputs'][name+'.lua']['sha256'],name
        text=raw.decode('utf-8')
        selected=[line for line in section(text,'recipes') if 'kind = "vendor"' in line and 'mats = {' in line and 'colors = {' in line]
        npcs=set(int(n) for line in selected for n in re.findall(r'\bnpc = (\d+)',line))
        lines.extend(['  '+name.lower()+'={','    recipes={'])
        lines.extend(selected)
        lines.extend(['    },','    npcs={'])
        for line in section(text,'npcs'):
            match=re.match(r'    \[(\d+)\] = ',line)
            if match and int(match[1]) in npcs: lines.append(line)
        lines.extend(['    },','  },'])
        count+=len(selected)
    lines.append('}')
    product=('\n'.join(lines)+'\n').encode('utf-8')
    target=DATA/'VendorRecipes.lua'
    if args.check: assert target.read_bytes().replace(b'\r\n',b'\n')==product
    else: target.write_bytes(product)
    print(f'PASS: {count} focused vendor recipes and referenced NPCs, pinned hashes verified')

if __name__=='__main__': main()
