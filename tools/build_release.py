"""Build or verify the install archive from the explicit runtime allowlist."""
import argparse
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
FILES = ['CraftPilot.toc', 'Core/Locale.lua', 'Locales/enUS.lua', 'Features/Camping.lua', 'Features/Economy.lua', 'Features/RecipeActions.lua', 'Core/TrainerRecipes.lua', 'UI/Presentation.lua', 'Features/ManualShopping.lua', 'Planning/CraftSuggestions.lua', 'UI/PlanUX.lua', 'Core/SkillPolicy.lua', 'Planning/ForwardPlanning.lua', 'Planning/CheapestPath.lua', 'Planning/Recommendation.lua', 'Features/Alts.lua', 'Features/Companion.lua', 'Planning/Learning.lua', 'Features/Farming.lua', 'Features/Account.lua', 'Features/Keep.lua', 'Features/Marks.lua', 'Features/Round.lua', 'Features/Endgame.lua', 'Features/Wishlist.lua', 'Features/RaidStock.lua', 'Features/Protection.lua', 'UI/Help.lua', 'Features/VendorBrowser.lua', 'Planning/Costing.lua', 'Planning/Planning.lua', 'Features/Market.lua', 'Features/Shopping.lua', 'Core/Diagnostics.lua', 'Core/QuestieBridge.lua', 'Core/Updates.lua', 'Core/SkillInfo.lua', 'ThirdParty/CraftLadder/SecondarySkillRanges.lua', 'ThirdParty/CraftLadder/VendorRecipes.lua', 'Core/Data.lua', 'Core/Core.lua', 'Core/Catalog.lua',
         'Core/PriceHistory.lua', 'Planning/Route.lua', 'UI/UI.lua', 'Core/Settings.lua', 'Media/CraftPilot.tga', 'Media/Round.tga', 'LICENSE',
         'README.md', 'DATA_SOURCES.md', 'docs/CAMPING_SOURCES.md', 'docs/PROFESSION_STATUS.md',
         'ThirdParty/CraftLadder/Camp.lua', 'ThirdParty/CraftLadder/CampingRecipes.lua',
         'ThirdParty/CraftLadder/CAMP_SOURCES.json',
         'ThirdParty/CraftLadder/UPSTREAM.json',
         'ThirdParty/Trainers/Trainers.lua', 'ThirdParty/Trainers/SOURCES.json', 'ThirdParty/Trainers/SOURCE.md',
         'ThirdParty/Gathering/Gathering.lua', 'ThirdParty/Gathering/SOURCES.json', 'ThirdParty/Gathering/SOURCE.md',
         'ThirdParty/CraftLadder/CREDITS.txt', 'ThirdParty/CraftLadder/SOURCE.md']
FILES += ['ThirdParty/CraftLadder/' + name + '.lua' for name in
          ['Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering',
           'Leatherworking', 'Tailoring', 'MiningSmelting']]

def source_bytes(name):
    data=(ROOT / name).read_bytes()
    return data if name.endswith(('.tga','.png')) else data.replace(b'\r\n', b'\n')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--out', type=Path, default=ROOT / 'dist', help='folder for the archive (default: dist)')
    args = parser.parse_args()
    version = next(line.split(':', 1)[1].strip() for line in
                   (ROOT / 'CraftPilot.toc').read_text().splitlines()
                   if line.startswith('## Version:'))
    args.out.mkdir(parents=True, exist_ok=True)
    archive = args.out / f'CraftPilot-{version}.zip'
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
