"""Extract Orange and Limpopo without inventing or joining river geometry."""
import hashlib,json,sys,zipfile
from pathlib import Path
from build_detail import dbf_records
from build_china_rivers import polylines
root=Path(__file__).resolve().parents[2]
archive=Path(sys.argv[1]);prefix='ne_10m_rivers_lake_centerlines'
with zipfile.ZipFile(archive) as z:
 rows=dbf_records(z.read(prefix+'.dbf'));shapes=polylines(z.read(prefix+'.shp'))
features=[]
for qid,slug,name in [('Q181475','orange','奥兰治河'),('Q173017','limpopo','林波波河')]:
 lines=[line for r,parts in zip(rows,shapes) if r and r.get('wikidataid','').strip('\x00 ')==qid for line in parts]
 assert lines
 features.append(dict(type='Feature',properties=dict(id='zaf-'+slug,name=name,kind='river'),geometry=dict(type='MultiLineString',coordinates=lines)))
output=dict(type='FeatureCollection',features=features,sourceUrl='https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/',license='Public domain',sourceArchiveSha256=hashlib.sha256(archive.read_bytes()).hexdigest(),note='保留源数据的跨境河道原段，不裁成国界，不用于现场导航。')
(root/'assets/atlas/zaf-rivers.geojson').write_text(json.dumps(output,ensure_ascii=False,separators=(',',':'))+'\n')
print([(f['properties']['id'],sum(map(len,f['geometry']['coordinates']))) for f in features])
