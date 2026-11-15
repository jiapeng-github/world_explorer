"""Offline checks for Egypt's published second edition."""

from collections import Counter
import hashlib
import json
from pathlib import Path
import re

from fetch_china_media import verify


ROOT = Path(__file__).resolve().parents[2]
DIAGRAMS = {'nile-flow', 'nile-irrigation', 'papyrus-steps', 'reef-habitat',
            'heritage-move', 'evidence'}
LEGACY_ARTICLES = {'egypt-geography', 'egypt-nature', 'egypt-people',
                   'egypt-culture', 'egypt-history', 'egypt-explore', 'egypt-food'}
LEGACY_PLACES = {'giza', 'nile-delta', 'abu-simbel'}
LEGACY_ANSWERS = {'egypt-location': 'egypt', 'egypt-water': 'water',
                  'egypt-observation': 'links'}


def validate_egypt(data):
    errors = []

    def check(condition, message):
        if not condition:
            errors.append(f'Egypt: {message}')

    def local(kind):
        return {item['id']: item for item in data[kind] if item['countryId'] == 'egypt'}

    c = next(c for c in data['countries'] if c['id'] == 'egypt')
    articles, places, exercises = map(local, ('articles', 'places', 'exercises'))
    photo_doc = json.loads((ROOT / 'tool/content/editorial/egypt_assets.json').read_text())
    photos = {row['id']: row for row in photo_doc['media']}
    directory = [aid for ids in c['sections'].values() for aid in ids]

    check(c['revision'] == 2 and c['coverage'] == 'editorial', 'country revision or coverage')
    check(len(c['sections']) == 10 and all(len(ids) == 3 for ids in c['sections'].values()),
          'expected three main articles in each of ten sections')
    check(len(directory) == len(set(directory)) == len(articles) == 30 and
          set(directory) == articles.keys(), 'duplicate or unreachable main articles')
    check(LEGACY_ARTICLES <= articles.keys() and LEGACY_PLACES <= places.keys(),
          'a previously published link was removed')
    check(len(places) == 12 and len(photos) == 36 and
          len({p['sha256'] for p in photos.values()}) == 36, 'place/media count or duplicate photographs')
    check(len(exercises) == 24 and Counter(e['type'] for e in exercises.values()) ==
          {'choice': 12, 'location': 6, 'observation': 6}, 'incorrect closed exercise distribution')
    check(all(exercises.get(eid, {}).get('answerId') == answer
              for eid, answer in LEGACY_ANSWERS.items()), 'legacy answer IDs changed')
    check(exercises.get('egypt-location', {}).get('mapScope') == 'world' and
          all(e.get('mapScope') == 'country' for e in exercises.values()
              if e['type'] == 'location' and e['id'] != 'egypt-location'),
          'world and regional exercises have incorrect scopes')

    def points(item, key, images):
        for point in item.get(key, []):
            check(point['mediaId'] in images and bool(point.get('label')) and
                  bool(point.get('explanation')), f'{item["id"]} has an incomplete photo point')
            check(all(type(point.get(axis)) in (float, int) and 0 < point[axis] < 1
                      for axis in ('x', 'y')), f'{item["id"]} has an out-of-photo point')

    opened = []
    for section, ids in c['sections'].items():
        for aid in ids:
            a = articles[aid]
            check(a['sectionId'] == section, f'{aid} listed in wrong section')
            body = ''.join(b['text'] for b in a['blocks'])
            count = len(re.findall(r'[\u3400-\u9fff]', body))
            check(a['revision'] == 2 and 4 <= len(a['blocks']) <= 6 and
                  450 <= count <= 650, f'{aid} has {count} Chinese characters or invalid revision/blocks')
            check(all(b['id'] == f'{aid}-r2-b{i}' for i, b in enumerate(a['blocks'], 1)),
                  f'{aid} unstable block IDs')
            check(bool(a['term'] and a['definition'] and a.get('glossary')), f'{aid} missing glossary')
            activity = a.get('activity', {})
            eid = a.get('exerciseId')
            if activity:
                opened.append(activity['id'])
                check(not eid and activity['type'] == 'open' and
                      activity['fields'] == ['我看见', '我猜想', '我还想知道'] and
                      bool(activity['mediaIds']) and set(activity['mediaIds']) <= photos.keys(),
                      f'{aid} incomplete open observation')
            else:
                check(eid in exercises and exercises[eid]['articleId'] == aid and
                      bool(exercises[eid]['evidenceBlockIds']), f'{aid} missing its exercise/evidence')
    check(len(opened) == len(set(opened)) == 6, 'expected six distinct open observations')
    check({a['diagram'] for a in articles.values() if a.get('diagram')} == DIAGRAMS,
          'incorrect diagram coverage')
    for p in places.values():
        check(bool(p['mediaIds']) and set(p['mediaIds']) <= photos.keys() and
              bool(p['articleIds']) and set(p['articleIds']) <= articles.keys() and
              bool(p['coordinateSource']), f'{p["id"]} is missing media, articles or coordinate origin')
        points(p, 'hotspots', p['mediaIds'])
    for e in exercises.values():
        check(set(e.get('mediaIds', [])) <= photos.keys(), f'{e["id"]} unknown exercise photo')
        points(e, 'photoHotspots', e.get('mediaIds', []))
    check(sum(bool(p['hotspots']) for p in places.values()) >= 5, 'missing place photo hotspots')
    for p in photos.values():
        try:
            verify(p, (ROOT / p['asset']).read_bytes())
        except (OSError, ValueError) as exc:
            errors.append(f'Egypt: {p["id"]}: {exc}')
    info = json.loads((ROOT / 'assets/atlas/egypt-relief-source.json').read_text())
    check(hashlib.sha256((ROOT / info['asset']).read_bytes()).hexdigest() == info['sha256'],
          'regional relief image integrity check failed')

    return errors
