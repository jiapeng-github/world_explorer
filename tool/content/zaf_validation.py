"""South Africa editorial contract: reject incomplete packs or broken evidence."""
from collections import Counter
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
def validate_zaf(data):
 errors=[]
 def check(ok,message):
  if not ok:errors.append('zaf: '+message)
 countries={c['id']:c for c in data['countries']};c=countries['zaf'];aa=[a for a in data['articles'] if a['countryId']=='zaf'];ee=[e for e in data['exercises'] if e['countryId']=='zaf'];pp=[p for p in data['places'] if p['countryId']=='zaf'];mm={m['id']:m for m in data['media']}
 check(c['coverage']=='editorial','not enabled in encyclopedia')
 check(len(aa)==30,'expected 30 full articles');check(len(pp)==12,'expected 12 places')
 check(Counter(e['type'] for e in ee)=={'choice':12,'location':6,'observation':6},'activity split changed')
 check(sum(bool(a.get('activity')) for a in aa)==6,'expected six open observations')
 check(len(c['sections'])==10 and all(len(ids)==3 for ids in c['sections'].values()),'three unique articles per section')
 check(len({i for ids in c['sections'].values() for i in ids})==30,'article reused to inflate count')
 check(len(c['editorial']['journeys'])==3,'three journeys')
 for a in aa:
  check(len(a['blocks'])==5 and sum(len(b['text']) for b in a['blocks'])>=380,a['id']+' incomplete prose')
  check(bool(a.get('exerciseId')) != bool(a.get('activity')),a['id']+' needs exactly one activity')
 for e in ee:
  check(bool(e['evidenceBlockIds']),e['id']+' evidence missing')
  if e.get('mapScope')=='country':check(all(o['id'] in {p['id'] for p in pp} for o in e['options']),e['id']+' unknown map candidate')
 for p in pp:check(bool(p['articleIds']),p['id']+' has no linked reading')
 used={a['mediaId'] for a in aa}|{m for p in pp for m in p['mediaIds']}
 for mid in used:
  check(mid in mm,mid+' missing metadata')
  if mid not in mm:continue
  m=mm[mid];f=ROOT/m['asset']
  check(bool(m.get('captureDate')),mid+' capture date missing')
  check(f.is_file() and hashlib.sha256(f.read_bytes()).hexdigest()==m['sha256'],mid+' media hash mismatch')
 geo=json.loads((ROOT/'assets/atlas/zaf-countries-detail.geojson').read_text())
 check({f['properties']['code'] for f in geo['features']}=={'ZAF','LSO','SWZ','NAM','BWA','ZWE','MOZ'},'regional country set')
 zaf=next(f for f in geo['features'] if f['properties']['code']=='ZAF')
 check(any(len(p)>1 for p in zaf['geometry']['coordinates']),'Lesotho interior ring lost')
 return errors
if __name__=='__main__':
 data=json.loads((ROOT/'assets/atlas/catalog.json').read_text());errors=validate_zaf(data)
 if errors:raise SystemExit('\n'.join(errors))
 print('South Africa prose, activities, references, media hashes and regional geometry: PASS')
