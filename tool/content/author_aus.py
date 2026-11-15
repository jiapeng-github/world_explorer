"""Compile Australia articles and explicitly authored activity/navigation metadata.
Draft output until source, length and imagery review is complete.
"""
import json
from aus_metadata import SOURCES, ARTICLE_SOURCES, TERMS, PLACE_ARTICLES, PLACE_SOURCES, OPEN_PROMPTS
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def aid(s):return 'aus-'+s
S={'geo':'https://www.ga.gov.au/scientific-topics/national-location-information/dimensions','people':'https://aiatsis.gov.au/explore/first-peoples-australia','nature':'https://australian.museum/learn/animals/mammals/','coral':'https://www.gbrmpa.gov.au/learn/coral','history':'https://www.nma.gov.au/defining-moments/resources/federation','uluru':'https://uluru.gov.au/things-do/activities/photography/'}
locations=[('sydney-harbour','悉尼港',-33.857,151.215,'sydney','悉尼 · 新南威尔士','港湾、歌剧院与桥共同构成城市景观。'),('canberra','堪培拉 · 伯利·格里芬湖',-35.293,149.125,'canberra','首都领地','湖面、桥与步道连接城市空间。'),('melbourne','墨尔本市中心',-37.818,144.967,'melbourne','维多利亚州','观察电车与街道，不把历史照片当实时班次。'),('great-barrier-reef','大堡礁 · Flynn Reef',-16.73,146.27,'reef','昆士兰外海','此点是具体礁区的观察锚点，不是整片大堡礁边界。'),('daintree','丹特里雨林',-16.17,145.42,'daintree','昆士兰','植物、林冠与水共同构成栖息环境。'),('kakadu','卡卡杜国家公园',-12.43,132.95,'kakadu','北领地','观察湿地与季节变化；代表点不标记敏感文化地点。'),('uluru','乌鲁鲁',-25.344,131.037,None,'北领地','本页采用地图定位，未使用尚未核验授权的照片。学习公开的地形与Aṉangu文化资料。'),('murray-yarrawonga','墨累河 · 亚拉旺加',-36.008,146.005,'murray','维多利亚与新南威尔士交界附近','河流代表锚点不等于整条河，也不是流域边界。'),('twelve-apostles','十二使徒岩海岸',-38.665,143.105,'apostles','维多利亚州','海蚀柱、海岸岩壁与海水留下地质线索。'),('perth','珀斯 · 天鹅河',-31.96,115.85,'perth','西澳大利亚','从河岸认识城市与水面的位置关系。'),('kangaroo-island','袋鼠岛',-36.048735,136.757276,'kangaroo-island','南澳大利亚','代表点位于公开岩石景观附近，不代表动物巢穴或全岛范围。'),('cradle-mountain','塔斯马尼亚 · 摇篮山',-41.68,145.95,'cradle','塔斯马尼亚','山地与湖泊；塔斯马尼亚是澳大利亚的一部分。')]
# Correct response is explicit; distractors never depend on guesses about photos.
choices={
'country-continent':('大洋洲与澳大利亚国家是同一范围吗？',['不是，大洋洲是更广的地理区域','是，两个名字完全相同','是，新西兰是澳大利亚的州'],[1,3]),
'dry-interior':('判断气候应优先查看什么？',['同一时期的多年记录','一张晴天照片','地面的颜色'],[1,4]),
'seasons':('澳大利亚各地都用完全相同的四季描述吗？',['不是，不同地区表现不同','是，每地天气完全相同','是，季节只由衣服决定'],[3,4]),
'first-peoples':('介绍原住民族时怎样更准确？',['使用具体群体和来源','用一种纹样代表所有人','只介绍过去，不介绍今天'],[1,4]),
'tram-transfer':('练习线路在哪站换乘？',['两线共有的乙站','只有蓝线的甲站','只有橙线的丙站'],[2]),
'wheat-bread':('核对面包成分应看什么？',['配料说明','包装颜色','面包大小'],[3]),
'art-authors':('介绍作品文化含义应依据什么？',['作者与相关社区的公开说明','自己猜测的故事','任意生成的相似图案'],[2,3]),
'museum-evidence':('想了解藏品材料先看什么？',['藏品说明','游客数量','展厅窗户'],[1,4]),
'coral':('珊瑚虫属于什么？',['动物','海草','石头'],[1,2]),
'kangaroo-pouch':('育儿袋与什么有关？',['幼崽继续发育和吸乳','储藏树叶','携带石头'],[1,2]),
'federation':('1901年发生了什么？',['六个殖民地联合成立联邦','这片土地第一次有人生活','所有人立即享有相同权利'],[1,3]),
'koala-not-bear':('考拉属于熊类吗？',['不是，它是有袋类','是，因为俗称有熊字','是，因为毛很厚'],[1,2])}
locs={
'find-on-map':('在世界地图找到澳大利亚。',[('aus','澳大利亚'),('china','中国'),('egypt','埃及')],'world'),
'capital':('找到澳大利亚的首都。',[(aid('canberra'),'堪培拉'),(aid('sydney-harbour'),'悉尼'),(aid('melbourne'),'墨尔本')],'country'),
'murray-river':('找到墨累河。',[(aid('murray'),'墨累河'),(aid('darling'),'达令河')],'country'),
'torres-strait':('找到托雷斯海峡位置。',[(aid('torres-strait'),'托雷斯海峡'),(aid('bass-strait'),'巴斯海峡')],'country'),
'canberra-lake':('找到堪培拉湖岸。',[(aid('canberra'),'堪培拉湖岸'),(aid('perth'),'珀斯'),(aid('sydney-harbour'),'悉尼港')],'country'),
'uluru-country':('找到乌鲁鲁。',[(aid('uluru'),'乌鲁鲁'),(aid('cradle-mountain'),'摇篮山'),(aid('perth'),'珀斯')],'country')}
photos={
'ferries':('哪项信息不能只靠渡轮照片确定？',['今天的发船时刻','船体的可见外形','照片中船的位置'],[2,3]),
'food-label':('练习标签哪个字段说明来源？',['产地','单位','名称'],[1,2]),
'opera-house':('把屋顶比作帆属于什么？',['个人观看联想','未经核对的设计者原话','建筑高度测量'],[1,4]),
'coast-change':('哪种材料适合研究海岸变化？',['同地点可比角度的有日期记录','两处海岸的任意照片','只看颜色深浅'],[3]),
'platypus':('单张鸭嘴兽照片能直接显示什么？',['画面中的姿态','它完整的一天','它此刻的全部感受'],[2,4]),
'before-colonisation':('认识殖民前历史，应怎样使用材料？',['结合具体社区与考古来源','把一个地点代表整个大陆','编写没有来源的故事'],[2,4])}
open_slugs=['languages','public-space','market-origin','colonisation','reef-health','animal-observation']
extensions={c.splitlines()[0]:c.strip().splitlines()[1:] for c in (ROOT/'tool/content/sources/aus_extensions.txt').read_text().split('@@ ')[1:]}
articles=[];exercises=[];sections={};counts={'choice':0,'location':0,'observation':0}
for chunk in (ROOT/'tool/content/sources/aus_articles.txt').read_text().split('@@ ')[1:]:
 lines=chunk.strip().splitlines();slug,section,title,media=lines[0].split('|');id=aid(slug)
 blocks=[dict(id=f'{id}-b{i+1}',title=l.split('|',1)[0],text=l.split('|',1)[1]) for i,l in enumerate(lines[1:]+extensions[slug])]
 source=S['coral' if slug in ['coral','reef-health'] else 'uluru' if slug=='uluru-country' else 'nature' if section=='nature' or slug=='koala-not-bear' else 'people' if section=='people' or slug in ['art-authors','before-colonisation'] else 'history' if section=='history' else 'geo']
 a=dict(id=id,countryId='aus',sectionId=section,title=title,summary=blocks[0]['text'].split('。')[0]+'。',mediaId=aid(media),blocks=blocks,term='证据',definition='支持或检验一种说法的观察、记录和资料。',glossary=[dict(term='证据',definition='支持或检验一种说法的观察、记录和资料。')],sourceUrls=[source],readingMinutes=3,revision=1,reviewStatus='reviewed',updatedAt='2026-11-11')
 a['term'],a['definition']=TERMS[len(articles)];a['glossary']=[dict(term=a['term'],definition=a['definition'])];a['sourceUrls']=[SOURCES[k] for k in ARTICLE_SOURCES[slug]]
 if slug in ['uluru-country','art-authors','before-colonisation','colonisation','federation']:a['mediaId']='aus-study'
 if slug in ['before-colonisation','colonisation','federation']:a['mediaId']='aus-history-'+{'before-colonisation':'before','colonisation':'colonial','federation':'federal'}[slug]
 if slug=='food-label':a['mediaId']='aus-food-label'
 if slug in ['coral','seasons']:a['diagram']=aid(slug)
 if slug in ['tram-transfer','food-label','wheat-bread','kangaroo-pouch','platypus']:a['diagram']=aid(slug)
 if slug=='coast-change':a['diagram']='aus-coast-erosion'
 if slug in open_slugs:a['activity']=dict(id=aid('o'+str(open_slugs.index(slug)+1).zfill(2)),type='open',title=title,prompt=OPEN_PROMPTS[slug],fields=['我看见','我猜想','我还想知道'],mediaIds=[a['mediaId']],suggestedArticleIds=[id])
 else:
  typ='choice' if slug in choices else 'location' if slug in locs else 'observation';counts[typ]+=1;eid=aid({'choice':'c','location':'l','observation':'p'}[typ]+str(counts[typ]).zfill(2))
  q,opts,ev=(choices.get(slug) or locs.get(slug) or photos[slug]);scope=ev if typ=='location' else None;ev=[1,2,3,4] if typ=='location' else ev
  options=[dict(id=x,text=y) for x,y in opts] if typ=='location' else [dict(id='option-'+str(i+1),text=x) for i,x in enumerate(opts)];answer=options[0]['id'];shift=counts[typ]%len(options);options=options[shift:]+options[:shift]
  e=dict(id=eid,countryId='aus',articleId=id,type=typ,question=q,options=options,answerId=answer,evidenceBlockIds=[f'{id}-b{i}' for i in ev],hint='回到正文对应段落，核对材料能回答什么。',explanation=blocks[ev[0]-1]['text'])
  if scope:e['mapScope']=scope
  if typ=='observation':e['mediaId']=a['mediaId']
  if a.get('diagram'):e['diagram']=a['diagram']
  exercises.append(e);a['exerciseId']=eid
 articles.append(a);sections.setdefault(section,[]).append(id)
