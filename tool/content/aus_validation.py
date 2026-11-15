"""Australia release invariants: editorial completeness and playable references."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def validate_aus(data):
 errors=[]
 def check(ok,message):
  if not ok:errors.append('aus: '+message)
 countries={c['id']:c for c in data['countries']};c=countries.get('aus',{})
 articles=[a for a in data['articles'] if a['countryId']=='aus'];places=[p for p in data['places'] if p['countryId']=='aus'];exercises=[e for e in data['exercises'] if e['countryId']=='aus'];media={m['id']:m for m in data['media']};by={a['id']:a for a in articles};pb={p['id']:p for p in places};eb={e['id']:e for e in exercises}
 check(c.get('coverage')=='editorial','not published')
 check(len(articles)==30 and len(places)==12 and len(exercises)==24,'expected 30 articles, 12 places and 24 exercises')
 check(len(c.get('sections',{}))==10 and all(len(ids)==3 for ids in c.get('sections',{}).values()),'ten sections of three articles')
 check(sorted(aid for ids in c['sections'].values() for aid in ids)==sorted(by),'section references duplicate or omit articles')
 for kind,count in [('choice',12),('location',6),('observation',6)]:check(sum(e['type']==kind for e in exercises)==count,kind+' count')
 check(sum(a.get('activity',{}).get('type')=='open' for a in articles)==6,'six open observations')
 check(len({a['diagram'] for a in articles if a.get('diagram')})==8,'eight diagrams')
 for a in articles:
  check(450<=len(re.findall('[\u4e00-\u9fff]',''.join(b['text'] for b in a['blocks'])))<=650,a['id']+' body length')
  check(4<=len(a['blocks'])<=6,a['id']+' block count')
  check(a.get('reviewStatus')=='reviewed',a['id']+' unreviewed')
  check(bool(a.get('exerciseId')) != bool(a.get('activity')),a['id']+' needs exactly one activity')
  check(a.get('mediaId') in media,a['id']+' image')
  check(bool(a.get('sourceUrls')) and all(u.startswith('https://') for u in a['sourceUrls']),a['id']+' sources')
  if a.get('exerciseId'):check(a['exerciseId'] in eb and eb[a['exerciseId']]['articleId']==a['id'],a['id']+' exercise')
  if a.get('placeId'):check(a['placeId'] in pb and a['id'] in pb[a['placeId']]['articleIds'],a['id']+' place')
 known=set(pb)|{'aus-murray','aus-darling','aus-torres-strait','aus-bass-strait','aus-tasmania','aus-canberra-city','aus-indian-ocean','aus-pacific-ocean'}
 for e in exercises:
  check(e['articleId'] in by,e['id']+' article')
  check(e['answerId'] in {o['id'] for o in e['options']},e['id']+' answer')
  check(bool(e['evidenceBlockIds']) and set(e['evidenceBlockIds'])<={b['id'] for b in by[e['articleId']]['blocks']},e['id']+' evidence')
  if e['type']=='location':
   valid=set(countries) if e['mapScope']=='world' else known
   check(all((o.get('featureId') or o['id']) in valid for o in e['options']),e['id']+' unselectable map option')
 for p in places:
  check(bool(p['mediaIds']) and all(m in media for m in p['mediaIds']),p['id']+' missing media')
  check(bool(p['articleIds']) and all(a in by for a in p['articleIds']),p['id']+' missing article')
  check(len(p['description'])>70 and bool(p['sourceUrl']),p['id']+' incomplete story')
  for h in p.get('hotspots',[]):check(h['mediaId'] in p['mediaIds'] and 0<=h['x']<=1 and 0<=h['y']<=1,p['id']+' hotspot')
 for m in media.values():
  if not m['id'].startswith('aus-'):continue
  path=ROOT/m['asset'];check(path.is_file(),m['id']+' missing asset')
  if path.is_file():check(hashlib.sha256(path.read_bytes()).hexdigest()==m.get('sha256'),m['id']+' changed bytes')
  check(all(m.get(k) for k in ['license','licenseUrl','sourceUrl','credit','captureDate','checkedAt']),m['id']+' provenance')
 for journey in c['editorial']['journeys']:check(len(journey['articleIds'])==3 and all(a in by for a in journey['articleIds']),journey['id']+' route')
 check(by['aus-uluru-country']['mediaId']=='aus-study','Uluru unapproved imagery')
 check(by['aus-market-origin']['mediaId']=='aus-market','market depiction')
 return errors
if __name__=='__main__':
 errors=validate_aus(json.loads((ROOT/'assets/atlas/catalog.json').read_text()))
 if errors:raise SystemExit('\n'.join(errors))
 print('Australia content, activity evidence, maps and image integrity: PASS')
