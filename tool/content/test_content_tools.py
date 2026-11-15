"""Run: python3 -m unittest discover -s tool/content -p 'test_*.py'."""
import json
import unittest
from copy import deepcopy
from pathlib import Path

from catalog_merge import archive_exercises, merge_country, upsert_records
from china_validation import validate_china


class EditorialMergeTest(unittest.TestCase):
    def test_upsert_preserves_old_identity_and_order_without_mutating_source(self):
        old = [{'id': 'china-nature', 'title': 'old'}, {'id': 'egypt-nature', 'title': 'unchanged'}]
        new = [{'id': 'china-nature', 'title': 'panda'}, {'id': 'china-new', 'title': 'new'}]
        result = upsert_records(old, new, source='china.json', kind='articles')
        self.assertEqual([r['id'] for r in result], ['china-nature', 'egypt-nature', 'china-new'])
        self.assertEqual(result[0]['title'], 'panda')
        self.assertEqual(old[0]['title'], 'old')

    def test_duplicate_in_same_supplement_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'duplicate ID china-food'):
            upsert_records([], [{'id': 'china-food'}, {'id': 'china-food'}],
                           source='china.json', kind='articles')

    def test_partial_country_patch_preserves_other_sections_and_refreshes_source(self):
        old = {'id': 'china', 'sections': {'nature': ['panda'], 'food': []},
               'sources': [{'url': 'https://example.org/fact', 'checkedAt': 'old'}]}
        patch = {'id': 'china', 'sections': {'food': ['tea']},
                 'sources': [{'url': 'https://example.org/fact', 'checkedAt': 'new'}]}
        result = merge_country(old, patch)
        self.assertEqual(result['sections'], {'nature': ['panda'], 'food': ['tea']})
        self.assertEqual(result['sources'], [{'url': 'https://example.org/fact', 'checkedAt': 'new'}])
        self.assertEqual(old['sections']['food'], [])

    def test_archive_removes_active_item_but_retains_migration_record(self):
        active = [{'id': 'china-canal'}, {'id': 'china-transport'}]
        archive = [{'id': 'china-transport', 'articleId': 'china-canal-history'}]
        self.assertEqual(archive_exercises(active, archive), [{'id': 'china-canal'}])
        self.assertEqual(archive[0]['articleId'], 'china-canal-history')


class ChinaEditorialTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = json.loads((Path(__file__).parent / 'editorial/china.json').read_text())
        cls.valid = {'countries': [source['country']], 'articles': source['articles'],
                     'exercises': source['exercises'], 'archivedExercises': source['archivedExercises']}

    def test_complete_pack_meets_editorial_acceptance(self):
        self.assertEqual(validate_china(self.valid), [])

    def test_wrong_article_evidence_is_rejected(self):
        changed = deepcopy(self.valid)
        changed['exercises'][0]['evidenceBlockIds'] = ['china-nature-r2-b1']
        self.assertTrue(any('evidence in its own article' in e for e in validate_china(changed)))

    def test_open_activity_cannot_also_count_as_closed_question(self):
        changed = deepcopy(self.valid)
        a = next(a for a in changed['articles'] if a.get('activity'))
        a['exerciseId'] = changed['exercises'][0]['id']
        self.assertTrue(any('exactly one core activity' in e for e in validate_china(changed)))

    def test_short_placeholder_body_cannot_pass_as_complete_article(self):
        changed = deepcopy(self.valid)
        changed['articles'][0]['blocks'] = [{'id': 'placeholder', 'title': '标题', 'text': '待补充'}]
        failures = validate_china(changed)
        self.assertTrue(any('450–650' in e for e in failures))
        self.assertTrue(any('4–6' in e for e in failures))

    def test_map_answer_must_match_real_feature_option(self):
        changed = deepcopy(self.valid)
        e = next(e for e in changed['exercises'] if e['type'] == 'location')
        e['mapFeatureId'] = 'wrong-feature'
        self.assertTrue(any('map answer mismatch' in e for e in validate_china(changed)))


if __name__ == '__main__':
    unittest.main()
