import json,hashlib,re,html,sys
from pathlib import Path
from fetch_china_media import image_size
sys.path.insert(0,str(Path(__file__).resolve().parent / "sources"))
from japan_details import SOURCES, EXTRA, LEGACY_EXTRA, PLACES, TERMS
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'tool/content/editorial'
j=json.loads((ROOT/'tool/content/sources/japan_legacy.json').read_text());c=j['country'];articles=j['articles'];sources={s['url'] for s in c['sources']};rows=json.loads((ROOT/'tool/content/sources/japan_expansion.json').read_text())
primary={'ainu':'https://ainu-upopoy.go.jp/en/facility/upopoy/','forest':'https://whc.unesco.org/en/list/662/','himeji':'https://whc.unesco.org/en/list/661/','peace':'https://whc.unesco.org/en/list/775/','volcano':'https://www.data.jma.go.jp/vois/data/report/activity_info/314.html','rice':'https://web-japan.org/kidsweb/cook/rice/rice01.html','miso':'https://web-japan.org/kidsweb/cook/rice/rice01.html'}
primary.update(SOURCES)
geo='https://web-japan.org/kidsweb/explore/nature/index.html'
placespec=[('tokyo','东京 · 隅田川',35.714,139.801),('fuji','富士山',35.361,138.727),('kyoto','京都 · 鸭川',35.011,135.771),('himeji','姬路城',34.839,134.694),('biwa','琵琶湖',35.24,136.08),('hiroshima','广岛和平纪念公园',34.392,132.453),('upopoy','白老 · Upopoy',42.561,141.36),('kushiro','钏路湿地',43.1,144.32),('sakurajima','樱岛',31.583,130.65),('yakushima','屋久岛',30.35,130.5),('naha','那霸',26.212,127.681),('iriomote','西表岛',24.32,123.82)]
media=[]
for r in json.loads((ROOT/'tool/content/sources/japan_media_manifest.json').read_text()):
 key=r['key'];name=next(n for k,n,_,_ in placespec if k==key);a=r['imageinfo'][0];m=a['extmetadata']
 dest=next((ROOT/'assets/atlas').glob('japan-'+key+'.*'));b=dest.read_bytes();w,h=image_size(b)
 clean=lambda s:html.unescape(re.sub('<[^>]+>','',s)).strip()
 media.append(dict(id='japan-photo-'+key,asset=str(dest.relative_to(ROOT)),caption=name+' · '+r['title'][5:],alt=name,credit=clean(m.get('Artist',{}).get('value','Commons作品作者')),sourceUrl=a['descriptionurl'],license=m['LicenseShortName']['value'],licenseUrl=m.get('LicenseUrl',{}).get('value','https://creativecommons.org/publicdomain/mark/1.0/').replace('http://','https://'),kind='realPhoto',width=w,height=h,sha256=hashlib.sha256(b).hexdigest(),captureDate=clean(m.get('DateTimeOriginal',{}).get('value','未注明')),checkedAt='2026-11-11'))
media.append(dict(id='japan-context',asset='assets/atlas/japan-context.png',caption='原创阅读提示卡 · 非地点实拍',credit='世界大百科',sourceUrl='https://web-japan.org/kidsweb/',license='CC BY 4.0',licenseUrl='https://creativecommons.org/licenses/by/4.0/',kind='diagram'))
for card in ['language','school','food','stage','labels','pottery','rice','miso','woodblock','origami']:
 dest=ROOT/('assets/atlas/japan-card-'+card+'.png');b=dest.read_bytes();w,h=image_size(b)
 media.append(dict(id='japan-card-'+card,asset=str(dest.relative_to(ROOT)),caption='原创学习图示 · 非实拍 / 非历史原物',alt='日本模块原创学习卡',credit='世界大百科',sourceUrl='https://web-japan.org/kidsweb/',license='CC BY 4.0',licenseUrl='https://creativecommons.org/licenses/by/4.0/',kind='diagram',width=w,height=h,sha256=hashlib.sha256(b).hexdigest()))
available={x['id'] for x in media}
def mid(key):return 'mount-fuji' if key=='fuji' else 'japan-photo-'+key if 'japan-photo-'+key in available else 'japan-context'
# A neutral original map illustration is used explicitly when a photo is unavailable.
for slug,section,title,place,typ,body in rows:
 id='japan-'+slug;blocks=[{'id':id+f'-b{i+1}','title':t,'text':p} for i,(t,p) in enumerate(zip(['认识线索','进一步了解','把关系连起来','资料的范围','自己试一试'],body.split('|')))]
 url=primary.get(slug,geo);sources.add(url)
 articles.append(dict(id=id,countryId='japan',sectionId=section,title=title,summary=blocks[0]['text'],mediaId=mid(place),blocks=blocks,term='证据',definition='能够支持或检验一种说法的资料与观察。',sourceUrls=[url],readingMinutes=3,revision=1,placeId='japan-'+place))
