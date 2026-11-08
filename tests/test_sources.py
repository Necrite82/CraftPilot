"""Offline regression checks for source selection and evidence preservation."""
import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('prepare_sources', Path(__file__).resolve().parents[1] / 'tools/prepare_sources.py')
sources = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sources)

class SourceTests(unittest.TestCase):
    def test_blocks_do_not_attach_empty_items_to_next_record(self):
        text = 'x = {\n  [1] = {},\n  [2] = {\n    ["V"] = {\n      [9] = 0,\n    },\n  },\n  [3] = {},\n}\n'
        result = sources.blocks(text)
        self.assertEqual(set(result), {2})
        self.assertIn('[9] = 0', result[2])

    def test_filter_retains_uncertainty_prices_and_duplicate_vendor_slots(self):
        service = {'spellId': 7, 'skillRank': 20, 'level': 0, 'sources': 1,
                   'costs': {'5': 150}, 'bartered': {'1': {'5': 140}}}
        entry = {'itemId': 42, 'stack': 5, 'costs': {'5': 100}, 'sources': 1,
                 'limited': True, 'stockMax': 1, 'costItems': [{'itemId': 3, 'amount': 2}]}
        trainers = {'1': {'tradeskill': True, 'services': {'7': service, '9': {'skill': 'First Aid'}}},
                    '2': {'tradeskill': False, 'services': {'7': service}}}
        vendors = {'3': {'entries': {'item:42': entry, 'item:42#2': entry, 'item:99': {'itemId': 99}}},
                   '4': {'repairs': True}}
        before = copy.deepcopy((trainers, vendors))
        t, v = sources.select_eg(trainers, vendors, {7: {}}, {42})
        self.assertEqual(set(t), {'1'})
        self.assertEqual(t['1']['services'], {'7': service})
        self.assertEqual(set(v['3']['entries']), {'item:42', 'item:42#2'})
        self.assertEqual((trainers, vendors), before)

    def test_build_and_license_mismatch_rejected(self):
        meta = {'product': 'wowf', 'clientBuild': sources.BUILD, 'schemaVersion': 1,
                'license': 'CC BY 4.0', 'dataset': 'trainers'}
        sources.validate_eg({'meta': meta, 'trainers': {}}, 'trainers')
        for key, bad in [('clientBuild', 'old'), ('license', 'unknown'), ('product', 'wow_classic_beta')]:
            with self.assertRaises(ValueError):
                sources.validate_eg({'meta': {**meta, key: bad}, 'trainers': {}}, 'trainers')

    def test_catalog_scope(self):
        recipes, items, _ = sources.catalog()
        self.assertEqual(len(recipes), 2080)
        self.assertIn(3755, recipes)
        self.assertNotIn(1313, recipes)  # NPC, not a recipe
        self.assertIn(3371, items)

    def test_modified_source_is_rejected_before_parsing(self):
        import tempfile
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'eg').mkdir()
            (root / 'eg' / 'LICENSE').write_bytes(b'changed')
            lock = {'sources': {'eg': {'files': {'LICENSE': sources.digest(b'original')}}}}
            with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                sources.build(root, lock)

    def test_checked_in_data_has_no_false_multisource_claim(self):
        import json
        data = json.loads((sources.OUT / 'eg-trainers.json').read_text(encoding='utf-8'))
        services = [s for t in data['trainers'].values() for s in t['services'].values()]
        self.assertEqual(len(services), 176)
        self.assertTrue(all(s['sources'] == 1 for s in services))
        self.assertNotIn('research/', (sources.ROOT / 'CraftPilot.toc').read_text())

if __name__ == '__main__':
    unittest.main()
