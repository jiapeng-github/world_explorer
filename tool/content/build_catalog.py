"""Build the versioned offline atlas from reviewed editorial and geographic data.

No network requests; all source inputs are checked into the repository.
Run from the project root: python3 tool/content/build_catalog.py
"""
import json
import sys
from pathlib import Path
from catalog_merge import archive_exercises, merge_country, upsert_records

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/atlas'
sys.path.insert(0, str(ROOT / 'tool/maps'))
from china_display_policy import merge_china, normalize_catalog
old = json.loads((ROOT / 'assets/content/catalog.json').read_text())
geo = json.loads((ROOT / 'assets/maps/world-countries.geojson').read_text())
properties = json.loads((OUT / 'country-properties.json').read_text())
by_code = {p['ADM0_A3']: p for p in properties}
aliases = {'CHN': 'china', 'EGY': 'egypt', 'BRA': 'brazil', 'JPN': 'japan', 'KEN': 'kenya', 'NOR': 'norway'}
continents = {'Asia': '亚洲', 'Europe': '欧洲', 'Africa': '非洲', 'North America': '北美洲', 'South America': '南美洲', 'Oceania': '大洋洲', 'Antarctica': '南极洲', 'Seven seas (open ocean)': '南极地区'}
catalog = {'schemaVersion': 1, 'contentVersion': '2026.11.10.1', 'countries': [], 'articles': [], 'places': [], 'topics': [], 'exercises': [], 'archivedExercises': [], 'media': []}
for feature in geo['features']:
    code = feature['properties']['code']
    p = by_code[code]
    cid = aliases.get(code, code.lower())
    feature['properties'] = {'id': cid, 'code': code, 'name': p['NAME_ZH']}
    catalog['countries'].append({'id': cid, 'code': p['ISO_A2'] if p['ISO_A2'] != '-99' else '', 'name': p['NAME_ZH'], 'englishName': p['NAME_EN'], 'continent': continents[p['CONTINENT']], 'latitude': float(p['LABEL_Y']), 'longitude': float(p['LABEL_X']), 'capital': '', 'intro': '', 'tagline': '', 'mediaId': '', 'coverage': 'basic', 'facts': [], 'takeaways': [], 'timeline': [], 'sections': {}, 'sources': [{'title': 'Natural Earth 地理实体与标注', 'url': 'https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/', 'checkedAt': '2026-11-01'}]})
countries = {c['id']: c for c in catalog['countries']}

media_defs = [
    ('nile-aswan', '尼罗河沿岸的水域与景观', 'Eszter Kisgyura', '7ObNCbySGGc'),
    ('tree-frog', '哥斯达黎加的蛙类 Duellmanohyla uranochroa', 'Antony Abarca Zuniga', 'close-up-of-a-green-frog-with-bright-red-eyes-w2qPD1JHs40'),
    ('mount-fuji', '日本富士山与湖面的倒影', 'CHEN HENG', 'mount-fuji-reflects-beautifully-on-a-tranquil-lake-Yktjlc6322Y'),
    ('geiranger', '挪威盖朗厄尔峡湾', 'Alex Korolkoff', 'scenic-view-of-a-fjord-with-mountains-and-ships-cajBHH285sc'),
    ('school', '印度金奈一间学校教室；仅呈现这所学校的一次观察', 'Haseeb Modi', 'a-group-of-children-sitting-at-desks-in-a-classroom-OcDJhBm8Jnc'),
    ('florence', '意大利佛罗伦萨的屋顶与城市景观', 'Jonas Smith', 'top-view-of-florence-italy-WCGyAnAcCiA'),
    ('elephant', '肯尼亚安博塞利的大象与幼象', 'Neil and Zulma Scott', 'brown-elephant-on-green-grass-field-during-daytime-pHztxoXCvAw'),
]
for mid, caption, credit, slug in media_defs:
    catalog['media'].append({'id': mid, 'asset': f'assets/atlas/{mid}.jpg', 'caption': caption, 'credit': credit, 'sourceUrl': f'https://unsplash.com/photos/{slug}', 'license': 'Unsplash License', 'licenseUrl': 'https://unsplash.com/license', 'kind': 'realPhoto'})

