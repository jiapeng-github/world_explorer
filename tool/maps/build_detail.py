#!/usr/bin/env python3
"""Convert official Natural Earth 1:50m country polygons to our stable country IDs.

Usage: python3 tool/maps/build_detail.py /tmp/ne_50m_admin_0_countries.zip
Only Python's standard library is required. The input archive is read in place;
it is never extracted into the repository. Output retains 110m fallback features
if an existing catalog entity is absent at this scale, and reports those IDs.
"""
import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def dbf_records(data):
    count = struct.unpack_from('<I', data, 4)[0]
    header, record_size = struct.unpack_from('<HH', data, 8)
    fields, position = [], 32
    while data[position] != 0x0D:
        name = data[position:position + 11].split(b'\0')[0].decode('ascii')
        fields.append((name, data[position + 16]))
        position += 32
    records = []
    for index in range(count):
        start = header + index * record_size
        raw = data[start:start + record_size]
        if not raw or raw[0] == ord('*'):
            records.append(None)
            continue
        record, position = {}, 1
        for name, length in fields:
            record[name] = raw[position:position + length].decode('utf-8').strip()
            position += length
        records.append(record)
    return records


def shapefile_rings(data):
    if struct.unpack_from('>I', data)[0] != 9994:
        raise ValueError('Not a shapefile')
    position, shapes = 100, []
    while position < len(data):
        _, words = struct.unpack_from('>II', data, position)
        raw = data[position + 8:position + 8 + words * 2]
        shape_type = struct.unpack_from('<I', raw)[0]
        position += 8 + words * 2
        if shape_type == 0:
            shapes.append([])
            continue
        if shape_type != 5:
            raise ValueError(f'Expected polygon geometry, found type {shape_type}')
        part_count, point_count = struct.unpack_from('<II', raw, 36)
        parts = list(struct.unpack_from(f'<{part_count}I', raw, 44)) + [point_count]
        points_start = 44 + 4 * part_count
        points = []
        for index in range(point_count):
            x, y = struct.unpack_from('<dd', raw, points_start + 16 * index)
            if not math.isfinite(x) or not math.isfinite(y) or abs(x) > 180.00001 or abs(y) > 90.00001:
                raise ValueError('Invalid WGS84 coordinate')
            points.append([round(x, 5), round(y, 5)])
        rings = []
        for start, end in zip(parts, parts[1:]):
            ring = []
            for point in points[start:end]:
                if not ring or point != ring[-1]:
                    ring.append(point)
            if ring and ring[0] != ring[-1]:
                ring.append(ring[0])
            if len(ring) >= 4:
                rings.append(ring)
        shapes.append(rings)
    return shapes


def area(ring):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(ring, ring[1:])) / 2


def contains(ring, point):
    x, y = point
    inside = False
    for a, b in zip(ring, ring[1:]):
        if (a[1] > y) != (b[1] > y) and x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]:
            inside = not inside
    return inside


def polygons(rings):
    # ESRI outer rings are clockwise. GeoJSON's right-hand rule is the reverse.
    outer = [r for r in rings if area(r) < 0]
    holes = [r for r in rings if area(r) >= 0]
    result = [[list(reversed(r))] for r in outer]
    for hole in holes:
        candidates = [i for i, ring in enumerate(outer) if contains(ring, hole[0])]
        if not candidates:
            raise ValueError('Interior polygon ring has no containing outer ring')
        index = min(candidates, key=lambda i: abs(area(outer[i])))
        result[index].append(list(reversed(hole)))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'assets/atlas/countries-detail.geojson')
    args = parser.parse_args()
    prefix = 'ne_50m_admin_0_countries'
    with zipfile.ZipFile(args.archive) as archive:
        records = dbf_records(archive.read(prefix + '.dbf'))
        shapes = shapefile_rings(archive.read(prefix + '.shp'))
        version = archive.read(prefix + '.VERSION.txt').decode().strip()
    if len(records) != len(shapes):
        raise ValueError('Geometry and attribute record counts differ')
    detailed = defaultdict(list)
    for record, rings in zip(records, shapes):
        if record and rings:
            detailed[record['ADM0_A3']].extend(polygons(rings))
    # Keep the product's China grouping when rebuilding finer geometry.
    detailed['CHN'].extend(detailed.get('TWN', []))
    base = json.loads((ROOT / 'assets/atlas/countries.geojson').read_text())
    features, fallback = [], []
    for feature in base['features']:
        code = feature['properties']['code']
        if code in detailed:
            feature['geometry'] = {'type': 'MultiPolygon', 'coordinates': detailed[code]}
            feature['properties']['scale'] = '50m'
        else:
            fallback.append(feature['properties']['id'])
            feature['properties']['scale'] = '110m'
        features.append(feature)
    output = {
        'type': 'FeatureCollection',
        'source': 'Natural Earth admin 0 countries',
        'sourceUrl': 'https://www.naturalearthdata.com/downloads/50m-cultural-vectors/50m-admin-0-countries-2/',
        'sourceVersion': version,
        'sourceArchiveSha256': hashlib.sha256(args.archive.read_bytes()).hexdigest(),
        'license': 'Public domain',
        'fallbackIds': fallback,
        'features': features,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, separators=(',', ':')) + '\n')
    print(json.dumps({'output': str(args.output), 'features': len(features), 'detailed': len(features) - len(fallback),
                      'fallbackIds': fallback, 'bytes': args.output.stat().st_size, 'version': version}, ensure_ascii=False))


if __name__ == '__main__':
    main()
