"""Add the sourced Brasilia reading stop without replacing other Brazil work."""
import hashlib
import json
from pathlib import Path

from fetch_china_media import image_size

ROOT = Path(__file__).resolve().parents[2]
EDITORIAL = ROOT / 'tool/content/editorial'
NASA = 'https://science.nasa.gov/earth/earth-observatory/brasilia-at-night-48963/'
UNESCO = 'https://whc.unesco.org/en/list/445/'
data = json.loads((EDITORIAL / 'brazil.json').read_text())


def upsert(collection, row):
    data[collection] = [r for r in data.get(collection, []) if r['id'] != row['id']] + [row]


blocks = []
for index, line in enumerate((ROOT / 'tool/content/sources/brazil_city.txt').read_text().splitlines()):
    title, text = line.split('|', 1)
    blocks.append(dict(id=f'brazil-brasilia-b{index + 1}', title=title, text=text))

upsert('articles', dict(
    id='brazil-brasilia', countryId='brazil', sectionId='landmarks',
    title='从上方怎样读巴西利亚？', summary='从道路的连接与夜间灯光，观察首都的城市布局。',
    mediaId='brazil-brasilia-night', placeId='brasilia', blocks=blocks,
    sourceUrls=[NASA, UNESCO], readingMinutes=4, revision=1, schemaVersion=1,
    locale='zh-CN', updatedAt='2026-11-11', reviewStatus='sourceChecked',
    term='城市规划', definition='统筹道路、建筑、公共空间等安排，考虑人们的生活需要。',
    exerciseId='brazil-brasilia-check',
))
upsert('exercises', dict(
    id='brazil-brasilia-check', countryId='brazil', articleId='brazil-brasilia', type='choice',
    question='这张夜间照片最适合帮助我们观察什么？',
    options=[dict(id='connections', text='亮起的道路和街区怎样相连'),
             dict(id='addresses', text='每个人的住址')],
    answerId='connections', hint='读最后一段，看看影像能够提供什么线索。',
    explanation='灯光帮助看见一些道路和街区的连接，照片不能说明每个人住在哪里。',
    evidenceBlockIds=['brazil-brasilia-b5'],
))
upsert('places', dict(
    id='brasilia', countryId='brazil', name='巴西利亚', category='城市设计',
    latitude=-15.7939, longitude=-47.8828, region='巴西中西部 · 联邦区',
    summary='在内陆高地，认识一座从整体规划开始的首都。',
    description='道路、居住区、行政建筑与开敞空间共同构成城市布局。夜景照片拍摄于2011年1月8日，不能代替当前街道地图。',
    observation='先找出亮线的连接，再提出一个关于公共空间的问题。',
    mediaIds=['brazil-brasilia-night'], sourceUrl=UNESCO,
    coordinateSource='沿用既有巴西利亚城市观察点，非导航位置。',
    articleIds=['brazil-brasilia'], aliases=['Brasília', 'Brasilia', '巴西首都'], hotspots=[],
))
country = data['country']
country['sections']['landmarks'] = list(dict.fromkeys(country['sections'].get('landmarks', []) + ['brazil-brasilia']))
editorial = country['editorial']
city = next(j for j in editorial['journeys'] if j['id'] == 'city-life')
city['mediaId'] = 'brazil-brasilia-night'
city['articleIds'][0] = 'brazil-brasilia'
city['stopTitles'][0] = '读懂城市布局'
editorial['directory']['mediaIds'] = ['brazil-meeting-waters', 'brazil-brasilia-night', 'brazil-iguazu']
for section in ['overview', 'landmarks', 'history']:
    editorial['sections'][section]['mediaId'] = 'brazil-brasilia-night'
for title, url in [('NASA：马瑙斯两河交汇', 'https://science.nasa.gov/earth/earth-observatory/meeting-of-the-waters-79111/'),
                   ('IBGE：六个陆地生物群系', 'https://educa.ibge.gov.br/jovens/conheca-o-brasil/territorio/18307-biomas-brasileiros.html'),
                   ('NASA：巴西利亚夜景', NASA), ('UNESCO：巴西利亚', UNESCO)]:
    if not any(s['url'] == url for s in country['sources']):
        country['sources'].append(dict(title=title, url=url, checkedAt='2026-11-11'))
(EDITORIAL / 'brazil.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')

path = ROOT / 'assets/atlas/brazil-brasilia-night.jpg'
raw = path.read_bytes()
width, height = image_size(raw)
media = dict(
    id='brazil-brasilia-night', asset=str(path.relative_to(ROOT)),
    caption='巴西利亚夜景，国际空间站宇航员实拍，2011年1月8日。非实时影像。',
    alt='黑暗背景上，金黄色灯光勾勒出巴西利亚道路和街区的连接。',
    credit='NASA / Expedition 26 crew; ISS Crew Earth Observations, Johnson Space Center',
    sourceUrl=NASA, license='NASA educational/informational use; source credited',
    licenseUrl='https://www.nasa.gov/nasa-brand-center/images-and-media/',
    kind='photo', width=width, height=height, sha256=hashlib.sha256(raw).hexdigest(),
    downloadUrl='https://assets.science.nasa.gov/dynamicimage/assets/science/esd/eo/images/imagerecords/48000/48963/ISS026-E-016368_lrg.jpg',
    captureDate='2011-01-08', checkedAt='2026-11-11',
    processing='NASA发布版本已裁剪并增强对比度、移除镜头伪影；App保留下载字节。',
)
asset_path = EDITORIAL / 'brazil_assets.json'
assets = json.loads(asset_path.read_text())
assets['media'] = [r for r in assets['media'] if r['id'] != media['id']] + [media]
asset_path.write_text(json.dumps(assets, ensure_ascii=False, indent=2) + '\n')
