"""Build or verify the install archive from the explicit runtime allowlist."""
import argparse
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
FILES = ['CraftPilotPro.toc', 'Core/Locale.lua', 'Locales/enUS.lua', 'Features/Camping.lua', 'Features/Economy.lua', 'Features/RecipeActions.lua', 'Core/TrainerRecipes.lua', 'UI/Presentation.lua', 'Features/ManualShopping.lua', 'Planning/CraftSuggestions.lua', 'UI/PlanUX.lua', 'Core/SkillPolicy.lua', 'Planning/ForwardPlanning.lua', 'Planning/CheapestPath.lua', 'Planning/Recommendation.lua', 'Features/Alts.lua', 'Features/Companion.lua', 'Planning/Learning.lua', 'Features/Farming.lua', 'Features/FarmRate.lua', 'Features/Account.lua', 'Features/Keep.lua', 'Features/Marks.lua', 'Features/Round.lua', 'Features/Endgame.lua', 'Features/Wishlist.lua', 'Features/Collection.lua', 'Features/ItemDB.lua', 'Features/RaidStock.lua', 'Features/Projects.lua', 'Features/Protection.lua', 'Features/SkillLog.lua', 'UI/Help.lua', 'Features/VendorBrowser.lua', 'Features/VendorStatus.lua', 'Planning/Costing.lua', 'Planning/RawMaterials.lua', 'Planning/BuyTiming.lua', 'Planning/SecondProfession.lua', 'Planning/Planning.lua', 'Features/Market.lua', 'Features/Shopping.lua', 'Core/Diagnostics.lua', 'Core/QuestieBridge.lua', 'Core/PriceScan.lua', 'Core/Updates.lua', 'Core/SkillInfo.lua', 'Core/Data.lua', 'Core/Core.lua', 'Core/Catalog.lua',
         'Core/PriceHistory.lua', 'Planning/Route.lua', 'UI/UI.lua', 'Core/Settings.lua', 'Media/CraftPilot.tga', 'Media/Round.tga', 'LICENSE',
         'README.md', 'DATA_SOURCES.md', 'docs/PROFESSION_STATUS.md',
         'Data/Catalog/SOURCES.json', 'Data/Catalog/SOURCE.md',
         'ThirdParty/Trainers/Trainers.lua', 'ThirdParty/Trainers/SOURCES.json', 'ThirdParty/Trainers/SOURCE.md',
         'ThirdParty/Gathering/Gathering.lua', 'ThirdParty/Gathering/SOURCES.json', 'ThirdParty/Gathering/SOURCE.md']
FILES += ['Data/Catalog/' + name + '.lua' for name in
          ['Camp', 'Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Leatherworking', 'Tailoring', 'Mining',
           'Cooking', 'FirstAid', 'Herbalism', 'Skinning', 'Fishing', 'Observed']]

def source_bytes(name):
    data=(ROOT / name).read_bytes()
    return data if name.endswith(('.tga','.png')) else data.replace(b'\r\n', b'\n')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--out', type=Path, default=ROOT / 'dist', help='folder for the archive (default: dist)')
    args = parser.parse_args()
    version = next(line.split(':', 1)[1].strip() for line in
                   (ROOT / 'CraftPilotPro.toc').read_text().splitlines()
                   if line.startswith('## Version:'))
    # Every file the TOC loads must be in the package, or the addon breaks in game.
    loaded = {line.strip().replace('\\', '/') for line in (ROOT / 'CraftPilotPro.toc').read_text().splitlines()
              if line.strip() and not line.startswith('#')}
    missing = sorted(loaded - set(FILES))
    if missing:
        raise SystemExit('TOC loads files missing from FILES: ' + ', '.join(missing))
    args.out.mkdir(parents=True, exist_ok=True)
    archive = args.out / f'CraftPilot-{version}.zip'
    if not args.check:
        with ZipFile(archive, 'w', compression=ZIP_DEFLATED) as output:
            for name in FILES:
                info = ZipInfo('CraftPilotPro/' + name, (2026, 11, 8, 0, 0, 0))
                info.compress_type = ZIP_DEFLATED
                info.external_attr = 0o644 << 16
                output.writestr(info, source_bytes(name))
    with ZipFile(archive) as output:
        assert output.testzip() is None
        assert set(output.namelist()) == {'CraftPilotPro/' + name for name in FILES}
        for name in FILES:
            assert output.read('CraftPilotPro/' + name) == source_bytes(name), name
    print(f'PASS: {archive.name}, {len(FILES)} allowlisted files match source')

if __name__ == '__main__':
    main()
