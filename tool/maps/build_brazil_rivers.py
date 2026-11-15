"""Extract source river segments without inventing connecting geometry."""
import json,sys,zipfile,hashlib
from pathlib import Path
from build_detail import dbf_records
from build_china_rivers import polylines
root=Path(__file__).resolve().parents[2];archive=Path(sys.argv[1]);prefix='ne_10m_rivers_lake_centerlines'
with zipfile.ZipFile(archive) as z:
 records=dbf_records(z.read(prefix+'.dbf'));shapes=polylines(z.read(prefix+'.shp'))
features=[]
for qid,id,name in [('Q3783','brazil-amazon-river','亚马孙河（含源数据上游段）'),('Q118771','brazil-negro-river','内格罗河')]:
 lines=[line for row,parts in zip(records,shapes) if row and row.get('wikidataid','').strip('\x00 ')==qid for line in parts];assert lines
 features.append(dict(type='Feature',properties=dict(id=id,name=name,kind='river'),geometry=dict(type='MultiLineString',coordinates=lines)))
out=dict(type='FeatureCollection',features=features,sourceUrl='https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/',license='Public domain',sourceArchiveSha256=hashlib.sha256(archive.read_bytes()).hexdigest(),note='保留Natural Earth原始河道段，国家图比例不适用于现场导航或水色边界判断。')
(root/'assets/atlas/brazil-rivers.geojson').write_text(json.dumps(out,ensure_ascii=False,separators=(',',':'))+'\n')
