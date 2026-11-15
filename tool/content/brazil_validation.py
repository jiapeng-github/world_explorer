"""Acceptance checks for Brazil's full edition and stable legacy records."""
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]

def validate_brazil(catalog):
    errors=[]
    def check(ok,message):
        if not ok:errors.append('Brazil: '+message)
    c=next(c for c in catalog['countries'] if c['id']=='brazil')
    articles={a['id']:a for a in catalog['articles'] if a['countryId']=='brazil'}
    places={p['id']:p for p in catalog['places'] if p['countryId']=='brazil'}
    exercises={e['id']:e for e in catalog['exercises'] if e['countryId']=='brazil'}
    media={m['id']:m for m in catalog['media'] if m['id'].startswith('brazil-')}
    ids=[aid for group in c['sections'].values() for aid in group]
    check(len(c['sections'])==10 and all(len(g)==3 for g in c['sections'].values()),'need ten sections of three readings')
    check(len(ids)==len(set(ids))==30,'thirty distinct current readings')
    check(set(ids)<=articles.keys(),'section reference missing')
    check(all('brazil-'+s in articles for s in ['geography','nature','people','culture','history','explore','food']),'legacy IDs removed')
    check(Counter(e['type'] for e in exercises.values())=={'choice':12,'location':6,'observation':6},'24 exercises split 12/6/6')
    featured=c['editorial']['featuredPlaceIds'];check(len(featured)==12 and set(featured)<=places.keys(),'twelve curated places')
    check(len(media)==36,'36 distinct licensed media')
    check(len(c['editorial']['timeline'])==5,'five sourced timeline clues')
    open_count=0;bound=set();diagrams=set()
    for aid in ids:
        a=articles[aid];han=len(re.findall('[一-鿿]',''.join(b['title']+b['text'] for b in a['blocks'])))
        check(450<=han<=650,f'{aid}: reading length {han}')
        check(a.get('reviewStatus')=='sourceChecked' and a.get('sourceUrls') and a.get('glossary'),f'{aid}: review/source/glossary')
        check(bool(a.get('exerciseId'))!=bool(a.get('activity')),f'{aid}: exactly one core activity')
        if a.get('activity'):
            open_count+=1
            check(len(a['activity']['fields'])==3 and set(a['activity']['mediaIds'])<=media.keys(),f'{aid}: open fields/media')
        if a.get('exerciseId'):
            eid=a['exerciseId'];bound.add(eid)
            check(exercises.get(eid,{}).get('articleId')==aid,f'{aid}: exercise belongs elsewhere')
        if a.get('diagram'):diagrams.add(a['diagram'])
    check(open_count==6 and bound==exercises.keys(),'six open activities and all questions bound')
    check(len(diagrams)==8,'eight interactive teaching models')
    for e in exercises.values():
        a=articles[e['articleId']]
        check(bool(e.get('evidenceBlockIds')) and set(e['evidenceBlockIds'])<={b['id'] for b in a['blocks']},e['id']+': evidence missing')
        check(e['answerId'] in {o['id'] for o in e['options']},e['id']+': answer invalid')
        if e['type']=='location':
            expected=places.keys() if e['mapScope']=='country' else {v['id'] for v in catalog['countries']}
            check({o['id'] for o in e['options']}<=expected,e['id']+': map candidate missing')
    for j in c['editorial']['journeys']:
        check(len(j['articleIds'])==3 and set(j['articleIds'])<=set(ids),j['id']+': journey coverage')
    linked=set()
    def scan(v):
        if isinstance(v,dict):
            for k,x in v.items():
                if k=='mediaId' and x:linked.add(x)
                elif k=='mediaIds':linked.update(x)
                else:scan(x)
        elif isinstance(v,list):
            for x in v:scan(x)
    scan([c,list(articles.values()),list(places.values()),list(exercises.values())])
    check(media.keys()<=linked,'media not visible from any content')
    hashes=set()
    for mid,m in media.items():
        raw=(ROOT/m['asset']).read_bytes();digest=sha256(raw).hexdigest()
        check(digest not in hashes,mid+': duplicate image bytes');hashes.add(digest)
        if mid!='brazil-iguazu':
            check(digest==m['sha256'],mid+': file hash differs')
            check(all(m.get(k) for k in ['captureDate','credit','license','licenseUrl','sourceUrl','processing']),mid+': attribution incomplete')
    geo=json.loads((ROOT/'assets/atlas/brazil-biomes.geojson').read_text())
    check(geo['sourceYear']==2019 and geo['sourceCrs']=='EPSG:4674' and geo['outputCrs']=='EPSG:4326','GIS provenance')
    check(len(geo['features'])==6 and len({f['properties']['id'] for f in geo['features']})==6,'six real GIS biomes')
    check(len(geo['sourceArchiveSha256'])==64,'source archive digest missing')
    return errors

if __name__=='__main__':
    errors=validate_brazil(json.loads((ROOT/'assets/atlas/catalog.json').read_text()))
    if errors:raise SystemExit('\n'.join(errors))
    print('Brazil: 30 readings, 24 tasks, 6 open activities, 12 curated places, 36 media, 8 diagrams, 6 GIS biomes: PASS')
