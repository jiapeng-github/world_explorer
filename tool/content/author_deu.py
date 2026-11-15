"""Build Germany's authored content; media and GIS have separate provenance ledgers."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'tool/content/editorial'
def aid(s):return 'deu-'+s
def mid(n):return f'deu-m{n:02}'
S={
'geo':('德国概况 · 联邦政治教育中心','https://www.bpb.de/kurz-knapp/lexika/kosmos-weltalmanach/65657/deutschland/'),
'states':('德国联邦议院 · 联邦与州职责','https://www.bundestag.de/en/parliament/function/legislation/competencies-245700'),
'rhine':('德国联邦水文研究所 · 莱茵河流域','https://undine.bafg.de/rhein/rheingebiet_en.html'),
'climate':('DWD · 天气与气候','https://www.dwd.de/EN/ourservices/nationalclimatereport/download_report_edition-3.pdf?__blob=publicationFile&v=4'),
'sorbian':('Domowina / FUEN · 索布人的语言与劳西茨','https://nks.fuen.org/assets/upload/editor/docs/doc_h45BcZWn_NKS%20brochure_final_v2_Q.pdf'),
'forest':('亚斯蒙德国家公园 · 倒木与森林循环','https://www.nationalpark-jasmund.de/fileadmin/jasmund/Inhaltsseiten/service/Downloads/fb_jas_gross.pdf'),
'wadden':('瓦登海国家公园 · 动物与潮沟','https://www.nationalpark-wattenmeer.de/wissen/natur/tiere/'),
'heritage':('UNESCO · 跨国瓦登海','https://whc.unesco.org/en/list/1314/'),
'print':('Europeana / 法国国家图书馆 · 印刷史','https://www.europeana.eu/en/stories/from-manuscript-production-to-the-printing-press'),
'workshop':('德意志博物馆 · 印刷工作室','https://www.deutsches-museum.de/museum/ueber-uns/werkstaetten/druckerei'),
'bauhaus':('德绍包豪斯基金会 · 校舍','https://bauhaus-dessau.de/en/venues/bauhaus-building/'),
'castle':('巴伐利亚宫殿管理局 · 新天鹅堡建筑史','https://www.neuschwanstein.de/englisch/palace/history.htm'),
'port':('汉堡港 · 多式联运','https://www.hafen-hamburg.de/de/intermodal/'),
'potato':('FAO · 土豆的跨洲传播','https://www.fao.org/newsroom/story/the-potatos-travel-through-ages-and-continents/'),
'bread':('法国自然历史博物馆 · 面包的制作','https://www.mnhn.fr/fr/comment-et-depuis-quand-fabrique-t-on-du-pain'),
'holocaust':('美国大屠杀纪念博物馆 · 大屠杀概述','https://encyclopedia.ushmm.org/content/en/article/introduction-to-the-holocaust'),
'war':('美国大屠杀纪念博物馆 · 纳粹政权与战争','https://encyclopedia.ushmm.org/content/en/question/how-did-the-nazis-and-their-collaborators-implement-the-holocaust'),
'unity':('德国联邦议院 · 通向统一','https://www.bundestag.de/dokumente/textarchiv/deutsche-einheit-202098'),
}
rows=[]
for line in (ROOT/'docs/countries/deu/CONTENT_PLAN.md').read_text().splitlines():
 c=[s.strip() for s in line.split('|')]
 if len(c)==6 and c[2].startswith('deu-'):rows.append(c[1:5])
texts={}
for c in (ROOT/'tool/content/sources/deu_articles.txt').read_text().split('@@ ')[1:]:
 l=c.strip().splitlines();texts[aid(l[0])]=[p.split('|',1) for p in l[1:]]
media=[1,2,2,1,22,23,31,3,24,10,30,11,27,28,29,26,32,14,6,8,16,33,20,22,13,36,34,4,21,18]
keys=['geo','states','geo','rhine','geo','climate','geo','sorbian','sorbian','geo','geo','geo','bread','potato','potato','print','workshop','bauhaus','rhine','port','castle','forest','wadden','geo','print','holocaust','unity','rhine','wadden','forest']
placekeys=['berlin','berlin','berlin','koblenz','alps','alps','berlin','berlin','bautzen','leipzig','leipzig','leipzig',None,None,'berlin','mainz',None,'dessau','cologne','hamburg','castle','jasmund','wadden','alps','mainz',None,'berlin','koblenz','wadden','jasmund']
diagrams={3:'river',4:'landscapes',9:'transfer',13:'food-flow',15:'type',16:'rhythm',21:'deadwood',22:'tides',27:'river'}
terms=[('国家范围','国家在地图上所表示的地域范围。'),('联邦州','德国联邦制度下的组成单位。'),('首都','国家主要中央机构所在地。'),('汇合','两条水道相遇并连接。'),('自然分区','依照地形等自然特点认识的区域。'),('气候','较长时期内天气的平均特征与变化。'),('地名','人们对地点使用的名称。'),('多语','使用或呈现多种语言。'),('文化区域','具有历史与文化联系的区域，不等同于行政区。'),('换乘','从一条交通线路转到另一条。'),('产地','商品所声明的生产或收获地点，须按具体说明理解。'),('公共空间','供人们共同使用的空间。'),('发酵','微生物参与、使材料变化的过程。'),('块茎','植物茎膨大形成的储藏器官。'),('供应','商品从生产走向使用者的过程。'),('活字','可独立排列并重复使用的印刷字块。'),('节拍','音乐中有规律的时间单位。'),('设计','围绕用途和条件安排形式与结构。'),('河岸','河道与两侧陆地相接的地方。'),('码头','船舶停靠和货物或人员转换的设施。'),('史料','用来认识和核对历史的材料。'),('分解','有机物在生物等作用下逐步变化的过程。'),('潮沟','潮滩上供海水往返的沟道。'),('山脉','相互联系、延伸分布的一系列山地。'),('传播','技术或知识被传递和采用的过程。'),('档案','保存下来、可以查考的活动记录。'),('统一','这里指一九九〇年德国实现政治统一。'),('水系','相互联系的河流及其他水体。'),('猜想','还需要证据检验的解释。'),('对照','在说明条件后比较材料的异同。')]
C=[
('德国的联邦州属于哪一层级？',['国家内部的组成单位','十六个无关的独立国家','十六条河流'],[1,2]),
('河流到国界时一定会结束吗？',['不一定，河流可以跨越国界','一定，所有河流遇国界就停','只有地图上的水能流动'],[1,4]),
('怎样比较两地气候更合适？',['同参考期的多年记录','两张无日期照片','只看今天的气温'],[2,3]),
('虚构线路应该在哪里换乘？',['两条线共有的乙站','只有蓝线的甲站','只在橙线上的丙站'],[2,4]),
('什么帮助许多发酵面包形成孔洞？',['面团留住部分发酵气体','面粉变成石头','有人逐个戳洞'],[1,2]),
('土豆走到餐桌要区分什么？',['种植、运输和加工等阶段','销售地点一定等于起源地','所有土豆都在厨房生长'],[1,3,4]),
('活字为什么可以再次使用？',['字块可拆开并重新排列','每页只能使用一次','印完就会变成纸'],[1,3]),
('码头的重要作用是什么？',['衔接水路和陆地运输','只用来装饰岸边','保证所有货物来自附近'],[1,2]),
('森林里的倒木有什么作用？',['提供栖息空间并参与分解循环','完全没有生命联系','立即变成一棵新树'],[1,2,3]),
('怎样准确描述古腾堡的贡献？',['欧洲印刷的重要改进；东亚已有更早实践','世界所有印刷都始于他','活字之前没有任何印刷'],[1,2]),
('1989与1990是同一事件吗？',['不是，开放边界与统一有先后','是同一天的两个名字','都是某座城堡开工'],[1,2,3]),
('河流线和国界线是什么关系？',['表示不同事物，有的河段与边界接近','所有河流都是国界','两种线都表示铁路'],[1,2]),
]
L=[
('在世界地图上找到德国。',[('deu','德国'),('egypt','埃及'),('usa','美国')],[1,3]),
('在德国地图找到柏林。',[(aid('berlin'),'柏林'),(aid('hamburg'),'汉堡'),(aid('munich'),'慕尼黑')],[1,4]),
('从北海往内陆，先找到北部低地教学区域。',[(aid('terrain-north'),'北部低地'),(aid('terrain-central'),'中部山地'),(aid('terrain-alps'),'德国阿尔卑斯')],[1,2,4]),
('哪个教学区域表示德国境内劳西茨的大致位置？',[(aid('terrain-lusatia'),'劳西茨文化区域'),(aid('terrain-north'),'北部低地'),(aid('terrain-alps'),'德国阿尔卑斯')],[1,4]),
('找到德国西部莱茵河边的科隆。',[(aid('cologne'),'科隆'),(aid('berlin'),'柏林'),(aid('leipzig'),'莱比锡')],[1,4]),
('点选德国境内阿尔卑斯的教学区域。',[(aid('terrain-alps'),'德国阿尔卑斯'),(aid('terrain-central'),'中部山地'),(aid('terrain-north'),'北部低地')],[1,4]),
]
P=[
('名称卡里的 Berlin 和柏林表示什么？',['同一座城市的不同语言名称','两个国家','两个人的名字'],[1,2],31),
('哪个字段回答“来自哪里”？',['③产地：德国','①名称：苹果','②单位：千克'],[2,3],30),
('哪组回应保留了示范的四拍等间隔？',['1—2—3—4，间隔相同','只拍两下','1—2——3—4，间隔不同'],[2,3],32),
('哪种材料最适合核对开工年代？',['有明确来源的建筑史资料','没有日期的风景照片','想象中的城堡故事'],[2,3,4],17),
('照片中的哪个位置是弯曲的潮沟？',['滩面中的水道','画面上方背景','另一片无水滩面'],[2],20),
('哪种历史材料更适合查考？',['有作者或机构、日期和保存信息的记录','只凭外貌猜测身份','没有来源的想象故事'],[3,4],36),
]
open_prompts=[('城市中的语言','记录公共信息中的文字；分开可见内容和对居民语言的猜想。',[3,31]),('街道里的空间','找一种公共设施，写下它可能的用途与待核对的问题。',[10,11]),('市场与产地','选一种能看清的食物，哪些产地资料还需要查？',[29,30]),('椅子的设计问题','观察身边的椅子，描述材料、用途与一个改进问题。',[14,15]),('看见与猜想','从潮滩照片写一条可见线索和一个待验证的解释。',[20,21]),('两张森林照片','比较树干与地面；哪些条件不同或未知？',[18,19])]
articles=[];exercises=[]
for i,(section,id,title,activity) in enumerate(rows):
 blocks=[dict(id=f'{id}-b{j+1}',title=t,text=p) for j,(t,p) in enumerate(texts[id])]
 a=dict(id=id,countryId='deu',sectionId=section,title=title,summary=blocks[0]['text'].split('。')[0]+'。',mediaId=mid(media[i]),blocks=blocks,term=terms[i][0],definition=terms[i][1],glossary=[dict(term=terms[i][0],definition=terms[i][1])],sourceUrls=[S[keys[i]][1]],readingMinutes=4,revision=1,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-11',reviewStatus='sourceChecked')
 if placekeys[i]:a['placeId']=aid(placekeys[i])
 if i in diagrams:a['diagram']=aid(diagrams[i])
 for b,n in {3:[(1,4)],6:[(1,31)],8:[(2,24)],10:[(1,30)],15:[(1,13)],16:[(1,32)],20:[(2,17)],21:[(1,33)],22:[(1,21)],24:[(1,26)],25:[(2,36)],26:[(2,35)],29:[(1,19)]}.get(i,[]):blocks[b]['mediaId']=mid(n)
 for key in {22:['heritage'],25:['war'],27:['geo'],15:['workshop']}.get(i,[]):a['sourceUrls'].append(S[key][1])
 n=int(activity[1:])-1;typ=activity[0]
 if typ=='O':
  t,p,mm=open_prompts[n];a['activity']=dict(id=aid(activity.lower()),type='open',title=t,prompt=p,fields=['我看见','我猜想','我还想知道'],mediaIds=[mid(m) for m in mm],suggestedArticleIds=[id])
 else:
  q,opts,ev=(C if typ=='C' else L if typ=='L' else P)[n][:3]
  options=[dict(id=k,text=v) for k,v in opts] if typ=='L' else [dict(id=f'option-{j+1}',text=t) for j,t in enumerate(opts)]
  answer=options[0]['id'];options=options[n%len(options):]+options[:n%len(options)]
  e=dict(id=aid(activity.lower()),countryId='deu',articleId=id,type={'L':'location','C':'choice','P':'observation'}[typ],question=q,hint='回到「'+blocks[ev[0]-1]['title']+'」寻找依据。',explanation=blocks[ev[0]-1]['text'],options=options,answerId=answer,evidenceBlockIds=[f'{id}-b{x}' for x in ev])
  if typ=='L':e['mapScope']='world' if n==0 else 'country'
  if typ=='P':e['mediaId']=mid(P[n][3])
  if 'diagram' in a:e['diagram']=a['diagram']
  if typ=='P' and n==3:e['mediaIds']=[mid(17),mid(16)]
  if typ=='P' and n==4:
   e['mediaIds']=[mid(20)]
   for o in e['options']:
    x,y=[(.63,.55),(.5,.08),(.18,.43)][int(o['id'][-1])-1];o.update(x=x,y=y)
  exercises.append(e);a['exerciseId']=e['id']
 articles.append(a)
place_specs=[
('berlin','柏林 · 施普雷河岸',52.521,13.401,'德国东北部',[2,3],'geo','Berlin|Spree|柏林|施普雷河','在首都河岸观察桥与城市。'),
('koblenz','科布伦茨 · 两河汇合处',50.364,7.607,'德国西部 · 莱茵河与摩泽尔河',[4,5],'rhine','Koblenz|Deutsches Eck|科布伦茨|摩泽尔河','摩泽尔河在这里汇入莱茵河。'),
('cologne','科隆 · 莱茵河岸',50.941,6.965,'德国西部',[6,7],'rhine','Köln|Cologne|科隆','沿莱茵河找到桥与城市地标。'),
('hamburg','汉堡港 · 公共观察区域',53.544,9.967,'德国北部 · 易北河',[8,9],'port','Hamburg|Elbe|汉堡港|易北河','从水路与码头理解运输连接。'),
('leipzig','莱比锡 · 电车街道',51.338,12.381,'德国东部',[10,11],'geo','Leipzig|Augustusplatz|莱比锡|电车','观察轨道、车辆与街道空间。'),
('mainz','美因茨 · 印刷故事',49.999,8.275,'德国西部',[12,13],'workshop','Mainz|Gutenberg|美因茨|古腾堡','从博物馆展陈认识印刷技术。'),
('dessau','德绍 · 包豪斯校舍',51.843,12.227,'德国东部',[14,15],'bauhaus','Dessau|Bauhaus|德绍|包豪斯','建筑中的形式、材料与用途。'),
('castle','新天鹅堡',47.5576,10.7498,'德国南部',[16,17],'castle','Neuschwanstein|新天鹅堡','外形不能代替建造年代证据。'),
('jasmund','亚斯蒙德 · 山毛榉林',54.55,13.64,'德国东北部 · 吕根岛',[18,19],'forest','Jasmund|Rügen|亚斯蒙德|吕根岛','倒木仍在森林的生命循环之中。'),
('wadden','瓦登海 · 德国北海沿岸',54.18,8.82,'德国北部 · 潮滩观察代表点',[20,21],'wadden','Wadden|Wattenmeer|瓦登海|潮滩','在潮沟与滩面寻找生命线索。'),
('alps','贝希特斯加登 · 国王湖山地',47.565,12.975,'德国南端 · 阿尔卑斯',[22,23],'geo','Königssee|Konigssee|Berchtesgaden|国王湖|阿尔卑斯','湖泊与山谷帮助认识高山环境。'),
('bautzen','包岑 · 劳西茨语言线索',51.182,14.423,'德国东部 · 上劳西茨',[24,25],'sorbian','Bautzen|Budyšin|包岑|劳西茨','从地名认识索布语言与文化区域。'),
]
places=[]
for slug,name,lat,lon,region,mm,key,aliases,summary in place_specs:
 places.append(dict(id=aid(slug),countryId='deu',name=name,category='自然' if slug in ['jasmund','wadden','alps'] else '城市',latitude=lat,longitude=lon,region=region,summary=summary,description=summary+' 地图标记为公开地点的代表位置；照片可能来自不同视角，代表点不等于摄影点。',observation={'koblenz':'先找两条水道，再对照说明核对名称。','wadden':'找弯曲潮沟；单张照片不能判断涨退潮。','jasmund':'比较树干、倒木和地面纹理。'}.get(slug,'描述一条照片中直接可见的线索，再写一个问题。'),mediaIds=[mid(m) for m in mm],sourceUrl=S[key][1],aliases=aliases.split('|'),articleIds=[a['id'] for a in articles if a.get('placeId')==aid(slug)],coordinateSource='WGS84 公共地点代表坐标；非精确摄影点或导航目的地',hotspots=[]))
# Hotspots reviewed against uncropped original images.
next(p for p in places if p['id']=='deu-koblenz')['hotspots']=[dict(mediaId=mid(4),x=.43,y=.40,label='莱茵河',explanation='较宽的水道沿画面斜向延伸。'),dict(mediaId=mid(4),x=.78,y=.68,label='摩泽尔河',explanation='这条水道在陆地尖端附近汇入莱茵河。')]
next(p for p in places if p['id']=='deu-wadden')['hotspots']=[dict(mediaId=mid(20),x=.63,y=.55,label='潮沟',explanation='弯曲的水道穿过滩面；单张照片不能判断潮向。')]
timeline=[dict(id=aid('timeline-'+slug),period=period,title=title,body=body,mediaId=mid(m),articleIds=[aid(slug)]) for slug,period,title,body,m in [('gutenberg','约1450年代','活字与印刷','欧洲的重要改进，与更早的东亚印刷实践。',26),('persecution','1933—1945年','记住迫害与战争','认识纳粹政权的责任，尊重受害者与历史证据。',36),('unity','1989—1990年','从开放边界到统一','两个年份，两件相互联系的事件。',34)]]
journeys=[dict(id=k,title=t,subtitle=sub,coverTitle=t,mediaId=mid(m),articleIds=[aid(x) for x in ids],stopTitles=stops) for k,t,sub,m,ids,stops in [('river-city','河流与城市','从跨境河流走向码头与街道。',1,['rhine','hamburg','street'],['河流跨境','水陆连接','街道空间']),('forest-coast','森林与海岸','从倒木到潮滩，再看南方高山。阅读顺序，不是交通路线。',18,['deadwood','wadden','alps'],['森林里的倒木','潮滩的线索','南方的阿尔卑斯']),('objects-time','物件里的时间','从字块与书页走向历史资料。',26,['printing','gutenberg','unity'],['活字重排','技术传播','历史的时间'])]]
sections={s:[a['id'] for a in articles if a['sectionId']==s] for s,*_ in rows}
facts=[dict(label='首都',value='柏林'),dict(label='位置',value='欧洲中部'),dict(label='语言',value='德语')]
intro='从莱茵河走向森林与海岸，在城市、物件和历史资料里发现德国。'
country=dict(id='deu',name='德国',code='DE',englishName='Germany',coverage='editorial',revision=1,capital='柏林',mediaId=mid(1),intro=intro,tagline='沿着河流发现世界',facts=facts,timeline=timeline,takeaways=['河流、山脉与自然区域可以跨越国界。','德国有不同地方、语言与生活，单个例子不能代表所有人。','分开看见、猜想与资料证据，让问题带着你继续探索。'],sources=[dict(title=t,url=u,checkedAt='2026-11-11') for t,u in S.values()],sections=sections)
titles=['国家名片','地理与气候','人们与语言','日常生活','饮食与物产','艺术与文化','城市与地标','动物与生态','历史故事','有趣问题']
country['editorial']=dict(subtitle=country['tagline'],introduction=intro,startLabel='从莱茵河开始',startJourneyId='river-city',questionArticleIds=[aid('rhine'),aid('printing')],factOverrides=facts,directoryTitle='德国 · 探索目录',directory=dict(mediaIds=[mid(1),mid(18),mid(2)]),timelineTitle='德国 · 历史线索',timeline=timeline,explore=dict(mediaId=mid(4),featuredTaskIds=[aid('l02'),aid('p05'),aid('o05')],categories=[dict(id=k,title=t,mediaId=mid(m)) for k,t,m in [('location','找地图',2),('observation','看照片',20),('choice','找证据',26),('open','写观察',18)]]),discoveries=dict(mediaId=mid(1),recommendedPlaceIds=[aid('wadden'),aid('jasmund')],recommendationTitles=['再看潮滩','倒木里的生命']),journeys=journeys,sections={s:dict(title=titles[i],summary=articles[i*3]['summary'],mediaId=mid(media[i*3])) for i,s in enumerate(sections)},featuredPlaceIds=[aid('koblenz'),aid('wadden'),aid('jasmund')])
country['editorial']['sections']['daily'].update(primaryMapPlaceId=aid('leipzig'),primaryLabel='看看莱比锡在地图哪里')
(OUT/'deu.json').write_text(json.dumps(dict(country=country,articles=articles,places=places,exercises=exercises),ensure_ascii=False,indent=2)+'\n')
assert (len(articles),len(exercises),len(places))==(30,24,12)
print('Germany: 30 articles, 24 exercises, 6 observations, 12 places, 3 journeys')
