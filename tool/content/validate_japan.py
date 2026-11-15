"""Japan release contract: references, editorial coverage and media integrity.
Run after author_japan.py and build_catalog.py. Also usable with a shared
catalog while unrelated countries are still being developed.
"""
import hashlib,json
from collections import Counter
from pathlib import Path
root=Path(__file__).resolve().parents[2]
j=json.loads((root/'tool/content/editorial/japan.json').read_text())
c=j['country'];arts={a['id']:a for a in j['articles']};places={p['id']:p for p in j['places']};ex={e['id']:e for e in j['exercises']}
shipped=json.loads((root/'assets/atlas/catalog.json').read_text());media={m['id']:m for m in shipped['media']}
assert len(arts)==30 and len(places)==12 and len(ex)==24
assert len(c['sections'])==10 and all(len(ids)==3 for ids in c['sections'].values())
assert Counter(e['type'] for e in ex.values())==dict(choice=12,location=6,observation=6)
assert sum('activity' in a for a in arts.values())==6
assert sum('diagram' in a for a in arts.values())==8
assert len(c['editorial']['journeys'])==3
assert c['revision']>=4
used=set()
for a in arts.values():
 n=sum(len(b['text']) for b in a['blocks']);assert 450<=n<=650,(a['id'],n)
 assert a['id'] in c['sections'][a['sectionId']]
 assert a['sourceUrls'] and all(u.startswith('https://') for u in a['sourceUrls'])
 assert a['term'] and a['definition'];used.add(a['mediaId'])
 if 'placeId' in a:assert a['placeId'] in places
 if 'exerciseId' in a:assert ex[a['exerciseId']]['articleId']==a['id']
 if 'activity' in a:
  assert a['activity']['type']=='open' and len(a['activity']['fields'])==3
  used.update(a['activity']['mediaIds'])
for e in ex.values():
 a=arts[e['articleId']];assert e['answerId'] in {o['id'] for o in e['options']}
 assert e['evidenceBlockIds'] and set(e['evidenceBlockIds']) <= {b['id'] for b in a['blocks']}
 if e['type']=='location':
  targets={x['id'] for x in shipped['countries']} if e['mapScope']=='world' else set(places)
  assert {o['id'] for o in e['options']}<=targets
 if e.get('mediaId'):used.add(e['mediaId'])
for p in places.values():
 assert p['articleIds'] and set(p['articleIds'])<=arts.keys()
 assert len(p['hotspots'])>=2 and all(0<=h['x']<=1 and 0<=h['y']<=1 and h['explanation'] for h in p['hotspots'])
 used.update(p['mediaIds'])
for journey in c['editorial']['journeys']:
 assert len(journey['articleIds'])==3 and set(journey['articleIds'])<=arts.keys();used.add(journey['mediaId'])
for event in c['editorial']['timeline']:
 assert set(event['articleIds'])<=arts.keys();used.add(event['mediaId'])
for mid in used:
 m=media[mid];p=root/m['asset'];assert p.is_file(),p
 assert m['credit'] and m['license'] and m['licenseUrl'].startswith('https://')
 if m.get('sha256'):assert hashlib.sha256(p.read_bytes()).hexdigest()==m['sha256'],mid
for kind,expected in [('articles',arts),('places',places),('exercises',ex)]:
 actual={r['id']:r for r in shipped[kind] if r.get('countryId')=='japan'}
 assert actual==expected,kind+' shipped catalog differs from editorial source'
rivers=json.loads((root/'assets/atlas/japan-rivers.geojson').read_text())
assert len(rivers['features'])==3
assert sum(len(line) for f in rivers['features'] for line in f['geometry']['coordinates'])>150
print('Japan: 30 readings (450–650 characters), 10 sections, 12 places, 24 exercises, 6 open tasks, 8 diagrams, 3 journeys, sources and assets: PASS')
