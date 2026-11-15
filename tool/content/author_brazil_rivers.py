"""Idempotently add Brazil river learning content; preserve prior stable records."""
import json,hashlib
from pathlib import Path
from fetch_china_media import image_size
ROOT=Path(__file__).resolve().parents[2]
p=ROOT/'tool/content/editorial/brazil.json';d=json.loads(p.read_text());source='https://science.nasa.gov/earth/earth-observatory/meeting-of-the-waters-79111/'
texts={}
for chunk in (ROOT/'tool/content/sources/brazil_rivers.txt').read_text().split('@@ ')[1:]:
 lines=chunk.strip().splitlines();texts[lines[0]]=[l.split('|',1) for l in lines[1:]]
def put(kind,row):
 d[kind]=[r for r in d.get(kind,[]) if r['id']!=row['id']]+[row]
for slug,title,section in [('meeting-waters','两种颜色的河水为什么相遇？','geography'),('six-biomes','巴西到处都是雨林吗？','geography'),('water-evidence','两河的颜色能判断水质吗？','questions')]:
 id='brazil-'+slug;blocks=[dict(id=f'{id}-b{i+1}',title=t,text=text) for i,(t,text) in enumerate(texts[slug])];url='https://educa.ibge.gov.br/jovens/conheca-o-brasil/territorio/18307-biomas-brasileiros.html' if slug=='six-biomes' else source
 a=dict(id=id,countryId='brazil',sectionId=section,title=title,summary=blocks[0]['text'],mediaId='brazil-meeting-waters' if slug!='six-biomes' else 'brazil-iguazu',blocks=blocks,sourceUrls=[url],readingMinutes=4,revision=1,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-11',reviewStatus='sourceChecked',term='生物群系' if slug=='six-biomes' else '汇合',definition='较大区域尺度上的生物与环境组合。' if slug=='six-biomes' else '两条或多条河流在一处相遇。')
 if slug!='six-biomes':a['placeId']='brazil-manaus-meeting-waters'
 if slug=='water-evidence':a['activity']=dict(id='brazil-o-water',type='open',title='看见与猜想',prompt='描述一种可见线索，再提出一个需要验证的问题。',fields=['我看见','我猜想','我还想知道'],mediaIds=['brazil-meeting-waters'],suggestedArticleIds=['brazil-meeting-waters'])
 else:
  eid='brazil-'+slug+'-check';a['exerciseId']=eid
  a['diagram']='brazil-'+slug
  e=dict(id=eid,countryId='brazil',articleId=id,type='choice',question='颜色能直接说明水质吗？' if slug=='meeting-waters' else '巴西到处都是雨林吗？',options=[dict(id='evidence',text='不能，还需要取样与测量' if slug=='meeting-waters' else '不是，还有湿地、草地等环境'),dict(id='appearance',text='能，只看颜色就够了' if slug=='meeting-waters' else '是，一张雨林照片能代表全国')],answerId='evidence',hint='回到最后一段，想想结论需要哪些证据。',explanation=blocks[-1]['text'],evidenceBlockIds=[blocks[-1]['id']])
  put('exercises',e)
 put('articles',a)
 sections=d['country']['sections'];sections[section]=list(dict.fromkeys(sections.get(section, ['brazil-geography'] if section=='geography' else ['brazil-explore'])+[id]))
put('places',dict(id='brazil-manaus-meeting-waters',countryId='brazil',name='马瑙斯 · 两河交汇',category='自然',latitude=-3.135,longitude=-59.9,region='巴西北部 · 亚马孙水系',summary='在两种水色中寻找汇合的线索。',description='内格罗河与索利蒙伊斯河在马瑙斯附近汇合。卫星影像摄于2012年6月17日，不代表当前水位。地图点为交汇区域代表位置，不是固定水色边界。',observation='先描述水色，再区分观察与猜想。',mediaIds=['brazil-meeting-waters'],sourceUrl=source,coordinateSource='NASA EO-1 影像的马瑙斯交汇区域代表锚点，WGS84',aliases=['Manaus','Rio Negro','Solimões','马瑙斯','内格罗河'],articleIds=['brazil-meeting-waters','brazil-water-evidence'],hotspots=[]))
e=d['country']['editorial'];e['questionArticleIds']=['brazil-meeting-waters','brazil-six-biomes'];e['journeys'][0]['articleIds'][0]='brazil-meeting-waters';e['journeys'][0]['stopTitles'][0]='两河交汇';e['journeys'][0]['mediaId']='brazil-meeting-waters';e['featuredPlaceIds']=['brazil-manaus-meeting-waters','iguazu'];e.setdefault('directory', {})['mediaIds']=['brazil-meeting-waters', 'brazil-brasilia-night' if (ROOT/'assets/atlas/brazil-brasilia-night.jpg').exists() else 'brazil-iguazu', 'brazil-iguazu'];e['explore']['featuredTaskIds']=['brazil-location','brazil-meeting-waters-check','brazil-six-biomes-check'];e['sections']['geography']['mediaId']='brazil-meeting-waters';e['sections']['geography']['summary']='从两河交汇到六个生物群系，认识不同尺度的环境。'
d['country']['revision']=2
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
file=ROOT/'assets/atlas/brazil-meeting-waters.jpg';b=file.read_bytes();w,h=image_size(b)
m=dict(id='brazil-meeting-waters',asset='assets/atlas/brazil-meeting-waters.jpg',caption='内格罗河与索利蒙伊斯河交汇，NASA EO-1 ALI 自然色卫星影像，2012年6月17日。非实时影像。',alt='深色与黄褐色河水在马瑙斯附近汇合，周围为陆地与城市。',credit='NASA Earth Observatory / Jesse Allen and Robert Simmon; NASA EO-1 team',sourceUrl=source,license='NASA educational/informational use; source credited',licenseUrl='https://www.nasa.gov/nasa-brand-center/images-and-media/',kind='satellite',width=w,height=h,sha256=hashlib.sha256(b).hexdigest(),downloadUrl='https://assets.science.nasa.gov/dynamicimage/assets/science/esd/eo/images/imagerecords/79000/79111/manaus_ali_2012169_lrg.jpg',captureDate='2012-06-17',checkedAt='2026-11-11',processing='保留NASA原始下载图像。')
assets_path=ROOT/'tool/content/editorial/brazil_assets.json'
assets=json.loads(assets_path.read_text()) if assets_path.exists() else {'media':[]}
assets['media']=[row for row in assets['media'] if row['id']!=m['id']]+[m]
assets_path.write_text(json.dumps(assets,ensure_ascii=False,indent=2)+'\n')
