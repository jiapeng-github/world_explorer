"""Extract Egyptian water features from the Natural Earth 1:10m archive."""

import argparse
import hashlib
import json
import zipfile
from pathlib import Path

from build_china_rivers import polylines
from build_detail import dbf_records


SOURCE = 'https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/'
FEATURES = {
    'egypt-nile': ('尼罗河', 'river', {'1159121589', '1159121573'}),
    'egypt-delta-rosetta': ('罗塞塔支流', 'river', {'1159113693'}),
    'egypt-delta-damietta': ('达米埃塔支流', 'river', {'1159113949'}),
    'egypt-suez-waterway': ('苏伊士运河', 'canal', {'1159113913', '1159113931'}),
}


def extract(archive_path):
    prefix = 'ne_10m_rivers_lake_centerlines'
    with zipfile.ZipFile(archive_path) as archive:
        records = dbf_records(archive.read(prefix + '.dbf'))
        shapes = polylines(archive.read(prefix + '.shp'))
        version = archive.read(prefix + '.VERSION.txt').decode().strip()
    if len(records) != len(shapes):
        raise ValueError('Natural Earth attributes and geometry do not align')
    by_id = {row['ne_id'].strip('\x00 '): (row, lines)
             for row, lines in zip(records, shapes) if row and lines}
    features = []
    for key, (name, kind, ids) in FEATURES.items():
        coordinates, segments = [], []
        for source_id in sorted(ids):
            row, lines = by_id[source_id]
            coordinates.extend(lines)
            segments.append({'neId': source_id, 'name': row['name'].strip('\x00 '),
                             'featureClass': row['featurecla'].strip('\x00 ')})
        features.append({'type': 'Feature',
                         'properties': {'id': key, 'name': name, 'kind': kind,
                                        'segments': segments},
                         'geometry': {'type': 'MultiLineString', 'coordinates': coordinates}})
    return {'type': 'FeatureCollection', 'source': 'Natural Earth 1:10m rivers and lake centerlines',
            'sourceUrl': SOURCE, 'sourceVersion': version,
            'downloadUrl': 'https://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_lake_centerlines.zip',
            'sourceArchiveSha256': hashlib.sha256(archive_path.read_bytes()).hexdigest(),
            'license': 'Public domain', 'checkedAt': '2026-11-08', 'features': features}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[2]
                        / 'assets/atlas/egypt-waterways.geojson')
    args = parser.parse_args()
    data = extract(args.archive)
    args.output.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n')
    print({f['properties']['id']: sum(map(len, f['geometry']['coordinates'])) for f in data['features']})
