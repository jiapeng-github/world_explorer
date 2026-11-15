"""Select three named Japanese rivers from Natural Earth 1:10m GeoJSON.
Usage: python3 tool/maps/build_japan_rivers.py INPUT.geojson
Preserves source vertices and disjoint segments; does not invent tributaries.
"""
import hashlib,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=Path(sys.argv[1]);j=json.loads(p.read_text());features=[]
for f in j['features']:
 name=f['properties'].get('name')
 if name not in ['Ishikari','Tone','Mogami']:continue
 g=f['geometry'];lines=g['coordinates'] if g['type']=='MultiLineString' else [g['coordinates']]
 features.append(dict(type='Feature',properties=dict(id='japan-river-'+name.lower(),name={'Ishikari':'石狩川','Tone':'利根川','Mogami':'最上川'}[name],neId=f['properties'].get('ne_id')),geometry=dict(type='MultiLineString',coordinates=lines)))
assert len(features)==3
result=dict(type='FeatureCollection',source='Natural Earth 1:10m rivers and lake centerlines',sourceUrl='https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/',downloadUrl='https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_rivers_lake_centerlines.geojson',sourceSha256=hashlib.sha256(p.read_bytes()).hexdigest(),license='Public domain',checkedAt='2026-11-11',features=features)
(root/'assets/atlas/japan-rivers.geojson').write_text(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n')
print('Japan rivers:',len(features),'features')
