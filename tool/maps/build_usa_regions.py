#!/usr/bin/env python3
"""Project Census state boundaries and Natural Earth waters for the offline USA atlas.

Pass the official 2025 1:20m state, 1:10m river and 1:10m lake zip files in that
order. Optionally pass a BMP of the WGS84 NASA Blue Marble raster (sips -s
format bmp) to rebuild each projected shaded-relief asset. Output units are km
with y increasing southward to match the Flutter canvas.
"""
import argparse
from bisect import bisect_left
from collections import defaultdict
import hashlib
import json
from math import atan2, cos, degrees, hypot, log, radians, sin, sqrt
from pathlib import Path
import struct
import subprocess
import tempfile
import zipfile

from build_china_rivers import polylines
from build_detail import ROOT, area, dbf_records, polygons, shapefile_rings

OUT = ROOT / 'assets/atlas'
CENSUS = 'https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.2025.html'
NE = 'https://www.naturalearthdata.com/downloads/10m-physical-vectors/'
NASA = 'https://science.nasa.gov/earth/earth-observatory/blue-marble-next-generation/'
STATES = dict(zip(
    'AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY'.split(),
    '亚拉巴马 阿拉斯加 亚利桑那 阿肯色 加利福尼亚 科罗拉多 康涅狄格 特拉华 华盛顿特区 佛罗里达 佐治亚 夏威夷 爱达荷 伊利诺伊 印第安纳 艾奥瓦 堪萨斯 肯塔基 路易斯安那 缅因 马里兰 马萨诸塞 密歇根 明尼苏达 密西西比 密苏里 蒙大拿 内布拉斯加 内华达 新罕布什尔 新泽西 新墨西哥 纽约 北卡罗来纳 北达科他 俄亥俄 俄克拉何马 俄勒冈 宾夕法尼亚 罗得岛 南卡罗来纳 南达科他 田纳西 得克萨斯 犹他 佛蒙特 弗吉尼亚 华盛顿 西弗吉尼亚 威斯康星 怀俄明'.split(),
    strict=True))
LAKES = {
    'Q1066': ('superior', '苏必利尔湖'), 'Q1169': ('michigan', '密歇根湖'),
    'Q1383': ('huron', '休伦湖'), 'Q5492': ('erie', '伊利湖'),
    'Q1062': ('ontario', '安大略湖'),
}
RIVERS = {'Q270627': ('colorado-river', '科罗拉多河'), 'Q1497': ('mississippi-river', '密西西比河')}


class Projection:
    """NAD83 Albers parameters for EPSG:5070 and EPSG:3338, at atlas precision."""
    radius = 6378.137
    e2 = 0.0066943800229
    e = sqrt(e2)

    def __init__(self, center, origin, parallels=None):
        self.center, self.origin = center, origin
        self.factor = cos(radians(origin))
        self.parallels = parallels
        if parallels:
            p1, p2 = map(radians, parallels)
            m1 = cos(p1) ** 2 / (1 - self.e2 * sin(p1) ** 2)
            m2 = cos(p2) ** 2 / (1 - self.e2 * sin(p2) ** 2)
            q1, q2 = self.q(sin(p1)), self.q(sin(p2))
            self.n = (m1 - m2) / (q2 - q1)
            self.c = m1 + self.n * q1
            self.r0 = self.rho(origin)
            self.latitudes = [i / 80 for i in range(-7200, 7201)]
            self.q_table = [self.q(sin(radians(p))) for p in self.latitudes]

    def q(self, s):
        return (1 - self.e2) * (s / (1 - self.e2 * s * s) -
                                 log((1 - self.e * s) / (1 + self.e * s)) / (2 * self.e))

    def rho(self, lat):
        return self.radius * sqrt(self.c - self.n * self.q(sin(radians(lat)))) / self.n

    def project(self, lon, lat):
        d = radians((lon - self.center + 180) % 360 - 180)
        if not self.parallels:
            return [self.radius * d * self.factor, self.radius * radians(self.origin - lat)]
        rho = self.rho(lat)
        return [rho * sin(self.n * d), rho * cos(self.n * d) - self.r0]

    def inverse(self, x, y):
        if not self.parallels:
            return self.center + degrees(x / self.radius / self.factor), self.origin - degrees(y / self.radius)
        r = hypot(x, y + self.r0)
        q = (self.c - (r * self.n / self.radius) ** 2) / self.n
        i = max(1, min(len(self.q_table) - 1, bisect_left(self.q_table, q)))
        a, b = self.q_table[i-1:i+1]
        latitude = self.latitudes[i-1] + (q - a) / (b - a) / 80
        return self.center + degrees(atan2(x, y + self.r0) / self.n), latitude


