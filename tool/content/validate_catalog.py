"""Validate the shipped atlas without Flutter or network access.

Run: python3 tool/content/validate_catalog.py
This checks structure and references; factual and image-depiction review remains
an editorial task. A passing check does not certify the full launch targets.
"""
import json
from pathlib import Path
from urllib.parse import urlparse
from china_validation import validate_china
from egypt_validation import validate_egypt
from usa_validation import validate_usa
from gbr_validation import validate_gbr
from deu_validation import validate_deu
from kenya_validation import validate_kenya
from norway_validation import validate_norway
from zaf_validation import validate_zaf
from aus_validation import validate_aus
from brazil_validation import validate_brazil

ROOT = Path(__file__).resolve().parents[2]
data = json.loads((ROOT / 'assets/atlas/catalog.json').read_text())
errors = []


def check(condition, message):
    if not condition:
        errors.append(message)


def https(url):
    parsed = urlparse(url)
    return parsed.scheme == 'https' and bool(parsed.netloc)


indexes = {}
for kind in ['countries', 'articles', 'places', 'topics', 'exercises', 'media']:
    indexes[kind] = {item['id']: item for item in data[kind]}
    check(len(indexes[kind]) == len(data[kind]), f'{kind}: duplicate ID')

countries = indexes['countries']
articles = indexes['articles']
media = indexes['media']
required_sections = {'overview', 'geography', 'people', 'daily', 'food',
                     'culture', 'landmarks', 'nature', 'history', 'questions'}
for c in countries.values():
    check(-90 <= c['latitude'] <= 90 and -180 <= c['longitude'] <= 180,
          f'{c["id"]}: invalid coordinates')
    for section, ids in c['sections'].items():
        for aid in ids:
            check(aid in articles and articles[aid]['countryId'] == c['id'],
                  f'{c["id"]}/{section}: unknown or foreign article {aid}')
    if c['coverage'] == 'editorial':
        check(required_sections <= c['sections'].keys(), f'{c["id"]}: missing section')
        check(all(c['sections'].get(s) for s in required_sections), f'{c["id"]}: empty section')
        check(bool(c['intro']) and len(c['takeaways']) == 3, f'{c["id"]}: profile incomplete')
        for event in c['timeline']:
            check(all(isinstance(event.get(k), str) and event[k] for k in ['period', 'title', 'body']),
                  f'{c["id"]}: incomplete timeline event')
    for s in c['sources']:
        check(https(s['url']) and bool(s.get('checkedAt')), f'{c["id"]}: invalid source')

for a in articles.values():
    check(a['countryId'] in countries, f'{a["id"]}: country missing')
    check(a['mediaId'] in media, f'{a["id"]}: cover missing')
    check(len(a['blocks']) >= 1, f'{a["id"]}: no body')
    check(len({b['id'] for b in a['blocks']}) == len(a['blocks']), f'{a["id"]}: duplicate block ID')
    check(bool(a['sourceUrls']) and all(https(u) for u in a['sourceUrls']), f'{a["id"]}: invalid sources')
    for b in a['blocks']:
        check(bool(b['title']) and bool(b['text']), f'{a["id"]}: empty block')
        if b.get('mediaId'):
            check(b['mediaId'] in media, f'{a["id"]}/{b["id"]}: body image missing')
    if a.get('placeId'):
        check(a['placeId'] in indexes['places'], f'{a["id"]}: linked place missing')

for p in indexes['places'].values():
    check(p['countryId'] in countries, f'{p["id"]}: country missing')
    check(all(mid in media for mid in p['mediaIds']), f'{p["id"]}: photo missing')
    check(https(p['sourceUrl']), f'{p["id"]}: invalid source')
    check(-90 <= p['latitude'] <= 90 and -180 <= p['longitude'] <= 180,
          f'{p["id"]}: invalid coordinates')

for t in indexes['topics'].values():
    check(all(aid in articles for aid in t['articleIds']), f'{t["id"]}: article missing')
    check(t['mediaId'] in media, f'{t["id"]}: cover missing')

for e in indexes['exercises'].values():
    check(e['articleId'] in articles, f'{e["id"]}: article missing')
    check(e['answerId'] in {o['id'] for o in e['options']}, f'{e["id"]}: answer missing')
    check(len({o['id'] for o in e['options']}) == len(e['options']), f'{e["id"]}: duplicate options')
    if e.get('mediaId'):
        check(e['mediaId'] in media, f'{e["id"]}: exercise image missing')
    if e['articleId'] in articles:
        check(articles[e['articleId']]['countryId'] == e['countryId'], f'{e["id"]}: wrong country')
        blocks = {b['id'] for b in articles[e['articleId']]['blocks']}
        check(all(b in blocks for b in e.get('evidenceBlockIds', [])), f'{e["id"]}: evidence missing')

for country in countries.values():
    editorial = country.get('editorial', {})
    for kind in ['journeys', 'timeline']:
        entries = editorial.get(kind, [])
        check(len({e['id'] for e in entries}) == len(entries), f'{country["id"]}/{kind}: duplicate ID')
        for entry in entries:
            check(entry.get('mediaId') in media, f'{entry["id"]}: editorial image missing')
            check(bool(entry.get('articleIds')) and all(
                aid in articles and articles[aid]['countryId'] == country['id']
                for aid in entry.get('articleIds', [])), f'{entry["id"]}: editorial article missing/foreign')
    for key, section in editorial.get('sections', {}).items():
        check(key in country['sections'] and bool(section.get('summary')),
              f'{country["id"]}/{key}: section introduction missing')
        check(section.get('mediaId') in media, f'{country["id"]}/{key}: section image missing')
    check(all(pid in indexes['places'] and indexes['places'][pid]['countryId'] == country['id']
              for pid in editorial.get('featuredPlaceIds', [])), f'{country["id"]}: featured place missing/foreign')

archived = data.get('archivedExercises', [])
check(len({e['id'] for e in archived}) == len(archived), 'archivedExercises: duplicate ID')
for e in archived:
    check(e['id'] not in indexes['exercises'], f'{e["id"]}: archived question still active')
    check(e['articleId'] in articles, f'{e["id"]}: archive article missing')
    check(e.get('replacementExerciseId') in indexes['exercises'], f'{e["id"]}: replacement exercise missing')

errors.extend(validate_china(data))
errors.extend(validate_egypt(data))
errors.extend(validate_usa(data))
errors.extend(validate_gbr(data))
errors.extend(validate_deu(data, ROOT))
errors.extend(validate_kenya(data, ROOT))
errors.extend(validate_norway(data, ROOT))
errors.extend(validate_zaf(data))
errors.extend(validate_aus(data))
errors.extend(validate_brazil(data))

for m in media.values():
    path = (ROOT / m['asset']).resolve()
    check(path.is_relative_to(ROOT / 'assets') and path.is_file(), f'{m["id"]}: missing/unsafe asset')
    check(all(bool(m.get(k)) for k in ['caption', 'credit', 'license']), f'{m["id"]}: credit incomplete')
    check(https(m['sourceUrl']) and https(m['licenseUrl']), f'{m["id"]}: license/source URL invalid')

if errors:
    raise SystemExit('\n'.join(errors))
print('Content schema, references, timeline fields and bundled media: PASS')
print(json.dumps({kind: len(values) for kind, values in indexes.items()}, ensure_ascii=False))
print('Countries with editorial articles:', sum(c['coverage'] == 'editorial' for c in countries.values()))
