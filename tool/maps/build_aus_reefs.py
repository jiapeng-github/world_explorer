"""Keep original NE 1:10m reef linework in the NE Australian coastal window.
This is mapped reef distribution, NOT the GBR Marine Park administrative boundary.
"""
import hashlib,json,sys,zipfile
from pathlib import Path
from build_china_rivers import polylines
ROOT=Path(__file__).resolve().parents[2]
p=Path(sys.argv[1])
with zipfile.ZipFile(p) as z:
 rings=polylines(z.read('ne_10m_reefs.shp'));version=z.read('ne_10m_reefs.VERSION.txt').decode().strip()
coords=[]
for rs in rings:
 if not rs:continue
 points=[p for r in rs for p in r]
 if all(142<=x<=154 and -24.5<=y<=-10.5 for x,y in points):coords.extend(rs)
assert len(coords)>10
j=dict(type='FeatureCollection',features=[dict(type='Feature',properties=dict(id='aus-reef-distribution',name='东北沿海礁体分布'),geometry=dict(type='MultiLineString',coordinates=coords))],sourceUrl='https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-reefs/',sourceVersion=version,license='Public domain',sourceArchiveSha256=hashlib.sha256(p.read_bytes()).hexdigest(),selectionWindow=[142,-24.5,154,-10.5],note='仅保留选定视窗内的原始礁体线段；不是海洋公园边界，不表示实时健康状况。')
(ROOT/'assets/atlas/aus-reefs.geojson').write_text(json.dumps(j,ensure_ascii=False,separators=(',',':'))+'\n')
print(len(coords),'source reef linework')
