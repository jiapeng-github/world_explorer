"""Contract checks for Kenya's article evidence, activities and bundled media."""
import hashlib,re
from pathlib import Path

def validate_kenya(data,root=None):
 errors=[]
 def check(ok,message):
  if not ok:errors.append('kenya: '+message)
 country=next((c for c in data['countries'] if c['id']=='kenya'),None)
 if not country or country.get('coverage')!='editorial':return errors
 articles=[a for a in data['articles'] if a['countryId']=='kenya'];exercises=[e for e in data['exercises'] if e['countryId']=='kenya'];places=[p for p in data['places'] if p['countryId']=='kenya'];media={m['id']:m for m in data['media']}
 check(len(articles)==30,'30 complete articles required');check(len(exercises)==24,'24 closed activities required');check(len(places)==12,'12 places required')
 check(len(country['sections'])==10 and all(len(v)==3 for v in country['sections'].values()),'10 sections with 3 articles each')
 activity_ids=[]
 for a in articles:
  blocks=a['blocks'];count=len(re.findall('[\u4e00-\u9fff]',''.join(b['text'] for b in blocks)))
  check(4<=len(blocks)<=6 and 450<=count<=650,a['id']+' prose length')
  check(bool(a.get('exerciseId'))!=bool(a.get('activity')),a['id']+' must have one core activity')
  check(a.get('sourceUrls') and all(u.startswith('https://') for u in a['sourceUrls']),a['id']+' sources')
  if a.get('activity'):
   check(a['activity']['fields']==['我看见','我猜想','我还想知道'],a['id']+' observation fields');activity_ids.append(a['activity']['id'])
 check(len(activity_ids)==6 and len(set(activity_ids))==6,'six distinct open observations')
 by_id={a['id']:a for a in articles}
 for e in exercises:
  blocks={b['id'] for b in by_id[e['articleId']]['blocks']}
  check(bool(e.get('evidenceBlockIds')) and set(e['evidenceBlockIds'])<=blocks,e['id']+' evidence links')
  check(e['answerId'] in {o['id'] for o in e['options']},e['id']+' answer option')
 for typ,n in [('choice',12),('location',6),('observation',6)]:check(sum(e['type']==typ for e in exercises)==n,typ+' count')
 for p in places:check(len(p['mediaIds'])>=2 and all(m in media for m in p['mediaIds']),p['id']+' place media')
 for n in range(1,37):
  m=media.get(f'kenya-m{n:02}',{});check(all(m.get(k) for k in ['credit','sourceUrl','license','licenseUrl','sha256','captureDate']),f'm{n:02} provenance')
  if root and m:
   f=Path(root)/m['asset'];check(f.exists() and hashlib.sha256(f.read_bytes()).hexdigest()==m['sha256'],m['id']+' asset checksum')
 for j in country['editorial']['journeys']:check(len(j['articleIds'])==3 and all(a in by_id for a in j['articleIds']),j['id']+' route references')
 check(set('kenya-'+s for s in ['geography','people','daily','food','culture','nature','history','questions']) <= set(by_id),'legacy article IDs retained')
 check({'kenya-amboseli','kenya-lamu','kenya-mount-kenya'} <= {p['id'] for p in places},'legacy place IDs retained')
 check(sum(bool(a.get('diagram')) for a in articles)==8,'eight teaching diagrams')
 check(len({m['id'] for m in data['media'] if m['id'].startswith('kenya-m')})==36,'36 media')
 return errors