PROJECTIONS = {
    'conus': Projection(-96, 23, (29.5, 45.5)),
    'ak': Projection(-154, 50, (55, 65)),
    'hi': Projection(-157.5, 20.5),
}


def read(archive_path, prefix, parser):
    with zipfile.ZipFile(archive_path) as archive:
        attrs = [{k: v.strip('\x00 ') for k, v in row.items()} if row else {}
                 for row in dbf_records(archive.read(prefix + '.dbf'))]
        shapes = parser(archive.read(prefix + '.shp'))
    if len(attrs) != len(shapes):
        raise ValueError(f'{prefix} attributes and geometry are misaligned')
    return zip(attrs, shapes)


def projected(lines, projection):
    return [[round(x, 3), round(y, 3)] for lon, lat in lines for x, y in [projection.project(lon, lat)]]


def project_polygons(shapes, projection):
    return [[projected(ring, projection) for ring in poly] for poly in shapes]


def bounds(points):
    xs, ys = zip(*points)
    return [min(xs), min(ys), max(xs), max(ys)]


def extent(box, horizontal, vertical):
    l, t, r, b = box
    return [l-horizontal, t-vertical, r+horizontal, b+vertical]


def feature(fid, name, kind, geometry, coordinates, **extra):
    return dict(type='Feature', properties=dict(id=fid, name=name, kind=kind, **extra),
                geometry=dict(type=geometry, coordinates=coordinates))


def source(archive, title, url):
    return dict(title=title, url=url, archive=archive.name,
                sha256=hashlib.sha256(archive.read_bytes()).hexdigest(), license='Public domain')


def assemble(states, rivers, lakes):
    regions = defaultdict(list)
    for row, rings in read(states, 'cb_2025_us_state_20m', shapefile_rings):
        code = row.get('STUSPS')
        if code not in STATES:
            continue
        district = code == 'DC'
        region = {'AK': 'ak', 'HI': 'hi'}.get(code, 'conus')
        name = STATES[code] + ('' if district else '州')
        shape = project_polygons(polygons(rings), PROJECTIONS[region])
        regions[region].append(feature(
            f"usa-{'district' if district else 'state'}-{row['STATEFP']}", name,
            'district' if district else 'state', 'MultiPolygon', shape,
            code=code, english=row['NAME'] + ('' if district else ' State'),
            aliases=(['Washington', 'Washington DC', 'D.C.', '首都', '华盛顿'] if district
                     else [row['NAME'], STATES[code], *({'TX': ['德克萨斯'], 'CA': ['加州'],
                           'AL': ['阿拉巴马'], 'NY': ['纽约州'], 'WA': ['美国西北部']}.get(code, []))])))
    if {k: len(v) for k, v in regions.items()} != {'conus': 49, 'ak': 1, 'hi': 1}:
        raise ValueError('State and federal district coverage changed')
    projection = PROJECTIONS['conus']
    grouped, segments = defaultdict(list), defaultdict(list)
    for row, lines in read(rivers, 'ne_10m_rivers_lake_centerlines', polylines):
        qid = row.get('wikidataid')
        if qid in RIVERS and lines:
            grouped[qid].extend(projected(line, projection) for line in lines)
            segments[qid].append(row['ne_id'])
    for qid, (key, name) in RIVERS.items():
        if sum(map(len, grouped[qid])) < 100:
            raise ValueError(f'Insufficient river detail for {name}')
        regions['conus'].append(feature('usa-feature-'+key, name, 'river', 'MultiLineString', grouped[qid],
                                        segments=segments[qid], english=key.replace('-', ' ').title()))
    for row, rings in read(lakes, 'ne_10m_lakes', shapefile_rings):
        qid = row.get('wikidataid')
        if qid not in LAKES:
            continue
        key, name = LAKES[qid]
        regions['conus'].append(feature('usa-feature-lake-'+key, name, 'lake', 'MultiPolygon',
                                        project_polygons(polygons(rings), projection),
                                        english=row['name_en'], sourceId=row['ne_id']))
    if sum(f['properties']['kind'] == 'lake' for f in regions['conus']) != 5:
        raise ValueError('Expected five Great Lakes')
    sources = [source(states, '美国人口普查局 · 2025 年州级制图边界 1:20m', CENSUS),
               source(rivers, 'Natural Earth 1:10m 河流与湖中心线', NE+'10m-rivers-lake-centerlines/'),
               source(lakes, 'Natural Earth 1:10m 湖泊', NE+'10m-lakes/')]
    output = {}
    for key, features in regions.items():
        features.sort(key=lambda f: f['properties']['id'])
        all_points = [p for f in features if f['properties']['kind'] in {'state', 'district', 'lake'}
                      for poly in f['geometry']['coordinates'] for ring in poly for p in ring]
        box = bounds(all_points)
        pad = 110 if key == 'conus' else 35
        camera = extent(box, pad, pad)
        raster = extent(camera, 1600 if key == 'conus' else 900 if key == 'ak' else 340,
                        1000 if key != 'hi' else 280)
        output[key] = dict(type='FeatureCollection', region=key,
                           projection={'conus':'EPSG:5070','ak':'EPSG:3338','hi':'local-equirectangular'}[key],
                           bounds=camera, reliefBounds=raster, features=features)
    return dict(schemaVersion=1, sources=sources,
                terrain=dict(title='NASA Blue Marble 地形底图', url=NASA, original='earth-relief.jpg',
                             transform='Inverse projected, luminance tinted, resampled'),
                regions=output)