title_sets = {
    'egypt': ['尼罗河流向哪里？', '尼罗河为什么重要？', '今天的埃及人怎样生活？', '一棵椰枣树能做什么？', '金字塔留下了哪些线索？', '怎样观察河流与生活？'],
    'china': ['中国的地势有什么不同？', '大熊猫为什么需要竹林？', '广阔土地上的不同生活', '一张纸怎样变成艺术？', '长城为什么这么长？', '怎样读懂中国的山川？'],
    'brazil': ['亚马孙河流向哪里？', '雨林里住着谁？', '巴西的人们说什么语言？', '音乐怎样连接人们？', '瀑布与城市的故事', '怎样发现雨林中的联系？'],
}
section_ids = ['overview', 'geography', 'people', 'daily', 'food', 'culture', 'landmarks', 'nature', 'history', 'questions']
for original in old['countries']:
    cid = original['id']; c = countries[cid]; profile = original['profile']
    photo = dict(profile['photo']); mid = Path(photo['asset']).stem; photo['id'] = mid; photo['kind'] = 'realPhoto'; catalog['media'].append(photo)
    c.update({k: original[k] for k in ['name', 'englishName', 'continent', 'latitude', 'longitude', 'facts', 'sources']})
    c.update({k: profile[k] for k in ['intro', 'capital', 'takeaways', 'timeline']})
    c.update({'mediaId': mid, 'coverage': 'editorial', 'tagline': {'china': '山川与文明', 'egypt': '尼罗河畔', 'brazil': '热带雨林与多彩文化'}[cid], 'sections': {s: [] for s in section_ids}})
    for index, t in enumerate(original['topics']):
        section = 'questions' if t['id'] == 'explore' else t['id']
        aid = f'{cid}-{t["id"]}'
        article_media = 'nile-aswan' if cid == 'egypt' and t['id'] in ['geography', 'nature', 'people', 'explore'] else mid
        blocks = [{'id': f'{aid}-b{i+1}', 'title': s['title'], 'text': s['body']} for i, s in enumerate(t['sections'])]
        catalog['articles'].append({'id': aid, 'countryId': cid, 'sectionId': section, 'title': title_sets[cid][index], 'summary': t['summary'], 'mediaId': article_media, 'blocks': blocks, 'term': t['glossary']['term'], 'definition': t['glossary']['definition'], 'question': t['question'], 'answer': t['answer'], 'sourceUrls': [s['url'] for s in c['sources']]})
        c['sections'][section].append(aid)
    # Overview and daily-life sections assemble existing reviewed material without
    # fabricating extra articles or inflating coverage counts.
    c['sections']['overview'] = [f'{cid}-geography', f'{cid}-people', f'{cid}-history']
    c['sections']['daily'] = [f'{cid}-people', f'{cid}-culture']
    c['sections']['food'] = []  # Filled only by a dedicated sourced food article.
    c['sections']['landmarks'] = [f'{cid}-history']
    for place in original['landmarks']:
        catalog['places'].append({'id': place['id'], 'countryId': cid, 'name': place['name'], 'category': place['category'], 'latitude': place['latitude'], 'longitude': place['longitude'], 'summary': place['teaser'], 'description': place['description'], 'observation': place['observation'], 'mediaIds': [mid] if place['photoAsset'] else [], 'sourceUrl': place['sourceUrl']})
    for quiz in original['quiz']:
        q = dict(quiz); q['countryId'] = cid; q['articleId'] = f'{cid}-geography' if q['type'] == 'location' else f'{cid}-nature'; catalog['exercises'].append(q)

for cid, capital, image, tagline in [('japan','东京','mount-fuji','自然与现代生活'),('kenya','内罗毕','elephant','草原上的生命'),('norway','奥斯陆','geiranger','峡湾与高纬度风景')]:
    countries[cid].update({'capital':capital,'mediaId':image,'tagline':tagline})