for a in articles:
 slug=a['id'].removeprefix('japan-')
 for title,body in EXTRA.get(slug,LEGACY_EXTRA.get(slug,[])):
  a['blocks'].append(dict(id=a['id']+f"-b{len(a['blocks'])+1}",title=title,text=body))
 if slug in TERMS:a['term'],a['definition']=TERMS[slug]
 a['glossary']=[dict(term=a['term'],definition=a['definition'])]
 endings={'geography':'岛屿和山地是两种不同分类：一座岛可以同时包含山地与平原。','people':'日语的三类文字会在同一段话中出现，阅读还需要理解句子与语境。','daily':'可以把比较结果记入观察本，并写下还想向同龄孩子了解的一件事。','food':'查看米饭与味噌的后续文章，还能继续认识加工和发酵的不同关系。','culture':'演出是一段随时间展开的过程，舞台照片只能截取其中一个瞬间。','nature':'从屋久岛森林到钏路湿地，再到西表岛海岸，可以比较不同环境，不必急着把它们归为相同景观。','questions':'先看照片，再查看说明与来源，让每一次提问都有能够继续寻找的方向。'}
 if slug in endings:a['blocks'][-1]['text']+=endings[slug]
 a.update(readingMinutes=4,revision=4,updatedAt='2026-11-11')
 if slug in SOURCES:a['sourceUrls']=[SOURCES[slug]]
 if slug in ['geography','nature']:a['placeId']='japan-'+('kushiro' if slug=='geography' else 'yakushima')
 if slug=='pottery':a.pop('placeId',None);a['mediaId']='japan-context'
 if slug=='forest':a['blocks'][1]['text']+='本页照片是山地森林远景，图解另行演示林下层次；照片不能直接辨认全部层次。'
 if slug=='peace':a['sourceUrls'].append('https://www.mofa.go.jp/announce/press/pm/murayama/9508.html')
 sources.update(a['sourceUrls'])
cards={'people':'language','daily':'school','food':'food','culture':'stage','labels':'labels','pottery':'pottery','rice':'rice','miso':'miso','woodblock':'woodblock','origami':'origami'}
for a in articles:
 slug=a['id'].removeprefix('japan-')
 if slug in cards:a['mediaId']='japan-card-'+cards[slug]
