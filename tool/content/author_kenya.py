"""Kenya authored edition; stable IDs retain notes and bookmarks."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'tool/content/editorial'
def aid(s):return 'kenya-'+s
def mid(n):return f'kenya-m{n:02}'
S={
'geo':('UNESCO · 肯尼亚山','https://whc.unesco.org/en/list/800/'),
'law':('Kenya Law · 2010宪法','https://kenyalaw.org/kl/fileadmin/pdfdownloads/Constitution/Constitution_of_Kenya2010.pdf'),
'language':('KLRC · 宪法第7条','https://klrc.go.ke/index.php/constitution-of-kenya/108-chapter-two-the-republic/173-7-national-official-and-other-languages'),
'city':('肯尼亚旅游局 · 内罗毕','https://magicalkenya.com/download/14326/?tmstv=1748249615'),
'rift':('USGS · 东非裂谷','https://www.usgs.gov/publications/seismicity-earth-1900-2013-east-african-rift'),
'water':('USGS · 流域与水循环','https://www.usgs.gov/water-science-school/science/watersheds-and-drainage-basins'),
'food':('肯尼亚农业部 · 玉米利用手册','https://statistics.kilimo.go.ke/files/bookpage/KENYA_Maize-Extension-Manual.pdf'),
'tea':('华盛顿州立大学 · 茶叶加工','https://vegetables.wsu.edu/tea-types-and-home-processing/'),
'culture':('UNESCO · Isukha和Idakho社区Isukuti传统','https://ich.unesco.org/en/USL/isukuti-dance-of-isukha-and-idakho-communities-of-western-kenya-00981'),
'lamu':('UNESCO · 拉穆古镇','https://whc.unesco.org/en/list/1055/'),
'port':('肯尼亚港务局 · 蒙巴萨港','https://www.kwatos.kpa.co.ke/main/main.jsp'),
'museum':('肯尼亚国家博物馆','https://museums.or.ke/museum-story/'),
'elephant':('KWS · 安博塞利','https://kws.go.ke/park/amboseli-national-park/'),
'mangrove':('KWS · 瓦塔穆','https://kws.go.ke/park/watamu-marine-national-park-reserve/'),
'forest':('KWS · 卡卡梅加森林','https://kws.go.ke/park/kakamega-forest-national-reserve/'),
'history':('肯尼亚国家博物馆 · 独立历史','https://museums.or.ke/kapenguria-museum/'),
'independence':('肯尼亚政府 · 独立与共和国日期','https://tourkenya.go.ke/event/jamuhuri-day-republic-day/'),
'map':('Natural Earth · 地理实体','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/'),
}
rows=[]
for line in (ROOT/'docs/countries/kenya/CONTENT_PLAN.md').read_text().splitlines():
 c=line.split('|')[1:-1]
 if len(c)==4 and c[0] in ['overview','geography','people','daily','food','culture','landmarks','nature','history','questions']:rows.append(c)
texts={}
for chunk in (ROOT/'tool/content/sources/kenya_articles.txt').read_text().split('@@ ')[1:]:
 ls=chunk.strip().splitlines();texts[aid(ls[0])]=[x.split('|',1) for x in ls[1:]]
media=[1,3,3,1,13,15,29,29,4,3,4,28,26,27,26,30,32,6,6,7,23,9,22,19,5,34,35,9,1,19]
keys=['map','law','city','geo','rift','water','language','city','language','city','city','food','food','tea','food','culture','lamu','culture','lamu','port','museum','elephant','mangrove','forest','lamu','independence','law','elephant','map','forest']
placekeys=['mount-kenya','nairobi-city','nairobi-city','mount-kenya','naivasha','turkana','nairobi-city','nairobi-city','nairobi-city','nairobi-city','nairobi-city','nairobi-city',None,None,None,None,'lamu','lamu','lamu','mombasa-port','national-museum','amboseli','watamu','kakamega','lamu','national-museum','nairobi-city','amboseli','mount-kenya','kakamega']
diagrams={3:'altitude',4:'rift',5:'water',10:'transfer',12:'maize',15:'rhythm',21:'habitat',22:'mangrove'}
terms=[('赤道','纬度为零的假想参考线。'),('郡','肯尼亚国家内部的行政单位。'),('首都','国家主要中央机构所在地。'),('海拔','地点相对于平均海平面的高度。'),('裂谷','与地壳伸展和断裂等过程相关的地貌。'),('流域','水汇向共同出口的地表区域。'),('官方语言','法律规定在公共事务中具有官方地位的语言。'),('译名','同一名称在另一种语言中的表达。'),('语境','信息出现的场合与背景。'),('公共空间','人们共同使用的空间。'),('换乘','在共同站点转到另一条线路或交通方式。'),('产地','标签声明的生产或收获地点。'),('加工','使原料形态或性质发生改变的处理。'),('氧化','这里指茶叶成分接触氧气后发生的变化。'),('样本','观察材料中的一个或一部分例子。'),('节拍','音乐中有规律的时间单位。'),('纹样','装饰中的图形与排列。'),('讲述者','讲述故事或经验的人。'),('文化交流','人们在联系中分享和改变知识、技术与观念。'),('港口','水路与陆路等运输衔接的设施和区域。'),('馆藏','博物馆等机构收藏并记录的材料。'),('栖息地','生物生活并获取所需条件的环境。'),('潮间带','高潮与低潮水位之间受潮汐影响的地带。'),('林冠','森林上部树冠形成的层次。'),('强迫迁移','人在不自由的条件下被迫离开原居地。'),('独立','这里指肯尼亚结束殖民统治、成为独立国家。'),('宪法','规定国家基本制度与重要权利等内容的基本法律。'),('观察','认真记录材料中可直接看见的信息。'),('纬线','表示相同纬度位置的假想线。'),('对照条件','比较材料时需核对的地点、时间和视角等。')]
C=[
('肯尼亚的郡是什么？',['国家内部的行政单位','四十七个独立国家','地图上的四十七条河'],[1,2]),
('比较赤道附近的环境，还应看什么？',['海拔等条件','只看纬度就足够','只看照片颜色'],[1,2]),
('怎样理解雨水的去向？',['结合地形、流域和不同水循环过程','所有水一定直接流进海','所有湖泊都有同一种出口'],[1,2,3]),
('怎样描述肯尼亚的语言更准确？',['官方语言不等于每个人只会使用这些语言','所有家庭都只说英语','可以根据外貌判断母语'],[1,2,3]),
('从虚构蓝线甲站到橙线丙站在哪里换乘？',['两线共有的乙站','只在蓝线上的甲站','没有共同站点也随处换乘'],[2,3]),
('玉米变成ugali需要区分哪些阶段？',['玉米粒、研磨成粉和烹调成品','生玉米粒就是ugali','包装地点就是种植地点'],[1,2]),
('为什么要注明故事的讲述者和来源？',['帮助理解背景并尊重来源','证明每个人经历完全相同','让故事显得更古老'],[1,2,3]),
('海港怎样联系不同地方？',['人员、物品和文化可以在长期往来中联系','每扇相似木门都来自同一国家','海港只有景观没有生活'],[3,4]),
('大象的家为什么需要连通空间？',['帮助连接水、食物和活动环境','只是为了让照片更宽','所有大象必须每天走固定路线'],[1,2]),
('红树林环境与什么联系密切？',['潮汐、根系与栖息空间','所有树根外形完全一样','高低潮图就是现场安全步行时间'],[1,2,3,4]),
('海岸历史是否只有自由的货物交换？',['还有文化联系，也有强迫迁移和不平等','所有人都是自由旅行','只有船只没有人'],[2,3]),
('宪法属于哪类材料？',['规定国家基本制度和重要权利的法律','个人日记','所有日常事项的操作手册'],[1,4,5])]
L=[
('在世界地图找到肯尼亚。',[('kenya','肯尼亚'),('egypt','埃及'),('china','中国')],[1,2]),
('找到肯尼亚首都内罗毕。',[(aid('nairobi-city'),'内罗毕'),(aid('mombasa-port'),'蒙巴萨'),(aid('kisumu'),'基苏木')],[1,4]),
('找到向北延伸到埃塞俄比亚的图尔卡纳湖。',[(aid('lake-turkana'),'图尔卡纳湖'),(aid('lake-victoria'),'维多利亚湖')],[2,4]),
('找到印度洋海岸的蒙巴萨港。',[(aid('mombasa-port'),'蒙巴萨'),(aid('nairobi-city'),'内罗毕'),(aid('kisumu'),'基苏木')],[1,2]),
('找到肯尼亚西部的卡卡梅加森林。',[(aid('kakamega'),'卡卡梅加森林'),(aid('amboseli'),'安博塞利'),(aid('watamu'),'瓦塔穆')],[1,5]),
('哪条线是纬度为零的赤道？',[(aid('equator'),'赤道'),(aid('border'),'陆地国界'),(aid('coast'),'海岸')],[1,3,4])]
P=[
('Nairobi和内罗毕表示什么？',['同一座城市的不同语言名称','两个不同国家','两个不同人物'],[1],29),
('哪一项回答“来自哪里”？',['③产地：肯尼亚','①名称：玉米粉','②单位：千克'],[1,2],28),
('哪组符合阶段卡中的红茶加工顺序？',['萎凋→揉捻或切碎→氧化→干燥','干燥→采下鲜叶→萎凋','只凭杯中色彩判断流程'],[2,3],37),
('哪组回应保持四拍等间隔？',['1—2—3—4，间隔相同','1—2——3—4，间隔不同','只拍两下'],[3],31),
('资料卡中哪个字段帮助追溯记录？',['资料来源','装饰颜色','卡片圆角'],[1,2],33),
('哪份材料更适合核对独立日期？',['注明来源与日期的事实摘记','没有日期的风景照片','想象中的历史插图'],[1,3,4],34)]
# Tea processing uses an original companion card; the fresh-leaf photograph remains M27.
P[2]=(*P[2][:3],36)
opens=[('语言标牌','记录可见文字和仍需查证的信息。',[29,4]),('城市的一角','看街道、建筑与公共空间，记录一条可见关系。',[3,4]),('一顿饭的范围','区分这一份食物与对所有家庭的推测。',[26,25]),('木门上的纹样','分开看见的形状与需要资料解释的含义。',[6,32]),('看见与猜想','一张照片能说明什么？还有什么没有展示？',[9,3]),('比较的条件','核对两张照片是否同地点、同视角、同日期。',[19,20])]
articles=[];exercises=[]
for i,(section,id,title,activity) in enumerate(rows):
 blocks=[dict(id=f'{id}-v2-b{j+1}',title=t,text=p) for j,(t,p) in enumerate(texts[id])]
 a=dict(id=id,countryId='kenya',sectionId=section,title=title,summary=blocks[0]['text'].split('。')[0]+'。',mediaId=mid(media[i]),blocks=blocks,term=terms[i][0],definition=terms[i][1],glossary=[dict(term=terms[i][0],definition=terms[i][1])],sourceUrls=[S[keys[i]][1]],readingMinutes=4,revision=2,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-12',reviewStatus='sourceChecked')
 if placekeys[i]:a['placeId']=aid(placekeys[i])
 if i in diagrams:a['diagram']=aid(diagrams[i])
 for b,n in {3:[(2,2)],9:[(1,4)],12:[(1,25)],13:[(2,36)],15:[(2,31)],16:[(1,32)],18:[(1,6)],20:[(1,33)],21:[(1,10)],22:[(1,21)],23:[(1,20)],25:[(2,34)],26:[(3,35)],29:[(1,19),(3,20)]}.get(i,[]):blocks[b]['mediaId']=mid(n)
 for key in {3:['map'],4:['map'],6:['law'],24:['history'],25:['history'],29:['map']}.get(i,[]):a['sourceUrls'].append(S[key][1])
 n=int(activity[1:])-1;typ=activity[0]
 if typ=='O':
  t,p,mm=opens[n];a['activity']=dict(id=aid(activity.lower()),type='open',title=t,prompt=p,fields=['我看见','我猜想','我还想知道'],mediaIds=[mid(m) for m in mm],suggestedArticleIds=[id])
 else:
  q,opts,ev=(C if typ=='C' else L if typ=='L' else P)[n][:3]
  options=[dict(id=k,text=v) for k,v in opts] if typ=='L' else [dict(id=f'option-{j+1}',text=t) for j,t in enumerate(opts)]
  answer=options[0]['id'];options=options[n%len(options):]+options[:n%len(options)]
  e=dict(id=aid(activity.lower()),countryId='kenya',articleId=id,type={'L':'location','C':'choice','P':'observation'}[typ],question=q,hint='回到「'+blocks[ev[0]-1]['title']+'」寻找依据。',explanation=blocks[ev[0]-1]['text'],options=options,answerId=answer,evidenceBlockIds=[f'{id}-v2-b{x}' for x in ev])
  if typ=='L':e['mapScope']='world' if n==0 else 'country'
  if typ=='P':e['mediaId']=mid(P[n][3])
  if 'diagram' in a:e['diagram']=a['diagram']
  exercises.append(e);a['exerciseId']=e['id']
 articles.append(a)
place_specs=[
('mount-kenya','肯尼亚山',-.152,37.308,'肯尼亚中部 · 高山',[1,2],'geo','Mount Kenya|Batian|肯尼亚山','赤道附近也有高山；岩峰与植被展示不同环境。'),
('nairobi-city','内罗毕',-1.286,36.817,'肯尼亚南部 · 内陆城市',[3,4],'city','Nairobi|内罗毕','从街道、建筑和公共交通认识首都生活。'),
('lamu','拉穆古镇',-2.269,40.903,'肯尼亚海岸 · 拉穆岛',[5,6],'lamu','Lamu|拉穆|拉姆','海岸街巷与木门留下长期生活的线索。'),
('mombasa-port','蒙巴萨港',-4.054,39.651,'肯尼亚东南部 · 印度洋海岸',[7,8],'port','Mombasa|蒙巴萨|蒙巴薩','从码头理解海路与陆路运输的衔接。'),
('amboseli','安博塞利国家公园',-2.652,37.260,'肯尼亚南部 · 湿地与草原',[9,10],'elephant','Amboseli|安博塞利','水、食物与连通空间共同支持动物生活。'),
('nakuru','纳库鲁湖',-.365,36.082,'肯尼亚中西部 · 湖泊',[11,12],'water','Nakuru|纳库鲁','湖岸与鸟类照片记录特定时刻，不表示实时数量。'),
('naivasha','奈瓦沙湖',-.772,36.350,'肯尼亚中部 · 湖泊',[13,14],'water','Naivasha|奈瓦沙','湖岸、植被和水面为理解环境提供线索。'),
('turkana','图尔卡纳湖',3.50,36.10,'肯尼亚北部 · 跨境湖泊',[15,16],'water','Turkana|Rudolf|图尔卡纳','湖面向北延伸至埃塞俄比亚，不全属于一个国家。'),
('kisumu','基苏木 · 维多利亚湖岸',-.102,34.753,'肯尼亚西部 · 湖岸城市',[17,18],'city','Kisumu|Victoria|基苏木','从城市走向跨境湖泊，比较点与水面范围。'),
('kakamega','卡卡梅加森林',.281,34.856,'肯尼亚西部 · 森林',[19,20],'forest','Kakamega|卡卡梅加','观察林冠与林下，森林地点不等于全部保护区边界。'),
('watamu','瓦塔穆与米达溪',-3.323,39.985,'肯尼亚海岸 · 海洋与红树林',[21,22],'mangrove','Watamu|Mida|瓦塔穆|米达溪','海岸与红树林为理解潮间带提供不同材料。'),
('national-museum','内罗毕国家博物馆',-1.274,36.815,'肯尼亚首都 · 博物馆',[23,24],'museum','National Museum|博物馆','说明卡帮助追问名称、年代与资料来源。')]
places=[]
for slug,name,lat,lon,region,mm,key,aliases,summary in place_specs:
 places.append(dict(id=aid(slug),countryId='kenya',name=name,category='城市' if slug in ['nairobi-city','lamu','mombasa-port','kisumu','national-museum'] else '自然',latitude=lat,longitude=lon,region=region,summary=summary,description=summary+' 地图标记为地点代表位置，不是摄影坐标或导航入口。不同照片的拍摄地点、视角与日期请查看说明。',observation='描述一条直接可见的线索，再提出需要查证的问题。',mediaIds=[mid(m) for m in mm],sourceUrl=S[key][1],aliases=aliases.split('|'),articleIds=[a['id'] for a in articles if a.get('placeId')==aid(slug)],coordinateSource='WGS84 地点代表位置；非边界、摄影点或导航入口',hotspots=[]))
for place in places:
 if place['id']=='kenya-mount-kenya':place['hotspots']=[dict(mediaId=mid(1),x=.43,y=.30,label='岩峰',explanation='高处可见陡峭岩壁；这张照片不能说明山上的全年天气。'),dict(mediaId=mid(1),x=.63,y=.70,label='浅色斑块',explanation='岩面之间可见浅色积雪；面积会随季节与年份变化。')]
 if place['id']=='kenya-lamu':place['hotspots']=[dict(mediaId=mid(6),x=.35,y=.08,label='重复纹样',explanation='门楣上可见连续排列的装饰图形；年代和含义需要资料核对。')]
timeline=[dict(id=aid('timeline-'+slug),period=period,title=title,body=body,mediaId=mid(m),articleIds=[aid(slug)]) for slug,period,title,body,m in [('coast-trade','长期的海岸联系','海岸交流','认识文化联系，也理解强迫迁移与不平等。',5),('independence','1963年','殖民统治与独立','土地、劳动与权利的不平等，以及争取自主的历史。',34),('constitution','2010年','宪法与公共生活','分清基本规则、资料摘记与现实中的落实。',35)]]
journeys=[dict(id=k,title=t,subtitle='三站 · 阅读顺序，不是交通路线。',coverTitle=t,mediaId=mid(m),articleIds=[aid(x) for x in ids],stopTitles=stops) for k,t,m,ids,stops in [('mountain-water','高山与水',1,['geography','rift','water'],['赤道附近的高山','裂谷与湖泊','水流的去向']),('city-coast','城市与海岸',5,['daily','mombasa','history'],['内罗毕的城市生活','蒙巴萨的港口','拉穆的木门']),('living-space','生命的空间',9,['nature','forest','mangrove'],['大象的栖息地','卡卡梅加森林','海岸红树林'])]]
sections={s:[a['id'] for a in articles if a['sectionId']==s] for s,*_ in rows};facts=[dict(label='首都',value='内罗毕'),dict(label='位置',value='非洲东部'),dict(label='官方语言',value='斯瓦希里语、英语')]
country=dict(id='kenya',name='肯尼亚',code='KE',englishName='Kenya',coverage='editorial',revision=2,capital='内罗毕',mediaId=mid(1),intro='从赤道附近的高山走向城市、森林与海岸，用地图、照片和证据认识肯尼亚。',tagline='从赤道高山走向印度洋',facts=facts,timeline=timeline,takeaways=['纬度之外，海拔等条件也会影响环境。','具体社区与个人的生活不能代表所有人。','把看见、猜想和资料证据分开。'],sources=[dict(title=t,url=u,checkedAt='2026-11-12') for t,u in S.values()],sections=sections)
titles=['国家名片','地理与气候','人们与语言','日常生活','饮食与物产','艺术与文化','城市与地标','动物与生态','历史线索','有趣问题']
country['editorial']=dict(subtitle=country['tagline'],introduction=country['intro'],startLabel='从肯尼亚山开始',startJourneyId='mountain-water',questionArticleIds=[aid('geography'),aid('questions')],factOverrides=facts,directoryTitle='肯尼亚 · 探索目录',directory=dict(mediaIds=[mid(1),mid(3),mid(5)]),timelineTitle='肯尼亚 · 历史线索',timeline=timeline,explore=dict(mediaId=mid(3)),discoveries=dict(mediaId=mid(5),recommendedPlaceIds=[aid('lamu'),aid('kakamega')]),journeys=journeys,sections={s:dict(title=titles[i],summary=articles[i*3]['summary'],mediaId=mid(media[i*3])) for i,s in enumerate(sections)},featuredPlaceIds=[aid('mount-kenya'),aid('lamu'),aid('amboseli')])
country['editorial']['sections']['daily'].update(primaryMapPlaceId=aid('nairobi-city'),primaryLabel='看看内罗毕在哪里')
archived=[dict(id=aid(s+'-check'),countryId='kenya',articleId=aid(s),replacementExerciseId=aid(new),reason='完整专题更新，保留历史作答记录。') for s,new in [('geography','c02'),('nature','c09'),('history','c08')]]
(OUT/'kenya.json').write_text(json.dumps(dict(country=country,articles=articles,places=places,exercises=exercises,archivedExercises=archived),ensure_ascii=False,indent=2)+'\n')
assert len(articles)==30 and len(exercises)==24 and len(places)==12
for a in articles:assert 450<=len(re.findall('[\u4e00-\u9fff]',''.join(b['text'] for b in a['blocks'])))<=650,a['id']
print('Kenya: 30 articles, 24 exercises, 6 open activities, 12 places, 3 journeys')
