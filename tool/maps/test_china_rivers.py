import json
from pathlib import Path
import unittest


class ChinaRiversTest(unittest.TestCase):
    def test_source_geometry_is_continuous_only_within_real_parts(self):
        path = Path(__file__).resolve().parents[2] / 'assets/atlas/china-rivers.geojson'
        data = json.loads(path.read_text())
        self.assertEqual({f['properties']['id'] for f in data['features']}, {'yangtze', 'yellow-river'})
        self.assertEqual(len(data['sourceArchiveSha256']), 64)
        for feature in data['features']:
            self.assertEqual(feature['geometry']['type'], 'MultiLineString')
            lines = feature['geometry']['coordinates']
            self.assertGreater(sum(map(len, lines)), 1000)
            for line in lines:
                self.assertGreaterEqual(len(line), 2)
                for lon, lat in line:
                    self.assertTrue(85 < lon < 125 and 20 < lat < 45)
                # No joining the mouth to the source or bridging missing parts.
                for a, b in zip(line, line[1:]):
                    self.assertLess(abs(a[0] - b[0]) + abs(a[1] - b[1]), 2)


if __name__ == '__main__':
    unittest.main()
