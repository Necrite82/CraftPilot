"""Build or verify the install archive from the explicit runtime allowlist."""
import argparse
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
FILES = ['CraftPilot.toc', 'Data.lua', 'Core.lua', 'Catalog.lua',
         'PriceHistory.lua', 'Route.lua', 'UI.lua', 'LICENSE',
         'README.md', 'DATA_SOURCES.md',
         'ThirdParty/CraftLadder/CREDITS.txt', 'ThirdParty/CraftLadder/SOURCE.md']
FILES += ['ThirdParty/CraftLadder/' + name + '.lua' for name in
          ['Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering',
           'Leatherworking', 'Tailoring', 'MiningSmelting']]

def source_bytes(name):
    # Every allowlisted file is UTF-8 text. Match Git's LF representation on
    # Windows and Linux without changing the actual program or license text.
    return (ROOT / name).read_bytes().replace(b'\r\n', b'\n')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    version = next(line.split(':', 1)[1].strip() for line in
                   (ROOT / 'CraftPilot.toc').read_text().splitlines()
                   if line.startswith('## Version:'))
    archive = ROOT / 'dist' / f'CraftPilot-{version}.zip'
    if not args.check:
        with ZipFile(archive, 'w', compression=ZIP_DEFLATED) as output:
            for name in FILES:
                info = ZipInfo('CraftPilot/' + name, (2026, 11, 8, 0, 0, 0))
                info.compress_type = ZIP_DEFLATED
                info.external_attr = 0o644 << 16
                output.writestr(info, source_bytes(name))
    with ZipFile(archive) as output:
        assert output.testzip() is None
        assert set(output.namelist()) == {'CraftPilot/' + name for name in FILES}
        for name in FILES:
            assert output.read('CraftPilot/' + name) == source_bytes(name), name
    print(f'PASS: {archive.name}, {len(FILES)} allowlisted files match source')

if __name__ == '__main__':
    main()