# Explicit pedagogical assignments, preserving old IDs for saved readings.
openids=['okinawa-names','tokyo-river','peace','daily','food','culture']
loc={'find-map':('japan','egypt','usa'),'capital':('japan-tokyo','japan-kyoto','japan-naha'),'kyoto-street':('japan-kyoto','japan-himeji','japan-tokyo'),'scale':('japan-naha','japan-tokyo','japan-kushiro'),'geography':('japan-kushiro','japan-naha','japan-kyoto'),'nature':('japan-yakushima','japan-kushiro','japan-tokyo')}
obs=['river','labels','woodblock','himeji','forest','questions']
questions={
'four-islands':('四个大岛是日本全部岛屿吗？','不是，还包括其他岛屿','是，只有四个岛'),
'volcano':('判断火山当前状况需要什么？','机构观测与公告','看一张没有烟的照片'),
'ainu':('应该怎样了解阿伊努文化？','听当事人和可靠机构的介绍','只凭衣着猜测'),
'people':('日语书写常使用哪些文字？','汉字、平假名和片假名','只有汉字'),
'rice':('判断米的产地应该查什么？','包装与供应记录','米饭颜色'),
'miso':('发酵有谁参与？','微生物','金属零件'),
'origami':('折痕可以帮助什么？','对齐纸面与理解步骤','证明纸变成金属'),
'crane':('认识丹顶鹤还要了解什么？','它的栖息环境','只看羽毛颜色'),
'pottery':('陶器年代应根据什么判断？','考古背景与检测资料','只看颜色深浅'),
'railway':('研究开通时的铁路需要什么？','有日期的档案','任意一张今天列车的照片'),
'history':('富士山的文化价值与什么有关？','信仰、旅行和艺术','只与照片数量有关'),
'transfer':('虚构蓝线甲—乙、橙线乙—丙，在哪换乘？','乙站','甲站'),
'river':('观察河流整体走向适合用什么？','地图上的河线','水面的颜色'),
'labels':('练习卡哪个字段表示产地？','③产地：日本','②单位：千克'),
'woodblock':('多色套印需要注意什么？','不同色版的位置对齐','只看纸张大小'),
'himeji':('内部楼层数量应如何确认？','查看平面图与建筑资料','直接数外部屋顶'),
'forest':('照片能直接帮助观察什么？','山脊与大片森林树冠','每棵树的准确年龄'),
'questions':('一张照片能说明什么？','一个视角和时刻的可见线索','全国每个人的一天'),
}
names={'japan':'日本','egypt':'埃及','usa':'美国',**{'japan-'+k:n for k,n,_,_ in placespec}}
ex=[]
for a in articles:
 slug=a['id'].removeprefix('japan-');a.pop('exerciseId',None);a.pop('activity',None)
 if slug in openids:
  a['activity']=dict(id='japan-open-'+slug,type='open',title=a['title'],prompt='写下可直接看见或读到的线索，再写一个需要验证的问题。',fields=['我看见','我猜想','我还想知道'],mediaIds=[a['mediaId']],suggestedArticleIds=[a['id']]);continue
 id='japan-kushiro-location-check' if slug=='geography' else 'japan-'+slug+'-check'
 if slug in loc:
  ids=loc[slug];q={'find-map':'在世界地图找到日本。','capital':'找到东京。','kyoto-street':'找到京都。','scale':'在候选地点中找到那霸。','geography':'找到北海道的钏路湿地。','nature':'找到九州以南的屋久岛。'}[slug];opts=[dict(id=k,text=names[k]) for k in ids];ans=ids[0];typ='location'
 else:
  q,yes,no=questions[slug];opts=[dict(id='a',text=yes),dict(id='b',text=no)];ans='a';typ='observation' if slug in obs else 'choice'
 if len(ex)%2:opts.reverse()
 e=dict(id=id,countryId='japan',articleId=a['id'],type=typ,question=q,options=opts,answerId=ans,hint='回到正文，寻找对应的地点或观察依据。',explanation=next(o['text'] for o in opts if o['id']==ans),evidenceBlockIds=[b['id'] for b in a['blocks']],mapScope='world' if slug=='find-map' else 'country')
 if typ=='observation':e['mediaId']=a['mediaId']
 evidence={'geography':4,'nature':4,'find-map':1,'capital':1,'kyoto-street':1,'scale':5,'four-islands':2,'volcano':4,'ainu':1,'people':1,'rice':5,'miso':2,'origami':2,'crane':2,'pottery':4,'railway':3,'history':2,'transfer':3,'river':4,'labels':2,'woodblock':3,'himeji':3,'forest':6,'questions':2}[slug]
 b=a['blocks'][evidence-1];e['evidenceBlockIds']=[b['id']];e['hint']='再读「'+b['title']+'」。';e['explanation']=b['text']
 if slug in ['transfer','woodblock']:e['diagram']=a['id']
 if slug in ['people','history']:
  old=next(x for x in j['exercises'] if x['articleId']==a['id'])
  e.update(question=old['question'],options=old['options'],answerId=old['answerId'])
 ex.append(e);a['exerciseId']=id
for a in articles:
 if a['id']=='japan-history':a['sectionId']='questions'
 if a['id'].removeprefix('japan-') in cards:a['mediaId']='japan-card-'+cards[a['id'].removeprefix('japan-')]
 if a['id']=='japan-nature':a['mediaId']=mid('iriomote')
 if a['id']=='japan-geography':a['mediaId']=mid('kushiro')
for a in articles:
 if a['id'].removeprefix('japan-') in ['volcano','transfer','rice','miso','woodblock','forest','scale','river']:a['diagram']=a['id']
sections={s:[] for s in ['overview','geography','people','daily','food','culture','landmarks','nature','history','questions']}
for a in articles:sections[a['sectionId']].append(a['id'])
# Original questions article plus two observation guides keep a 3-article questions section.
# Keep three readings in each of the ten sections.
places=[]
for key,name,lat,lon in placespec:
 places.append(dict(id='japan-'+key,countryId='japan',name=name,category='自然' if key in ['fuji','biwa','kushiro','sakurajima','yakushima','iriomote'] else '城市',latitude=lat,longitude=lon,region='日本 · '+('西南岛屿' if lat<28 else '北海道' if lat>41 else '主要列岛'),summary='从地图位置出发，观察这里的景观与资料。',description='此标记是公开地点的代表位置，不代表整个地区范围。图片或示意的类型见图注。',observation='记录一条可见线索与一个待查证的问题。',mediaIds=[mid(key)],sourceUrl=geo,articleIds=[a['id'] for a in articles if a.get('placeId')=='japan-'+key],aliases=[key,name],hotspots=[]))
