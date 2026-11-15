#!/usr/bin/env python3
"""Extract named Yangtze/Jinsha and Yellow River geometry from Natural Earth.

Usage: python3 tool/maps/build_china_rivers.py ARCHIVE.zip
Reads official SHP/DBF without third-party dependencies; does not join gaps.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import zipfile

from build_detail import dbf_records

ROOT = Path(__file__).resolve().parents[2]


def polylines(data):
    if struct.unpack_from('>I', data)[0] != 9994:
        raise ValueError('Not a shapefile')
    offset, output = 100, []
    while offset < len(data):
        _, words = struct.unpack_from('>II', data, offset)
        raw = data[offset + 8:offset + 8 + words * 2]
        offset += 8 + words * 2
        kind = struct.unpack_from('<I', raw)[0]
        if kind == 0:
            output.append([])
            continue
        if kind != 3:
            raise ValueError(f'Expected polyline, got {kind}')
        n_parts, n_points = struct.unpack_from('<II', raw, 36)
        parts = list(struct.unpack_from(f'<{n_parts}I', raw, 44)) + [n_points]
        start = 44 + 4 * n_parts
        points = []
        for i in range(n_points):
            lon, lat = struct.unpack_from('<dd', raw, start + i * 16)
            if not math.isfinite(lon + lat) or abs(lon) > 180 or abs(lat) > 90:
                raise ValueError('Invalid coordinate')
            points.append([round(lon, 5), round(lat, 5)])
        output.append([points[a:b] for a, b in zip(parts, parts[1:]) if b - a >= 2])
    return output


def extract(archive_path):
    prefix = 'ne_10m_rivers_lake_centerlines'
    with zipfile.ZipFile(archive_path) as archive:
        records = dbf_records(archive.read(prefix + '.dbf'))
        shapes = polylines(archive.read(prefix + '.shp'))
        version = archive.read(prefix + '.VERSION.txt').decode().strip()
    assert len(records) == len(shapes)
    by_id = {'yangtze': [], 'yellow-river': []}
    names = {k: [] for k in by_id}
    for record, lines in zip(records, shapes):
        if record is None:
            continue
        record = {k: v.strip('\x00 ') for k, v in record.items()}
        qid = record.get('wikidataid')
        target = 'yangtze' if qid in ('Q5413', 'Q1038418') else 'yellow-river' if qid == 'Q7355' else None
        if target:
            by_id[target].extend(lines)
            names[target].append({'name': record['name'], 'neId': record['ne_id']})
    features = []
    for key, lines in by_id.items():
        if sum(map(len, lines)) < 100:
            raise ValueError(f'Missing detailed geometry for {key}')
        features.append({'type': 'Feature', 'properties': {
            'id': key, 'name': '长江' if key == 'yangtze' else '黄河',
            'segments': names[key],
            'note': '保留数据源各段；长江包括金沙江段，不跨缺口补线。',
        }, 'geometry': {'type': 'MultiLineString', 'coordinates': lines}})
    return {'type': 'FeatureCollection', 'source': 'Natural Earth 1:10m rivers and lake centerlines',
            'sourceUrl': 'https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/',
            'downloadUrl': 'https://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_lake_centerlines.zip',
            'sourceVersion': version, 'sourceArchiveSha256': hashlib.sha256(Path(archive_path).read_bytes()).hexdigest(),
            'license': 'Public domain', 'checkedAt': '2026-11-07', 'features': features}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'assets/atlas/china-rivers.geojson')
    args = parser.parse_args()
    result = extract(args.archive)
    args.output.write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n')
    print({f['properties']['id']: sum(len(line) for line in f['geometry']['coordinates']) for f in result['features']})