class Bmp:
    def __init__(self, path):
        self.data = path.read_bytes()
        self.offset = struct.unpack_from('<I', self.data, 10)[0]
        self.w, height, _, bits, compression = struct.unpack_from('<iiHHI', self.data, 18)
        if self.data[:2] != b'BM' or bits not in {24, 32} or compression != 0:
            raise ValueError('Expected a 24-bit or 32-bit uncompressed BMP')
        self.bottom_up = height > 0
        self.h, self.bytes = abs(height), bits // 8
        self.stride = (self.w * self.bytes + 3) & ~3

    def pixel(self, longitude, latitude):
        col = min(self.w-1, int(((longitude+180) % 360) / 360 * self.w))
        row = max(0, min(self.h-1, int((90-latitude) / 180 * self.h)))
        if self.bottom_up:
            row = self.h-1-row
        i = self.offset + row*self.stride + col*self.bytes
        return self.data[i:i+3]


def render_relief(raw, output):
    bmp = Bmp(raw)
    with tempfile.TemporaryDirectory() as tmp:
        for key, region in output['regions'].items():
            x0, y0, x1, y1 = region['reliefBounds']
            width = {'conus': 1450, 'ak': 1100, 'hi': 900}[key]
            height = round(width*(y1-y0)/(x1-x0))
            stride = (width*3 + 3) & ~3
            pixels = bytearray(stride*height)
            proj = PROJECTIONS[key]
            for row in range(height):
                y = y1 - (row+.5)*(y1-y0)/height
                for col in range(width):
                    x = x0 + (col+.5)*(x1-x0)/width
                    blue, green, red = bmp.pixel(*proj.inverse(x, y))
                    if blue > red * 1.14 and blue > green * 1.04:
                        color = (236, 213, 167)  # BGR atlas water
                    else:
                        color = (min(240, int(94 + blue*.62)),
                                 min(242, int(126 + green*.55)),
                                 min(244, int(104 + red*.70)))
                    at = row*stride+col*3
                    pixels[at:at+3] = bytes(color)
            info = struct.pack('<IiiHHIIiiII', 40, width, height, 1, 24, 0, len(pixels), 0, 0, 0, 0)
            path = Path(tmp)/f'{key}.bmp'
            path.write_bytes(b'BM'+struct.pack('<III',54+len(pixels),0,54)+info+pixels)
            subprocess.run(['sips','-s','format','jpeg','-s','formatOptions','86',str(path),
                            '--out',str(OUT/f'usa-relief-{key}.jpg')], check=True, capture_output=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('states', 'rivers', 'lakes'):
        parser.add_argument(name, type=Path)
    parser.add_argument('--relief-bmp', type=Path)
    args = parser.parse_args()
    data = assemble(args.states, args.rivers, args.lakes)
    if args.relief_bmp:
        render_relief(args.relief_bmp, data)
    (OUT/'usa-regions.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':'))+'\n')
    print({key: len(region['features']) for key, region in data['regions'].items()})


if __name__ == '__main__':
    main()