for p in places:
 key=p['id'].removeprefix('japan-');summary,description,observation,points=PLACES[key]
 p.update(summary=summary,description=description,observation=observation,hotspots=[dict(mediaId=p['mediaIds'][0],x=x,y=y,label=label,explanation=body) for x,y,label,body in points])
 related={'fuji':['volcano','history','questions'],'sakurajima':['volcano','geography'],'iriomote':['nature','scale'],'naha':['scale','okinawa-names','labels'],'yakushima':['forest','nature'],'upopoy':['ainu'],'tokyo':['capital','tokyo-river','transfer','railway'],'kyoto':['kyoto-street'],'biwa':['river'],'himeji':['himeji'],'hiroshima':['peace'],'kushiro':['crane','geography']}[key]
 p['articleIds']=['japan-'+v for v in related];p['sourceUrl']=next(a['sourceUrls'][0] for a in articles if a['id']==p['articleIds'][0])
 p['category']='文化' if key=='upopoy' else '历史' if key in ['himeji','hiroshima'] else p['category']
c.update(revision=4,tagline='从岛屿读懂山海与生活',sections=sections)
c['sources']=[dict(title=next((a['title']+' · 参考资料' for a in articles if u in a['sourceUrls']), '日本模块参考资料'),url=u,checkedAt='2026-11-11') for u in sorted(sources)]
c['editorial']['sections']={s:dict(title={'overview':'初识日本','geography':'地理与山海','people':'人们与语言','daily':'城市的一天','food':'餐桌与食物','culture':'艺术与手作','landmarks':'地标与城市','nature':'自然与生命','history':'物件里的时间','questions':'带着问题观察'}[s],summary=next(a['summary'] for a in articles if a['id']==ids[0]),mediaId=next(a['mediaId'] for a in articles if a['id']==ids[0])) for s,ids in sections.items() if ids}
c['editorial']['directory']={'mediaIds':['mount-fuji',mid('tokyo'),mid('yakushima')]}
c['editorial']['featuredPlaceIds']=['japan-fuji','japan-yakushima','japan-tokyo']
for journey,ids in zip(c['editorial']['journeys'],[['find-map','volcano','forest'],['transfer','labels','tokyo-river'],['pottery','woodblock','railway']]):
 journey['articleIds']=['japan-'+s for s in ids];journey['stopTitles']=[next(a['title'] for a in articles if a['id']=='japan-'+s) for s in ids]
c['editorial']['explore']={'mediaId':mid('yakushima'),'featuredTaskIds':[e['id'] for e in ex[:3]],'categories':[dict(id=k,title=t,mediaId=mid(p)) for k,t,p in [('location','找地图','tokyo'),('observation','看照片','yakushima'),('choice','找证据','himeji'),('open','写观察','kyoto')]]}
c['editorial']['discoveries']={'mediaId':mid('tokyo'),'recommendedPlaceIds':['japan-fuji','japan-yakushima'],'recommendationTitles':['再看富士山','走进森林']}
c['editorial']['timelineTitle']='日本 · 物件与时间'
c['editorial']['timelineIntro']=dict(title='先看物件，再问年代',summary='把实物、档案与今天的景观分开，顺着资料理解历史。',articleId='japan-pottery')
c['editorial']['timeline']=[dict(id='japan-time-'+slug,period=period,title=title,body=body,mediaId=image,articleIds=['japan-'+slug]) for slug,period,title,body,image in [
 ('pottery','史前时期','陶器留下的生活线索','不同陶器年代不同，需要结合出土背景与检测资料，不能只凭颜色判断。','japan-card-pottery'),
 ('peace','1945 年','战争记忆与和平纪念','1945年8月6日广岛遭受原子弹轰炸。把平民经历放回第二次世界大战与日本侵略战争的背景中理解。',mid('hiroshima')),
 ('railway','1964 年','东海道新干线开始运营','开通日期来自铁路机构历史资料；本页城市照片不是1964年开通现场。',mid('tokyo')),
 ('history','2013 年','富士山成为世界文化遗产','遗产资料介绍山峰与信仰、旅行和艺术之间的文化联系。','mount-fuji')]]
for journey,key,subtitle in zip(c['editorial']['journeys'],['fuji','tokyo','himeji'],['找到列岛，认识火山，再走进森林。','读懂连接与标签，观察城市公共空间。','从陶器、版画和铁路档案寻找时间线索。']):
 journey['mediaId']=mid(key);journey['subtitle']=subtitle+' 阅读顺序，不是交通路线。'
# Fix open-activity covers after legacy image corrections.
for a in articles:
 if 'activity' in a:a['activity']['mediaIds']=[a['mediaId']]
(OUT/'japan.json').write_text(json.dumps(dict(country=c,articles=articles,places=places,exercises=ex,archivedExercises=[dict(id='japan-geography-check',countryId='japan',articleId='japan-geography',replacementExerciseId='japan-kushiro-location-check',reason='地理练习改为地图定位，保留旧作答记录。')]),ensure_ascii=False,indent=2)+'\n')
(OUT/'japan_assets.json').write_text(json.dumps(dict(media=media),ensure_ascii=False,indent=2)+'\n')
print(len(articles),'articles',len(places),'places',len(ex),'exercises')
