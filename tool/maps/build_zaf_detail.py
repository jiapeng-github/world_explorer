"""Build a regional 1:10m layer, retaining source enclaves and neighbouring states."""
import sys,json,zipfile,hashlib
from pathlib import Path
from build_detail import dbf_records,shapefile_rings,polygons
root=Path(__file__).resolve().parents[2];archive=Path(sys.argv[1]);prefix='ne_10m_admin_0_countries'
with zipfile.ZipFile(archive) as z:
 rows=dbf_records(z.read(prefix+'.dbf'));rings=shapefile_rings(z.read(prefix+'.shp'))
ids={c['code']:c['id'] for c in json.loads((root/'assets/atlas/countries.geojson').read_text())['features'] for c in [c['properties']]}
selected={'ZAF','LSO','SWZ','NAM','BWA','ZWE','MOZ'}
features=[dict(type='Feature',properties=dict(id=ids[r['ADM0_A3']],code=r['ADM0_A3'],scale='10m'),geometry=dict(type='MultiPolygon',coordinates=polygons(s))) for r,s in zip(rows,rings) if r and r['ADM0_A3'] in selected]
assert len(features)==7
out=dict(type='FeatureCollection',features=features,sourceUrl='https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-countries/',sourceArchiveSha256=hashlib.sha256(archive.read_bytes()).hexdigest(),license='Public domain',note='原始多边形含内环，保留莱索托、埃斯瓦蒂尼及跨境地理关系。')
(root/'assets/atlas/zaf-countries-detail.geojson').write_text(json.dumps(out,ensure_ascii=False,separators=(',',':'))+'\n');print(len(features))
