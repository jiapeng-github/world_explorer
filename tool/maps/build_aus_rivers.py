"""Extract source segments of the Murray and Darling; never bridge source gaps."""
import hashlib,json,sys,zipfile
from pathlib import Path
from build_detail import dbf_records
from build_china_rivers import polylines
ROOT=Path(__file__).resolve().parents[2]
def extract(path):
 with zipfile.ZipFile(path) as z:
  base='ne_10m_rivers_lake_centerlines';records=dbf_records(z.read(base+'.dbf'));shapes=polylines(z.read(base+'.shp'));version=z.read(base+'.VERSION.txt').decode().strip()
 groups={'Q183078':('aus-murray','墨累河',[]),'Q181482':('aus-darling','达令河',[])}
 for row,lines in zip(records,shapes):
  if not row:continue
  key=row.get('wikidataid','').strip('\x00 ')
  if key in groups:groups[key][2].extend(lines)
 features=[]
 for id,name,lines in groups.values():
  if not lines:raise ValueError('Missing '+name)
  features.append(dict(type='Feature',properties=dict(id=id,name=name,kind='river',note='原始河道分段；未跨缺口补线'),geometry=dict(type='MultiLineString',coordinates=lines)))
 return dict(type='FeatureCollection',features=features,source='Natural Earth 1:10m rivers',sourceVersion=version,sourceUrl='https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/',downloadUrl='https://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_lake_centerlines.zip',sourceArchiveSha256=hashlib.sha256(Path(path).read_bytes()).hexdigest(),license='Public domain',checkedAt='2026-11-11')
if __name__=='__main__':
 out=extract(sys.argv[1]);(ROOT/'assets/atlas/aus-rivers.geojson').write_text(json.dumps(out,ensure_ascii=False,separators=(',',':'))+'\n');print([(f['properties']['id'],sum(map(len,f['geometry']['coordinates']))) for f in out['features']])
