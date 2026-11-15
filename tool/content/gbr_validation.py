"""Offline cross-checks for the published UK editorial and projected map."""
from collections import Counter
from hashlib import sha256
import json
import re
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[2]


def validate_gbr(catalog):
    errors = []

    def check(condition, problem):
        if not condition:
            errors.append(f'UK: {problem}')

    country = next((c for c in catalog['countries'] if c['id'] == 'gbr'), None)
    if country is None or country['coverage'] != 'editorial':
        return ['UK: editorial package is missing']
    a = {r['id']: r for r in catalog['articles'] if r['countryId'] == 'gbr'}
    p = {r['id']: r for r in catalog['places'] if r['countryId'] == 'gbr'}
    e = {r['id']: r for r in catalog['exercises'] if r['countryId'] == 'gbr'}
    m = {r['id']: r for r in catalog['media'] if r['id'].startswith('gbr-')}
    check(len(country['sections']) == 10 and all(len(items) == 3 for items in country['sections'].values()),
          'expected ten sections of three articles')
    section_ids = [aid for items in country['sections'].values() for aid in items]
    check(len(a) == len(section_ids) == 30 and set(section_ids) == a.keys(), 'section coverage differs')
    check(len(p) == 12, 'expected 12 places')
    check(Counter(r['type'] for r in e.values()) == {'choice':12, 'location':6, 'observation':6},
          'expected 12 choice, 6 map and 6 observation exercises')
    check(len(m) == 36 and Counter(r['kind'] for r in m.values()) ==
          {'realPhoto': 34, 'diagram': 2}, 'media coverage differs')
    open_ids, bound = set(), set()
    for article in a.values():
        aid = article['id']
        han = len(re.findall(r'[一-鿿]', ''.join(b['title'] + b['text'] for b in article['blocks'])))
        check(len(article['blocks']) in range(4, 7) and len(article.get('glossary', [])) in range(1, 4)
              and 450 <= han <= 650, f'{aid} differs from the reading length or glossary target')
        activity = article.get('activity')
        question = article.get('exerciseId')
        check(bool(activity) != bool(question), f'{aid} must have one core activity')
        if activity:
            open_ids.add(activity['id'])
            check(activity['type'] == 'open' and len(activity['fields']) == 3 and activity['mediaIds']
                  and set(activity['mediaIds']) <= m.keys() and set(activity['suggestedArticleIds']) <= a.keys(),
                  f'{aid} open activity is incomplete')
        if question:
            bound.add(question)
            check(e.get(question, {}).get('articleId') == aid, f'{aid} exercise is missing or belongs elsewhere')
    check(len(open_ids) == 6 and bound == e.keys(), 'activity coverage differs')
    for place in p.values():
        check(bool(place['region'] and place['coordinateSource'] and place['aliases'])
              and set(place['mediaIds']) <= m.keys()
              and set(place['articleIds']) <= a.keys(), f'{place["id"]} lacks source or referenced records')
        for hotspot in place['hotspots']:
            check(hotspot['mediaId'] in place['mediaIds'] and
                  all(0 < hotspot[key] < 1 for key in ('x','y')), f'{place["id"]} hotspot is out of frame')

    geo_path = ROOT / 'assets/atlas/gbr-regions.json'
    geo = json.loads(geo_path.read_text())
    features=geo['features']
    points=set(p) | {f['properties']['id'] for f in features}
    kinds=Counter(f['properties']['kind'] for f in features)
    check(kinds['part']==4 and kinds['island']==2 and kinds['river']==2 and kinds['lake']==1,'UK geographic coverage differs')
    check((ROOT/'assets/atlas/gbr-relief.jpg').is_file(),'UK relief missing')
    for item in e.values():
        check(item['evidenceBlockIds'] and set(item.get('mediaIds', [])) <= m.keys(),
              f'{item["id"]} evidence or media is missing')
        if item['type'] == 'location':
            options = {o.get('featureId', o['id']) for o in item['options']}
            scope = item.get('mapScope')
            check((scope == 'country' and options <= points) or
                  (scope == 'world' and options <= {r['id'] for r in catalog['countries']}),
                  f'{item["id"]} map candidates missing')
        for option in item['options']:
            if 'x' in option:
                check(all(0 < option[key] < 1 for key in ('x','y')) and len(item['mediaIds']) == 1,
                      f'{item["id"]} invalid photo point')
    seen = set()
    for media in m.values():
        path = ROOT / media['asset']
        digest = sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        check(digest == media['sha256'] and digest not in seen, f'{media["id"]} digest missing or duplicated')
        seen.add(digest)
        check(media['width'] > 0 and media['height'] > 0 and media['checkedAt'] and
              all(urlparse(media[k]).scheme == 'https' for k in ('sourceUrl','licenseUrl','downloadUrl')),
              f'{media["id"]} dimensions or attribution missing')
    editorial = country['editorial']
    check(len(editorial['journeys']) == 3 and all(len(j['articleIds']) == 3 for j in editorial['journeys']),
          'journey coverage differs')
    check([t['period'] for t in editorial['timeline']] == ['约公元前2500年','1825年','1928年'], 'timeline coverage differs')
    return errors
