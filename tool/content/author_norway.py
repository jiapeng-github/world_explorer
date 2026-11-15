"""Build Norway's authored edition with stable entity IDs and new block revision."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'tool/content/editorial'
def aid(s):return 'norway-'+s
def mid(n):return f'norway-m{n:02}'
S={
'map':('Natural Earth · Map Units','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/'),
'fjord':('UNESCO · 西挪威峡湾','https://whc.unesco.org/en/list/1195/'),
'bryggen':('UNESCO · 布吕根','https://whc.unesco.org/en/list/59/'),
'urnes':('UNESCO · 乌尔内斯木教堂','https://whc.unesco.org/en/list/58/'),
'alta':('UNESCO · 阿尔塔岩画','https://whc.unesco.org/en/list/352/'),
'polar':('挪威极地研究所 · 地图','https://npolar.no/en/maps/'),
'bear':('挪威极地研究所 · 北极熊','https://npolar.no/en/species/polar-bear/'),
'light':('Yr · 极夜与午夜太阳','https://hjelp.yr.no/hc/en-us/articles/360008027114-Polar-nights-and-midnight-sun'),
'aurora':('挪威航天局 · 空间天气','https://www.romsenter.no/laer-om-romvirksomhet/det-farlige-romvaeret'),
'climate':('挪威政府 · 地理与气候','https://www.regjeringen.no/en/documents/norways-eighth-national-communication/id2971116/?ch=2'),
'language':('挪威政府 · 书面语言规范','https://www.regjeringen.no/no/om-nettstedet/innholdsstrategi/ti-bud-for-godt-innhold-pa-regjeringen.no/skriveregler-for-regjeringen.no/skriftsprak/id2551245/'),
'sami':('挪威政府 · 萨米人','https://www.regjeringen.no/en/topics/indigenous-peoples-and-minorities/Sami-people/id1403/'),
'reconciliation':('挪威议会 · 真相与和解委员会','https://www.stortinget.no/en/In-English/About-the-Storting/News-archive/Front-page-news/2022-2023/the-truth-and-reconciliation-commission/'),
'history':('挪威议会 · 民主史里程碑','https://www.stortinget.no/en/in-english/about-the-storting/historical-highlights/milestones-in-norways-democratic-history/'),
'war':('挪威议会 · 二战期间','https://www.stortinget.no/en/In-English/About-the-Storting/historical-highlights/the-storting-during-world-war-ii/'),
'union':('挪威王室 · 宪法与联合','https://www.kongehuset.no/historie/grunnlov-og-union-1814-1905'),
'transport':('Ruter · 交通线路图','https://ruter.no/en/plan-journey/timetables-and-route-maps'),
'food':('Nordland · 便当材料','https://www.nfk.no/_f/p1/i1bd327e2-4d6b-4d3e-a6ef-b5e44464f9d5/matglede-i-boks.pdf'),
'cod':('挪威海产局 · 风干鱼','https://www.fromnorway.com/seafood-from-norway/stockfish/'),
'stories':('Nationalmuseum · 故事的艺术版本','https://collection.nationalmuseum.se/en/collection/item/36656/'),
'glacier':('NVE · 尼加尔冰川','https://www.nve.no/hydrology/glaciers/glacier-monitoring/nigardsbreen/'),
'ice':('挪威冰川博物馆 · 冰舌','https://en.bremuseum.no/deeper-learning/breutlparar-fra-jostedalsbreen'),
}
rows=json.loads((ROOT/'docs/countries/norway/content-outline.json').read_text())['articles'];texts={}
for chunk in (ROOT/'tool/content/sources/norway_articles.txt').read_text().split('@@ ')[1:]:
 ls=chunk.strip().splitlines();texts[aid(ls[0])]=[x.split('|',1) for x in ls[1:]]
media=[1,5,21,1,35,7,28,28,17,5,6,37,25,26,27,29,10,30,1,4,9,14,34,33,31,31,32,2,13,23]
keys=['map','transport','polar','fjord','ice','climate','language','language','sami','transport','transport','transport','food','cod','food','history','urnes','stories','fjord','bryggen','urnes','light','aurora','bear','history','union','war','fjord','polar','glacier']
placekeys=['geiranger','oslo','longyearbyen','geiranger','jostedalsbreen','naeroyfjord','oslo','oslo','karasjok','oslo','oslo','oslo',None,'lofoten-reine',None,'oslo','urnes',None,'geiranger','bryggen','urnes','tromso','tromso','longyearbyen','eidsvoll','eidsvoll','eidsvoll','geiranger','tromso','jostedalsbreen']
diagrams={3:'fjord',5:'climate',10:'transfer',12:'lunch',13:'cod',21:'daylight',22:'aurora',23:'sea-ice'}
terms=[('纬度','表示地点相对赤道南北位置的角度。'),('首都','国家主要公共机构所在地。'),('比例尺','地图距离与实际距离之间的关系。'),('峡湾','冰川参与塑造谷地后形成的狭长海湾。'),('侵蚀','岩石或土壤被磨蚀、移走等过程。'),('气候','一个地区长期天气的统计特点。'),('书面规范','对书写形式的约定，不等于固定口音。'),('方言','与地区或群体生活有关的语言变体。'),('原住民族','具有历史延续、文化联系与自身认同的群体。'),('公共空间','供人们共同使用的空间。'),('换乘','在连接站点转到另一条线路或交通方式。'),('缓坡','以渐变高度连接不同平面的路径。'),('matpakke','挪威语中指随身携带的便当。'),('干制','通过减少水分等处理形成产品的过程。'),('产地','标签声明的生产或原料来源地点。'),('宪法日','挪威5月17日纪念宪法历史的节日。'),('构件','建筑中承担特定作用的组成部分。'),('版本','经过特定整理、翻译或出版形成的文本。'),('代表点','帮助定位一个对象的大致位置，不是完整边界。'),('修复','对损坏材料或结构进行维护和修整。'),('遗产','从过去传承并值得认识与保护的材料和实践。'),('极昼','高纬地区太阳整天不落下的季节现象。'),('极光','带电粒子与高层大气作用产生的发光现象。'),('海冰','海水冻结形成的冰，不同于陆地冰川。'),('事实摘记','注明出处的事实整理，不是档案原件。'),('联合','这里指挪威与瑞典曾有的国家关系。'),('占领','战争中外来力量强制控制一地的状态。'),('透视','空间关系在平面图像中的呈现方式。'),('北极圈','与地轴倾角有关的北半球高纬参考线。'),('冰舌','冰川向低处或外围延伸的部分。')]
C=[('三幅分图为什么不能直接用屏幕长度比较大小？',['比例尺和缩放范围不同','它们都没有真实位置','所有岛屿都与本土一样大'],[4,5]),('峡湾的水面与哪里相连？',['海洋','沙漠','封闭的空气'],[1,3,4]),('比较同纬度附近的气候，还应考虑什么？',['海洋、海拔与山地等条件','只看纬度就够了','只看一张雪景照片'],[2,3,4]),('怎样理解挪威的语言生活？',['存在多种语言，书面规范不等于固定口音','所有人只用同一种语言','外貌决定一个人的母语'],[1,2,3]),('从虚构蓝线甲站到橙线丙站，在哪里换乘？',['两线共有的乙站','只在蓝线上的甲站','任何没有站点的地方'],[4,5]),('matpakke应怎样理解？',['可以有不同食物组合的便当习惯','每个人完全相同的一份菜单','只能由一种配料组成'],[1,2,4]),('干制、盐渍和冷藏的关系是什么？',['它们是不同的处理方式','所有干鱼一定加过盐','三种词表示完全相同的过程'],[3,4]),('挪威宪法日主要纪念哪个年份的宪法历史？',['1814年','1905年','1945年'],[1,2]),('故事与历史记录有什么区别？',['材料类型不同，适合回答的问题不同','故事人物都是真实生物','所有故事情节都是历史事实'],[2,3,4]),('怎样更可靠地核对建筑年代？',['查阅遗产研究与历史记录','只看木头颜色深浅','只看屋顶是否很高'],[3,4]),('午夜太阳主要与什么关系有关？',['纬度、季节和地轴倾斜','太阳突然停止运动','整个挪威全年都没有夜晚'],[1,2,3,4]),('哪组关系有助于解释极光？',['带电粒子、磁场与高层大气','雪地把绿色灯光反射到天空','太阳整天不落下'],[1,2,3])]
L=[('在世界地图找到挪威。',[('norway','挪威'),('kenya','肯尼亚'),('china','中国')],[1,2,5]),('找到首都奥斯陆。',[(aid('oslo'),'奥斯陆'),(aid('bryggen'),'卑尔根 · 布吕根'),(aid('tromso'),'特罗姆瑟')],[2,5]),('找到盖朗厄尔峡湾的代表位置。',[(aid('geiranger'),'盖朗厄尔峡湾'),(aid('oslo'),'奥斯陆'),(aid('lofoten-reine'),'罗弗敦 · 雷讷')],[1,4]),('找到约斯特达尔冰川的代表位置。',[(aid('jostedalsbreen'),'约斯特达尔冰川'),(aid('geiranger'),'盖朗厄尔峡湾'),(aid('bryggen'),'布吕根')],[1,2,5]),('在哪幅分图里能找到斯瓦尔巴岛屿范围？',[(aid('part-svalbard'),'斯瓦尔巴'),(aid('part-mainland'),'挪威本土'),(aid('part-jan-mayen'),'扬马延')],[1,5]),('哪条线是北极圈？',[(aid('arctic-circle'),'北极圈'),(aid('border'),'陆地国界'),(aid('coast'),'海岸线')],[1,3,4,5])]
P=[('哪组符合原创冰川过程卡的先后关系？',['冰川运动与侵蚀→冰退后地形显露','先有冰退后的地形→冰川才开始侵蚀','三幅都是同一地点三个年份的实拍'],[1,2,4,5],35),('Bokmål和Nynorsk表示什么？',['挪威语的两种书面规范','两种固定口音','两个不同国家'],[1,2,3],28),('原创示意中哪一项是缓坡？',['逐渐升高的连续路径','一格一格的台阶','写着站名的站牌'],[3,4],37),('哪项回答标签上的“来自哪里”？',['③产地：挪威','①名称：面包','②计量：克'],[2,3,4],27),('判断木材年代应怎样使用证据？',['结合火灾与修复记录，不能只凭旧外观','每块木材都一定同样古老','只凭颜色判断确切年份'],[3,4,5],36),('哪项更适合核对宪法年份？',['注明机构、年份和出处的事实摘记','没有日期的风景照片','想象中的古纸插画'],[3,4,5],31)]
opens=[('今天的萨米文化','记录材料来源与仍想了解的问题。',[17,18]),('身边的公共空间','先观察一个设施，再想想它可能帮助谁。',[5,37]),('木雕的线条','分开记录可见形状与需要资料解释的含义。',[9,10]),('两个历史年份','分别记录1814和1905对应的事件及疑问。',[31,19]),('战争与和平','记录一条事实和一个想继续了解的问题。',[32,20]),('峡湾里的三种尺度','分别观察近景、中景和远景，不用像素大小推断真实大小。',[1,2])]
articles=[];exercises=[]
for i,row in enumerate(rows):
 id=row['id'];blocks=[dict(id=f'{id}-v2-b{j+1}',title=t,text=p,sourceUrls=[S[keys[i]][1]]) for j,(t,p) in enumerate(texts[id])]
 a=dict(id=id,countryId='norway',sectionId=row['sectionId'],title=row['title'],summary=blocks[0]['text'].split('。')[0]+'。',mediaId=mid(media[i]),blocks=blocks,term=terms[i][0],definition=terms[i][1],glossary=[dict(term=terms[i][0],definition=terms[i][1])],sourceUrls=[S[keys[i]][1]],readingMinutes=4,revision=2,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-12',reviewStatus='sourceChecked')
 if placekeys[i]:a['placeId']=aid(placekeys[i])
 if i in diagrams:a['diagram']=aid(diagrams[i])
 for key in {4:['glacier','fjord'],6:['sami'],8:['reconciliation','language'],15:['union'],19:['cod'],23:['polar'],24:['union'],25:['history'],29:['ice']}.get(i,[]):
  a['sourceUrls'].append(S[key][1])
  for b in blocks:b['sourceUrls']=a['sourceUrls'][:]
 for b,n in {3:[(2,35)],8:[(2,18)],9:[(3,37)],16:[(1,10)],19:[(3,36)],20:[(2,10)],21:[(2,13)],24:[(3,31)],26:[(0,32)],29:[(3,24)]}.get(i,[]):blocks[b]['mediaId']=mid(n)
 task=row['task'];typ=task[0];n=int(task[1:])-1
 if typ=='O':
  title,prompt,mm=opens[n];a['activity']=dict(id=aid(task.lower()),type='open',title=title,prompt=prompt,fields=['我看见','我猜想','我还想知道'],mediaIds=[mid(x) for x in mm],suggestedArticleIds=[id])
 else:
  q,opts,ev=(C if typ=='C' else L if typ=='L' else P)[n][:3];options=[dict(id=k,text=v) for k,v in opts] if typ=='L' else [dict(id=f'option-{j+1}',text=t) for j,t in enumerate(opts)];answer=options[0]['id'];options=options[n%len(options):]+options[:n%len(options)]
  e=dict(id=aid(task.lower()),countryId='norway',articleId=id,type={'L':'location','C':'choice','P':'observation'}[typ],question=q,hint='回到「'+blocks[ev[0]-1]['title']+'」寻找依据。',explanation=blocks[ev[0]-1]['text'],options=options,answerId=answer,evidenceBlockIds=[f'{id}-v2-b{x}' for x in ev])
  if typ=='L':e['mapScope']='world' if n==0 else 'country'
  if typ=='P':e['mediaId']=mid(P[n][3])
  if 'diagram' in a:e['diagram']=a['diagram']
  exercises.append(e);a['exerciseId']=e['id']
 articles.append(a)
place_specs=[('geiranger','盖朗厄尔峡湾',62.10,7.10,'西部海岸 · 峡湾','fjord','Geiranger|Geirangerfjord','峡湾海水伸入山谷，岸边聚落提供尺度线索。'),('bryggen','布吕根历史港区',60.397,5.325,'卑尔根 · 历史港区','bryggen','Bryggen|Bergen','木建筑、通道与海岸贸易共同留下历史线索。'),('oslo','奥斯陆',59.91,10.75,'挪威南部 · 首都','transport','Oslo','海滨、公共空间与电车连接今天的城市生活。'),('naeroyfjord','纳柔依峡湾',60.96,6.94,'西部海岸 · 峡湾','fjord','Naeroyfjord|Nærøyfjord','狭长海湾连接海洋，两侧山地展示冰川作用的线索。'),('urnes','乌尔内斯木教堂',61.298,7.323,'西部峡湾 · 木建筑','urnes','Urnes','整体结构与雕刻细节帮助认识木建筑遗产。'),('lofoten-reine','罗弗敦 · 雷讷',67.932,13.09,'北部群岛 · 聚落','cod','Reine|Lofoten','群岛聚落与渔业联系，不只是一张空旷的风景。'),('tromso','特罗姆瑟',69.65,18.96,'北极圈以北 · 城市','light','Tromsø|Tromso','认识现代城市，也比较夏季日照与极昼。'),('alta','阿尔塔岩画',69.947,23.187,'北部 · 岩画遗产','alta','Alta','岩画与环境共同组成遗产，具体解释应查阅来源。'),('karasjok','卡拉绍克',69.471,25.511,'北部 · 当代萨米公共生活','sami','Karasjok|Kárášjohka|Sametinget','从萨米议会与社区环境认识当代生活。'),('eidsvoll','埃兹沃尔',60.298,11.171,'南部 · 宪法历史','history','Eidsvoll|Eidsvollsbygningen','历史建筑与资料摘记帮助区分不同年份的事件。'),('longyearbyen','朗伊尔城',78.22,15.65,'斯瓦尔巴 · 城镇','polar','Longyearbyen|Svalbard','北方城镇与科学文化活动，不把野生动物当作街头景观。'),('jostedalsbreen','约斯特达尔冰川',61.67,6.97,'西部 · 冰川地区','glacier','Jostedalsbreen|Nigardsbreen','冰川照片应说明具体冰舌、拍摄日期与比较条件。')]
places=[]
for i,(slug,name,lat,lon,region,key,aliases,summary) in enumerate(place_specs):
 places.append(dict(id=aid(slug),countryId='norway',name=name,category='自然' if i in [0,3,5,11] else '城市',latitude=lat,longitude=lon,region=region,summary=summary,description=summary+' 地图标记是WGS84代表位置，不是完整边界、摄影坐标或导航入口。照片地点与日期请查看素材说明。',observation='写下一条可见线索，再提出一个需要查证的问题。',mediaIds=[mid(i*2+1),mid(i*2+2)],sourceUrl=S[key][1],aliases=aliases.split('|'),articleIds=[a['id'] for a in articles if a.get('placeId')==aid(slug)],coordinateSource='专题代表位置；遗产地参照UNESCO地点资料，城市参照Natural Earth地理位置；精度约公里，不用于导航。',hotspots=[]))
for p in places:
 if p['id']=='norway-geiranger':p['hotspots']=[dict(mediaId=mid(1),x=.49,y=.35,label='远处山坡',explanation='陡坡围着海湾；这里只能观察可见的形状。'),dict(mediaId=mid(2),x=.52,y=.75,label='岸边聚落',explanation='房屋和道路与水面相邻；年代与用途需资料核对。')]
 if p['id']=='norway-bryggen':p['hotspots']=[dict(mediaId=mid(4),x=.7,y=.6,label='木板与立柱',explanation='木材组成通道两侧的结构，颜色不能独自证明年代。')]
timeline=[dict(id=aid('timeline-'+slug),period=period,title=title,body=body,mediaId=mid(m),articleIds=[aid(slug)]) for slug,period,title,body,m in [('history','海岸贸易与木城','木屋里的历史','从港口、火灾与修复认识布吕根。',3),('union','1814—1905','宪法与国家关系','两年两件事：宪法历史与联合解体。',31),('occupation','1940—1945','占领、迫害、抵抗与解放','以非血腥材料认识战争与人们的经历。',32)]]
journeys=[dict(id=k,title=t,subtitle='三站 · 阅读顺序，不是交通路线。',coverTitle=('北方光与生命' if k=='northern-light' else t),mediaId=mid(m),articleIds=[aid(x) for x in ids],stopTitles=stops) for k,t,m,ids,stops in [('fjord-wood','峡湾与木城',1,['geography','history','urnes'],['盖朗厄尔峡湾','布吕根木城','乌尔内斯木教堂']),('city-daily','城市里的日常',5,['daily','food','people'],['奥斯陆公共空间','一份便当','多样语言']),('northern-light','北方的光与生命',34,['nature','aurora','sea-ice'],['午夜太阳','夜空极光','海冰生态'])]]
sections={s:[a['id'] for a in articles if a['sectionId']==s] for s in dict.fromkeys(a['sectionId'] for a in articles)};facts=[dict(label='首都',value='奥斯陆'),dict(label='位置',value='欧洲北部'),dict(label='代表地形',value='山地与峡湾')]
country=dict(id='norway',name='挪威',code='NO',englishName='Norway',coverage='editorial',revision=2,capital='奥斯陆',mediaId=mid(1),intro='从峡湾、木城走向现代生活与北方自然，用地图、照片和证据认识挪威。',tagline='从峡湾海岸走向北极之光',facts=facts,timeline=timeline,takeaways=['峡湾与海洋相连，冰川曾参与塑造山谷。','极昼与极光的成因不同，挪威并非全国全年冰雪。','现代城市、多种语言与不同社区共同组成挪威生活。'],sources=[dict(title=t,url=u,checkedAt='2026-11-12') for t,u in S.values()],sections=sections)
titles=['国家名片','地理与气候','人们与语言','日常生活','饮食与物产','艺术与文化','城市与地标','动物与生态','历史线索','有趣问题']
country['editorial']=dict(subtitle=country['tagline'],introduction=country['intro'],startLabel='从峡湾开始',startJourneyId='fjord-wood',questionArticleIds=[aid('geography'),aid('nature')],factOverrides=facts,directoryTitle='挪威 · 探索目录',directory=dict(mediaIds=[mid(1),mid(5),mid(3)]),timelineTitle='挪威 · 历史线索',timeline=timeline,explore=dict(mediaId=mid(1)),discoveries=dict(mediaId=mid(3),recommendedPlaceIds=[aid('bryggen'),aid('tromso')]),journeys=journeys,sections={s:dict(title=titles[i],summary=articles[i*3]['summary'],mediaId=mid(media[i*3])) for i,s in enumerate(sections)},featuredPlaceIds=[aid('geiranger'),aid('bryggen'),aid('tromso')])
country['editorial']['sections']['daily'].update(primaryMapPlaceId=aid('oslo'),primaryLabel='在地图上找奥斯陆')
archived=[dict(id=aid(s+'-check'),countryId='norway',articleId=aid(s),replacementExerciseId=aid(new),reason='完整专题更新；历史作答保留，不计入新题。') for s,new in [('geography','c02'),('nature','c11'),('people','c04')]]
for a in articles:
 n=len(re.findall('[\u4e00-\u9fff]',''.join(b['text'] for b in a['blocks'])));assert 450<=n<=650,(a['id'],n)
(OUT/'norway.json').write_text(json.dumps(dict(country=country,articles=articles,places=places,exercises=exercises,archivedExercises=archived),ensure_ascii=False,indent=2)+'\n')
print('Norway: 30 articles, 12 places, 24 closed tasks, 6 open observations, 3 journeys.')