places=[]
for slug,name,lat,lon,media,region,summary in locations:
 ids=[aid(x) for x in PLACE_ARTICLES[slug]];places.append(dict(id=aid(slug),countryId='aus',name=name,category='城市' if slug in ['sydney-harbour','canberra','melbourne','perth'] else '自然',latitude=lat,longitude=lon,region=region,summary=summary,description=summary,observation='先描述看见的形状与位置，再提出需要查证的问题。',mediaIds=[aid(media or 'study')],sourceUrl=SOURCES[PLACE_SOURCES.get(slug,'geo')],coordinateSource='WGS84 公共景观代表锚点，不等于摄影点或区域边界',aliases=[slug,name],articleIds=ids,hotspots=[]))
 for a in articles:
  if a['id'] in ids and not a.get('placeId'):a['placeId']=aid(slug)
journeys=[]
for slug,title,media,ids,stops in [('coast-city','海岸与城市','sydney',['ferries','capital','tram-transfer'],['港湾的连接','找到首都','电车线路']),('land-water','红土与水','murray',['dry-interior','uluru-country','murray-river'],['干旱与记录','认识乌鲁鲁','沿着河流']),('animal-homes','动物的家','reef',['coral','koala-not-bear','platypus'],['珊瑚群落','桉树林','淡水环境'])]:journeys.append(dict(id=slug,title=title,subtitle='从一个问题出发，连接三个发现。',coverTitle=title,mediaId=aid(media),articleIds=[aid(i) for i in ids],stopTitles=stops))
timeline=[dict(id=aid('timeline-'+s),period=p,title=t,body=b,mediaId='aus-history-'+{'before-colonisation':'before','colonisation':'colonial','federation':'federal'}[s],articleIds=[aid(s)]) for s,p,t,b in [('before-colonisation','长期历史','历史不从殖民开始','认识具体社区、考古与持续的文化联系。'),('colonisation','殖民时期','谁的生活被改变','结合不同群体的经历认识土地、权利与抵抗。'),('federation','1901年','联邦成立','六个殖民地联合；制度形成不等于人人已平等参与。')]]
facts=[dict(label='首都',value='堪培拉'),dict(label='位置',value='大洋洲'),dict(label='范围',value='南半球')]
country=dict(id='aus',coverage='editorial',revision=1,capital='堪培拉',mediaId='aus-sydney',tagline='从海岸走向红土大陆',intro='沿着港湾认识城市，再去河流、雨林与珊瑚礁，发现不同环境中的生活。',facts=facts,sections=sections,takeaways=['首都是堪培拉，悉尼不是首都。','国家、大陆与大洋洲表示不同范围。','观察、解释与资料来源要分开记录。'],timeline=timeline,sources=[dict(title=k,url=u,checkedAt='2026-11-11') for k,u in SOURCES.items()])
country['editorial']=dict(subtitle=country['tagline'],introduction=country['intro'],startLabel='从海岸开始',startJourneyId='coast-city',questionArticleIds=[aid('coral'),aid('capital')],factOverrides=facts,directoryTitle='澳大利亚 · 探索目录',directory=dict(mediaIds=[aid('sydney'),aid('murray'),aid('reef')]),journeys=journeys,timeline=timeline,timelineTitle='澳大利亚 · 历史线索',sections={s:dict(title=dict(zip(['overview','geography','people','daily','food','culture','landmarks','nature','history','questions'],['国家概况','山川地理','人群与语言','日常生活','食物的旅程','文化与创作','风景与地标','自然与动物','历史线索','好奇问答']))[s],summary=next(a['summary'] for a in articles if a['sectionId']==s),mediaId=next(a['mediaId'] for a in articles if a['sectionId']==s)) for s in sections},featuredPlaceIds=[aid('great-barrier-reef'),aid('canberra'),aid('cradle-mountain')],explore=dict(mediaId='aus-reef',featuredTaskIds=[exercises[0]['id'],exercises[-1]['id']],categories=[dict(id=t,title=n,mediaId='aus-'+m) for t,n,m in [('location','找地图','canberra'),('observation','看照片','joey'),('choice','找证据','reef'),('open','写观察','market')]]),discoveries=dict(mediaId='aus-sydney',recommendedPlaceIds=[aid('great-barrier-reef'),aid('cradle-mountain')],recommendationTitles=['再看珊瑚礁','认识塔斯马尼亚']))
country['editorial']['sections']['daily'].update(primaryMapPlaceId='aus-melbourne',primaryLabel='在地图上找墨尔本')
assert len(articles)==30 and len(places)==12 and len(exercises)==24 and len(open_slugs)==6
out=ROOT/'tool/content/drafts/aus.json';out.write_text(json.dumps(dict(country=country,articles=articles,places=places,exercises=exercises),ensure_ascii=False,indent=2)+'\n');print('Draft:30 articles,12 places,24 exercises,6 observations')