topic_specs = [
    ('rivers','江河与文明','为什么很多城市在河边？','沿着尼罗河、长江与亚马孙河，把水源、土地与人们的生活放在一起看。','自然','nile-aswan',['egypt-geography','china-geography','brazil-geography']),
    ('nature','雨林与生命','雨林里住着谁？','从一只蛙的照片出发，认识不同环境里的生物。封面拍摄于哥斯达黎加；下面的文章带你继续观察巴西雨林与其他地方的生态。','自然','tree-frog',['brazil-nature','china-nature','egypt-nature']),
    ('daily','世界上的不同生活','人们怎样上学、工作与生活？','照片记录了印度金奈的一间教室。再到埃及、中国与巴西，比较语言、城市和乡村生活；一个例子不能代表所有人的日常。','生活','school',['egypt-people','china-people','brazil-people']),
    ('heritage','石头会讲故事吗？','古建筑留下了什么线索？','看金字塔、长城和历史城市，区分我们看见的证据与自己的猜想。','人文','egypt-giza',['egypt-history','china-history','brazil-history']),
    ('craft','双手里的文化','手艺怎样传到今天？','从编织、剪纸和音乐，认识不同地方的传承。','人文','china-wall',['egypt-culture','china-culture','brazil-culture']),
    ('water','水从哪里来？','干燥的地方也会有绿色吗？','比较河谷、森林与湿地，看看水怎样影响生命。','自然','brazil-iguazu',['egypt-nature','brazil-nature','china-nature']),
    ('observe','学做世界观察员','怎样把发现变成一个好问题？','用地图、照片与文字互相印证，写下你看见、猜想和还想知道的事。','生活','nile-aswan',['egypt-explore','china-explore','brazil-explore']),
    ('protect','一起守护世界','我们为什么要保护遗产与自然？','认识国际合作、生态环境与日常行动之间的联系。','人文','brazil-iguazu',['egypt-history','china-nature','brazil-nature']),
]
for tid,title,question,description,category,mid,articles in topic_specs:
    catalog['topics'].append({'id':tid,'title':title,'question':question,'description':description,'category':category,'mediaId':mid,'articleIds':articles})

# Optional, separately reviewed content packs can add deeper country material.
for supplement in sorted((ROOT / 'tool/content/editorial').glob('*.json')):
    j = json.loads(supplement.read_text())
    if 'country' in j:
        country_patch = j['country']
        country = countries[country_patch['id']]
        merged = merge_country(country, country_patch)
        country.clear()
        country.update(merged)
    for key in ['articles', 'places', 'media', 'exercises', 'archivedExercises']:
        catalog[key] = upsert_records(catalog[key], j.get(key, []),
                                      source=supplement.name, kind=key)

# Archiving removes only the shipped question, not historical user attempts.
# Migration readers can still resolve its corrected article and replacement ID.
catalog['exercises'] = archive_exercises(catalog['exercises'], catalog['archivedExercises'])

# Topics point at the same articles as country chapters; no copied-body counts.
topic_extensions = {
    'nature': ['japan-nature', 'kenya-nature'],
    'daily': ['japan-daily', 'norway-daily', 'kenya-daily', 'usa-new-york-subway'],
    'heritage': ['japan-history', 'norway-history', 'kenya-history'],
    'craft': ['japan-culture', 'kenya-culture', 'usa-new-orleans-jazz'],
    'water': ['norway-geography', 'kenya-nature'],
    'observe': ['japan-questions', 'norway-questions', 'kenya-questions', 'usa-photo-evidence'],
    'protect': ['norway-history', 'kenya-nature'],
}
article_ids = {a['id'] for a in catalog['articles']}
for topic in catalog['topics']:
    topic['articleIds'].extend(aid for aid in topic_extensions.get(topic['id'], []) if aid in article_ids)

order=['china','egypt','usa','gbr','brazil','japan','kenya','norway']
catalog['countries'].sort(key=lambda c:(order.index(c['id']) if c['id'] in order else 99,c['englishName']))
catalog['packSizes']={}
media={m['id']:m for m in catalog['media']}


def linked_media(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key == 'mediaId' and isinstance(child, str) and child:
                yield child
            elif key == 'mediaIds' and isinstance(child, list):
                yield from child
            else:
                yield from linked_media(child)
    elif isinstance(value, list):
        for child in value:
            yield from linked_media(child)


for c in catalog['countries']:
    articles=[a for a in catalog['articles'] if a['countryId']==c['id']]
    places=[p for p in catalog['places'] if p['countryId']==c['id']]
    exercises=[e for e in catalog['exercises'] if e['countryId']==c['id']]
    payload={'country':c,'articles':articles,'places':places,'exercises':exercises}
    ids=set(linked_media(payload))
    byte_count=len(json.dumps(payload,ensure_ascii=False).encode())
    byte_count+=sum((ROOT/media[mid]['asset']).stat().st_size for mid in ids if mid in media and (ROOT/media[mid]['asset']).exists())
    catalog['packSizes'][c['id']]=byte_count

normalize_catalog(catalog)
merge_china(geo)
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
(OUT/'countries.geojson').write_text(json.dumps(geo,ensure_ascii=False,separators=(',',':'))+'\n')
print({k:len(catalog[k]) for k in ['countries','articles','places','topics','exercises','media']})
