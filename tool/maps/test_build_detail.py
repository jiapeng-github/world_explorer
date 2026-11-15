import json
import unittest

from build_detail import ROOT, area, polygons


class DetailMapChecks(unittest.TestCase):
    def test_inner_ring_stays_with_its_outer_polygon(self):
        outer = [[0, 0], [0, 10], [10, 10], [10, 0], [0, 0]]
        hole = [[2, 2], [4, 2], [4, 4], [2, 4], [2, 2]]
        result = polygons([outer, hole])
        self.assertEqual(len(result), 1)
        self.assertEqual(len(result[0]), 2)
        self.assertGreater(area(result[0][0]), 0)
        self.assertLess(area(result[0][1]), 0)

    def test_orphan_hole_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'no containing'):
            polygons([[[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]]])

    def test_details_preserve_all_catalog_ids_and_have_closed_rings(self):
        base = json.loads((ROOT / 'assets/atlas/countries.geojson').read_text())
        detail = json.loads((ROOT / 'assets/atlas/countries-detail.geojson').read_text())
        self.assertEqual({f['properties']['id'] for f in base['features']},
                         {f['properties']['id'] for f in detail['features']})
        self.assertEqual(detail['fallbackIds'], [])
        for feature in detail['features']:
            self.assertEqual(feature['geometry']['type'], 'MultiPolygon')
            for polygon in feature['geometry']['coordinates']:
                for ring in polygon:
                    self.assertGreaterEqual(len(ring), 4)
                    self.assertEqual(ring[0], ring[-1])
                    self.assertTrue(all(-180 <= x <= 180 and -90 <= y <= 90 for x, y in ring))


if __name__ == '__main__':
    unittest.main()
