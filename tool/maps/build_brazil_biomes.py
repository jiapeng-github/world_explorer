"""Convert IBGE 2019 biomes, preserving shared borders through coverage simplification.

Requires shapely>=2.1 and pyproj. Input: official Biomas_250mil.zip.
SIRGAS 2000 coordinates are transformed to WGS84; output is for national learning maps.
"""
import hashlib
import json
from pathlib import Path
import sys
import struct
import zipfile

from pyproj import Transformer
from shapely import coverage_is_valid, coverage_simplify, set_precision
from shapely.geometry import mapping, shape
from shapely.ops import transform
from build_detail import dbf_records, polygons

def shapefile_rings(data):
    result, position = [], 100
    while position < len(data):
        _, words = struct.unpack_from('>II', data, position)
        raw = data[position + 8:position + 8 + words * 2]
        position += 8 + words * 2
        assert struct.unpack_from('<I', raw)[0] == 5
        count, points = struct.unpack_from('<II', raw, 36)
        parts = list(struct.unpack_from(f'<{count}I', raw, 44)) + [points]
        coordinates = list(struct.iter_unpack('<dd', raw[44 + 4 * count:44 + 4 * count + 16 * points]))
        result.append([coordinates[a:b] for a,b in zip(parts, parts[1:])])
    return result

ROOT = Path(__file__).resolve().parents[2]
archive = Path(sys.argv[1])
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert 'SIRGAS_2000' in z.read('lm_bioma_250.prj').decode()
    rows = dbf_records(z.read('lm_bioma_250.dbf'))
    rings = shapefile_rings(z.read('lm_bioma_250.shp'))
geometries = [shape(dict(type='MultiPolygon', coordinates=polygons(r))) for r in rings]
assert all(g.is_valid for g in geometries), 'Invalid source polygon'
geometries = [set_precision(g, 0.00001) for g in geometries]
assert coverage_is_valid(geometries), 'Source has overlapping regions'
simplified = coverage_simplify(geometries, tolerance=.015)
assert coverage_is_valid(simplified)
project = Transformer.from_crs('EPSG:4674', 'EPSG:4326', always_xy=True).transform
names = {'1':('amazon','亚马孙'), '2':('caatinga','卡廷加'), '3':('cerrado','塞拉多'),
         '4':('atlantic','大西洋森林'), '5':('pampa','潘帕'), '6':('pantanal','潘塔纳尔')}
features = []
for row, original, reduced in zip(rows, geometries, simplified):
    assert abs(reduced.area - original.area) / original.area < .01
    slug, name = names[row['CD_Bioma']]
    features.append(dict(type='Feature', properties=dict(id=f'brazil-biome-{slug}', name=name,
        sourceName=row['Bioma'], sourceCode=row['CD_Bioma']), geometry=mapping(transform(project, reduced))))
out = dict(type='FeatureCollection', features=features, source='IBGE · Biomas e Sistema Costeiro-Marinho 2019',
    sourceUrl='https://www.ibge.gov.br/geociencias/cartas-e-mapas/informacoes-ambientais/15842-biomas.html',
    downloadUrl='https://geoftp.ibge.gov.br/informacoes_ambientais/estudos_ambientais/biomas/vetores/Biomas_250mil.zip',
    sourceArchiveSha256=hashlib.sha256(archive.read_bytes()).hexdigest(), sourceYear=2019,
    sourceCrs='EPSG:4674', outputCrs='EPSG:4326', sourceScale='1:250000',
    processing='Snap to 0.00001 degree grid to repair tiny source overlaps; Shapely coverage_simplify 0.015 degrees, shared boundaries preserved; SIRGAS 2000 to WGS84.',
    note='全国学习图；生态区不等于现存植被覆盖，不用于导航。采用2019版，不代表最新修订。')
path=ROOT/'assets/atlas/brazil-biomes.geojson'
path.write_text(json.dumps(out, ensure_ascii=False, separators=(',',':'))+'\n')
print('biomes',len(features),'bytes',path.stat().st_size)
