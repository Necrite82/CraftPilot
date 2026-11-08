"""Import only pinned camp data and matching recipe records, using an existing cache."""
import argparse
import hashlib
import json
import re
from urllib.request import urlopen
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ThirdParty/CraftLadder'
def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--source-dir',type=Path,required=True)
 p.add_argument('--check',action='store_true')
 p.add_argument('--download',action='store_true',help='Fetch only manifest-pinned inputs and verify their hashes')
 args=p.parse_args()
 lock=json.loads((OUT/'CAMP_SOURCES.json').read_text())
 inputs={}
 for name,spec in lock['inputs'].items():
  if args.download:
   with urlopen(spec['url'],timeout=30) as response: data=response.read()
  else: data=(args.source_dir/name).read_bytes()
  if hashlib.sha256(data).hexdigest()!=spec['sha256']: raise ValueError('Source checksum mismatch: '+name)
  if args.download:
   args.source_dir.mkdir(parents=True,exist_ok=True)
   (args.source_dir/name).write_bytes(data)
  inputs[name]=data
 camp=inputs['Camp.lua'].decode('utf-8')
 makers=set(map(int,re.findall(r'\bmaker = (\d+)',camp)))
 lines=['-- Filtered camping recipe records from Craft Ladder; GPL-3.0, original notices in CREDITS.txt.',
        '-- Modified: only recipes referenced by Camp.lua. No gathering or unrelated recipes included.',
        'local _,CP=...', 'CP.CampingRecipeData={']
 count=0
 for name in ['Cooking','FirstAid','Fishing']:
  lines.append('  ["'+name.lower()+'"]={')
  for line in inputs[name+'.lua'].decode('utf-8').splitlines():
   match=re.match(r'    \[(\d+)\] = \{ name = ',line)
   if match and int(match[1]) in makers and 'mats =' in line and 'learn =' in line:
    lines.append(line);count+=1
  lines.append('  },')
 lines.append('}')
 products={'Camp.lua':inputs['Camp.lua'],'CampingRecipes.lua':('\n'.join(lines)+'\n').encode('utf-8')}
 for name,data in products.items():
  target=OUT/name
  if args.check:
   if target.read_bytes().replace(b'\r\n',b'\n')!=data: raise ValueError('Generated data differs: '+name)
  else: target.write_bytes(data)
 print(f'PASS: camping data and {count} additional relevant recipe records')

if __name__=='__main__': main()
