"""Compile South Africa's complete prose and evidence-linked learning activities.
Run before build_catalog.py. No network or changes to other countries.
"""
import json, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]; OUT=ROOT/'tool/content/editorial'
def zid(slug): return 'zaf-'+slug
S={
'geo':('南非政府 · 地理与气候','https://www.gov.za/about-sa/geography-and-climate'),
'capitals':('南非政府 · 国家概况','https://www.gov.za/about-sa/south-africa-glance'),
'languages':('南非政府 · 官方语言','https://www.gov.za/about-sa/south-africa-glance'),
'sign':('南非社会发展部 · 手语与沟通','https://www.dsd.gov.za/index.php/21-latest-news/639-deaf-awareness-month-it-is-time-deaf-stories-are-told-by-deaf-people'),
'agulhas':('SANParks · 非洲大陆最南端','https://www.sanparks.org/parks/agulhas/explore/heritage/southernmost-tip-of-africa'),
'penguins':('SANParks · 博尔德斯企鹅栖地','https://www.sanparks.org/parks/table-mountain/what-to-do/attractions/boulders-penguin-colony'),
'mountains':('UNESCO · 马洛蒂—德拉肯斯山','https://whc.unesco.org/en/list/985/'),
'mapungubwe':('UNESCO · 马蓬古布韦文化景观','https://whc.unesco.org/en/list/1099/'),
'wetland':('UNESCO · 伊西曼加利索与马普托跨境遗产','https://whc.unesco.org/en/list/914/'),
'robben':('UNESCO · 罗本岛','https://whc.unesco.org/en/list/916/'),
'election':('南非议会 · 民主25周年回顾','https://www.parliament.gov.za/index.php/press-releases/statement-presiding-officers-parliament-25-years-our-democracy'),
'lesotho':('UNESCO · 跨越南非与莱索托的遗产','https://whc.unesco.org/en/list/985/'),
'kruger':('SANParks · 克鲁格国家公园','https://www.sanparks.org/parks/kruger'),
'table':('SANParks · 桌山国家公园','https://www.sanparks.org/parks/table-mountain'),
'maize':('南非旅游局 · 玉米粉与饮食','https://www.southafrica.net/na/en/travel/article/traditional-african-food-in-south-africa'),
'fruit':('Fruit SA · 南非水果行业','https://fruitsa.co.za/'),
'food':('南非学校膳食计划 · 食谱与原料','https://www.education.fs.gov.za/files/programmes/Mnandi4%20Sure%20-%20A%20Recipe%20Book%20for%20the%20NSNP.pdf'),
'beads':('牛津大学皮特里弗斯博物馆 · 南非珠饰','https://web.prm.ox.ac.uk/LGweb/beads/1987_25_25.htm'),
'music':('南非政府 · 体育、艺术与文化','https://www.gov.za/about-sa/sports-arts-and-culture'),
'sport':('南非政府 · 体育、艺术与文化','https://www.gov.za/about-sa/sports-arts-and-culture'),
'transport':('Gautrain · 铁路与换乘服务','https://www.gautrain.co.za/'),
'library':('约翰内斯堡市 · 图书馆','https://www.joburg.org.za/'),
'port':('Transnet · 开普敦港','https://www.transnetnationalportsauthority.net/OurPorts/Cape%20Town/Pages/Overview.aspx'),
}
# Questions name specific evidence, not merely a generic praise message.
C=[
('three-capitals','哪句话与国家名片相符？',['不同国家职能由不同城市承担','全部法院都在布隆方丹','三个名称指同一座城市'],3),
('country-region','“南非”和“非洲南部”有什么区别？',['前者是国家，后者是区域','两个词的范围始终完全相同','后者只指开普敦'],2),
('coast-plateau','高原一定像桌面一样完全平吗？',['不，高原也有山丘和谷地','是，不能出现河谷','是，所有地方一样高'],1),
('rainfall','比较两座城市的雨季，哪份材料更合适？',['同一时期的逐月多年记录','今天的一张晴天照片','某位游客一次旅行的衣服'],4),
('sign-language','南非第12种官方语言是？',['南非手语','一种世界通用手势','所有口语的简单逐字比划'],2),
('city-transfer','从虚构甲站去丙站，在哪站换乘？',['乙站','甲站','丙站'],3),
('maize-food','哪组顺序符合玉米粉食物的制作过程？',['玉米粒→研磨成粉→烹调','烹调→长出玉米→研磨','玉米粒→直接变成包装'],2),
('sports-rules','哪种安排更利于大家公平参与？',['开始前说明并确认共同规则','比赛中偷偷改变计分','只让声音最大的人决定'],2),
('grassland-links','图解“草→食草动物”的箭头表示什么？',['食物与能量传递方向','动物一定向右走','地图上唯一的道路'],2),
('mapungubwe-story','研究古物时，哪种做法更可靠？',['结合出土位置和多种证据','只看颜色猜来自哪里','编一个故事就当作历史'],2),
('voting-1994','1994年选举的重要变化是什么？',['不受种族排除地参与民主选择','所有生活困难当日自动消失','所有人只能选择同一个答案'],1),
('lesotho','莱索托与南非是什么关系？',['被南非陆地包围的独立国家','南非的一座城市','南非海岸的一处海湾'],1),
]
L=[
('find-south-africa','在世界地图上找到南非。',[('zaf','南非'),('egypt','埃及'),('china','中国')],1,'world'),
('two-capes','在地图上找到非洲大陆最南端。',[('zaf-agulhas','厄加勒斯角'),('zaf-good-hope','好望角'),('zaf-cape-town','开普敦')],1,'country'),
('table-mountain','哪一个地点是开普敦附近的桌山？',[('zaf-table-mountain','桌山'),('zaf-drakensberg','德拉肯斯山'),('zaf-mapungubwe','马蓬古布韦')],1,'country'),
('two-cities','找到位于内陆高原的约翰内斯堡。',[('zaf-johannesburg','约翰内斯堡'),('zaf-cape-town','开普敦'),('zaf-agulhas','厄加勒斯角')],1,'country'),
('wetland-water','找到南非东部沿海的伊西曼加利索湿地。',[('zaf-isimangaliso','伊西曼加利索'),('zaf-robben-island','罗本岛'),('zaf-mapungubwe','马蓬古布韦')],1,'country'),
('robben-island','找到开普敦外海的罗本岛。',[('zaf-robben-island','罗本岛'),('zaf-boulders','博尔德斯'),('zaf-pretoria','比勒陀利亚')],1,'country'),
]
P=[
('languages','两张语言卡表达什么？',['同一个欢迎意思的不同语言表达','两座不同城市','两个人的国籍'],2),
('market-label','哪一个字段声明产地？',['③产地：南非','①名称：苹果','②单位：千克'],2),
('recipe-diversity','从练习配方能直接读出什么？',['它使用玉米粉与水','全国每个家庭都用它','全国只有这一种食物'],2),
('bead-patterns','蓝、橙、蓝、橙之后，按同一规律是哪种颜色？',['蓝色','绿色','橙色'],2),
('african-penguins','照片里可以直接观察哪种细节？',['黑白羽毛与周围岩石','每只企鹅刚吃了多少鱼','整个地区的企鹅总数'],5),
('tracks-evidence','调查模糊脚印时，应怎样增加证据？',['补充尺度、地点和连续痕迹','只凭模糊照片立即猜名称','从远景照片编一个动物故事'],4),
]
questions={}
for typ,rows in [('C',C),('L',L),('P',P)]:
 for n,row in enumerate(rows,1):questions[row[0]]=(typ,n,*row[1:])
terms=[('国界','地图上表示国家范围的边界。'),('职能','机构所承担的工作和作用。'),('区域','按某种用途划分的一片地理范围。'),('高原','海拔较高、范围较大的地形，表面也有起伏。'),('纬度','表示一个地方在赤道以北或以南的位置。'),('气候','一个地区较长时期的天气规律。'),('官方语言','在国家制度中获得官方地位的语言。'),('手语','利用手形、动作、表情等表达的完整语言。'),('证据','能够支持或检验一个判断的材料。'),('换乘','由一条交通线路转到另一条。'),('产地','标签所声明的产品生产或收获地点。'),('公共空间','供人们共同使用的场所。'),('研磨','把较大的颗粒磨成较小颗粒的过程。'),('配方','说明原料及搭配方法的资料。'),('供应链','从生产到送达使用者的一系列环节。'),('重复单元','一个图案中反复出现的最小一组。'),('节拍','音乐中有规律的时间单位。'),('规则','大家共同遵守的活动约定。'),('轮廓','从某个方向看到的外部边缘。'),('内陆','远离海岸的陆地区域。'),('港口','连接水上与陆上运输的场所。'),('栖息地','动物生活、觅食和繁殖所需的环境。'),('食物网','生物之间多种食物关系组成的网络。'),('湿地','水与陆地环境相互作用的重要生态区域。'),('考古','通过遗存及其关系研究过去的人类活动。'),('平等权利','人应得到尊重，不因种族等身份遭受不平等对待。'),('选举','按规则通过投票作出公共选择的过程。'),('独立国家','拥有自己国家身份的政治实体。'),('线索','帮助进一步调查、还需结合其他材料的信息。'),('猜想','需要用证据检验的一种可能解释。')]
articles=[];exercises=[];open_count=0
for index,chunk in enumerate((ROOT/'tool/content/sources/zaf_articles.txt').read_text().split('@@ ')[1:]):
 lines=chunk.strip().splitlines();slug,section,title,media,sk,place,diagram,typ=lines[0].split('|');aid=zid(slug)
 blocks=[dict(id=f'{aid}-b{j+1}',title=line.split('|',1)[0],text=line.split('|',1)[1]) for j,line in enumerate(lines[1:])]
 assert len(blocks)==5
 article=dict(id=aid,countryId='zaf',sectionId=section,title=title,summary=blocks[0]['text'].split('。')[0]+'。',mediaId=zid(media),blocks=blocks,term=terms[index][0],definition=terms[index][1],glossary=[dict(term=terms[index][0],definition=terms[index][1])],sourceUrls=[S[sk][1]],readingMinutes=math.ceil(sum(len(b['text']) for b in blocks)/180),revision=1,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-11',reviewStatus='sourceChecked')
 if place:article['placeId']=zid(place)
 if diagram:article['diagram']=zid(diagram)
 if slug=='coast-plateau':article['sourceUrls'].append(S['mountains'][1])
 if typ=='O':
  open_count+=1
  article['activity']=dict(id=zid(f'o{open_count:02}'),type='open',title=title,prompt=blocks[-1]['text'],fields=['我看见','我猜想','我还想知道'],mediaIds=[zid(media)],suggestedArticleIds=[aid])
 else:
  qt,n,q,opts,ev,*scope=questions[slug];assert qt==typ
  options=[dict(id=k,text=t) for k,t in opts] if typ=='L' else [dict(id=f'option-{j+1}',text=t) for j,t in enumerate(opts)]
  answer=options[0]['id'];options=options[n%len(options):]+options[:n%len(options)]
  eid=zid(f'{typ.lower()}{n:02}')
  exercise=dict(id=eid,countryId='zaf',articleId=aid,type={'C':'choice','L':'location','P':'observation'}[typ],question=q,options=options,answerId=answer,hint='再读「'+blocks[ev-1]['title']+'」，找一条证据。',explanation=blocks[ev-1]['text'],evidenceBlockIds=[blocks[ev-1]['id']])
  if typ=='L':exercise['mapScope']=scope[0]
  if typ=='P':exercise['mediaId']=zid(media)
  if diagram:exercise['diagram']=zid(diagram)
  if slug=='recipe-diversity':exercise['diagram']='zaf-recipe';article['diagram']='zaf-recipe'
  if slug=='bead-patterns':exercise['diagram']='zaf-patterns';article['diagram']='zaf-patterns'
  article['exerciseId']=eid;exercises.append(exercise)
 articles.append(article)
# Refine covers using separately credited, subject-specific photography.
for a in articles:
 slug=a['id'].removeprefix('zaf-')
 if slug in ['african-penguins','seen-guessed']:
  a['mediaId']='zaf-penguin-close'; a['blocks'][0]['mediaId']='zaf-penguins'
  if a.get('activity'):a['activity']['mediaIds']=['zaf-penguin-close','zaf-penguins']
 if slug in ['maize-food','recipe-diversity']:a['mediaId']='zaf-food'
 if slug in ['city-transfer','shared-spaces']:a['mediaId']='zaf-street'
for e in exercises:
 if e['articleId']=='zaf-african-penguins':e['mediaId']='zaf-penguin-close'
 if e['articleId']=='zaf-recipe-diversity':e['mediaId']='zaf-food'
# Each photo below depicts the named place, never a substituted animal/location.
place_specs=[
('cape-town','开普敦',-33.925,18.424,'西南海岸','hero','port','Cape Town|开普敦','海湾、城市与山体相伴。','把海岸与城市放在同一幅地图上，找一条连接陆地和海洋的线索。'),
('table-mountain','桌山',-33.962,18.410,'开普敦','hero','table','Table Mountain|Tafelberg|桌山','从城市方向观察平顶轮廓。','山顶轮廓随视角变化；山体不是完全平整的桌面。'),
('boulders','博尔德斯企鹅观察区',-34.197,18.451,'开普半岛','penguins','penguins','Boulders|Foxy Beach|企鹅','花岗岩巨石与非洲企鹅。','点位为公开观赏区域的概略位置，不提供具体巢穴。沿规定步道观察，不投喂、不触碰。'),
('good-hope','好望角',-34.357,18.497,'开普半岛','good-hope','table','Cape of Good Hope|好望角','著名海角，位于厄加勒斯角以西。','沿真实海岸比较位置：这里不是非洲大陆最南端。'),
('agulhas','厄加勒斯角',-34.833,20.000,'南部海岸','agulhas','agulhas','Cape Agulhas|阿古拉斯|厄加勒斯','非洲大陆的最南端。','大洋地理分界不等于固定可见的海水双色线。'),
('drakensberg','德拉肯斯山',-28.752,28.895,'东部山地','mountains','mountains','Drakensberg|德拉肯斯|龙山','山地、谷地与水系。','这是南非一侧公开山景的代表点；相关世界遗产跨南非与莱索托。'),
('kruger','克鲁格 · 斯库库扎公共区域',-24.995,31.592,'东北部','kruger','kruger','Kruger|Skukuza|克鲁格','从植物开始认识草原生态。','代表点是公开访客区域，不是野生动物实时位置或巢穴位置。照片来自公园其他公开景观视角。'),
('isimangaliso','伊西曼加利索 · 圣卢西亚',-28.377,32.414,'印度洋沿岸','wetland','wetland','iSimangaliso|St Lucia|圣卢西亚|湿地','河口、湿地与海岸环境相连。','代表点位于公开河口区域；不表示保护区边界，也不标出动物繁殖地点。'),
('johannesburg','约翰内斯堡',-26.204,28.047,'内陆高原','city','capitals','Johannesburg|Joburg|约堡','内陆城市的天际线。','照片拍摄于2006年，只记录当时的一个视角；不是今天全市生活的缩影。'),
('pretoria','比勒陀利亚',-25.740,28.212,'豪登省','pretoria','capitals','Pretoria|Tshwane|比勒陀利亚','南非常用名片中的行政首都。','代表点位于联合大厦一带；不要据此推断全部国家机构都集中于此。'),
('mapungubwe','马蓬古布韦文化景观',-22.212,29.388,'北部边境','mapungubwe','mapungubwe','Mapungubwe|马蓬古布韦|马蓬古布韦','古老聚落与远方联系的线索。','位置、器物与出土关系共同帮助研究历史；不是只看一件珍宝。'),
('robben-island','罗本岛',-33.806,18.368,'开普敦外海','robben','robben','Robben Island|罗本岛|罗布恩岛','保存关于自由与权利的历史。','建筑、历史文件与当事人讲述互相补充；不是苦难角色扮演的场所。'),
]
places=[]
for slug,name,lat,lon,region,media,sk,aliases,summary,desc in place_specs:
 linked=[a['id'] for a in articles if a.get('placeId')==zid(slug)]
 if slug=='good-hope':linked=[zid('two-capes')]
 places.append(dict(id=zid(slug),countryId='zaf',name=name,category='自然' if slug in ['boulders','good-hope','agulhas','drakensberg','kruger','isimangaliso'] else '人文',latitude=lat,longitude=lon,region=region,summary=summary,description=desc,observation='先描述一条看得见的线索，再提出一个仍需查证的问题。',mediaIds=[zid(media)],sourceUrl=S[sk][1],aliases=aliases.split('|'),articleIds=linked,coordinateSource='WGS84 公开地点概略代表点，非范围边界、摄影机位或现场导航坐标。',hotspots=[]))
next(p for p in places if p['id']=='zaf-boulders')['mediaIds']=['zaf-penguin-close','zaf-penguins']
sections={s:[a['id'] for a in articles if a['sectionId']==s] for s in ['overview','geography','people','daily','food','culture','landmarks','nature','history','questions']}
sectiontitles=['国家名片','地理与气候','人们与语言','日常生活','饮食与物产','艺术与节日','城市与地标','动物与生态','历史故事','有趣问题']
sectionmedia=['hero','mountains','city','street','food','mountains','hero','penguins','mapungubwe','agulhas']
sectionintro=['先找大陆南端，再认识国家与区域。','从海岸、陡崖走向高原。','12种官方语言，不同的表达与生活。','乘车、读标签，也关心共同空间。','从原料到餐桌，追踪食物的旅程。','发现图案、节拍与共同参与的规则。','在地图与照片中认识山城和港口。','看见动物，也看见它们的生活环境。','让遗址、档案与时间彼此印证。','带着问号，把看见和猜想分开。']
journeys=[dict(id=slug,title=title,subtitle=sub,coverTitle=title,mediaId=zid(media),articleIds=[zid(a) for a in ids],stopTitles=stops) for slug,title,sub,media,ids,stops in [
('coast-life','海岸与生命','沿着海岸，认识海角、企鹅与湿地。','penguin-close',['two-capes','african-penguins','wetland-water'],['找到最南端','企鹅的家','湿地与水']),
('mountains-grassland','山地与草原','从起伏的地形，走向相互连接的生命。','mountains',['coast-plateau','lesotho','grassland-links'],['海岸到高原','山地跨国界','食物的联系']),
('city-living','城市里的生活','从两座城市，走向交流与日常观察。','street',['two-cities','languages','city-transfer'],['海岸与内陆','不同的表达','共同站点换乘'])]]
timeline=[dict(id=zid('time-'+slug),period=period,title=title,body=body,mediaId=zid(media),articleIds=[zid(slug)]) for slug,period,title,body,media in [
('mapungubwe-story','约公元900—1300年','聚落与远方联系','遗址与器物共同记录南部非洲社会的发展。','mapungubwe'),
('robben-island','20世纪后半叶','为自由与平等努力','罗本岛保存许多人反对种族隔离的历史线索。','robben'),
('voting-1994','1994年4月','共同参与民主选择','首次不分种族的民主全国选举，是重要的变化节点。','robben'),
('sign-language','2023年','让更多表达被看见','南非手语成为第12种官方语言。','city')]]
facts=[dict(label='位置',value='非洲南部'),dict(label='首都',value='三城分工'),dict(label='语言',value='12种官方语言')]
intro='在非洲大陆南端，沿着海岸认识企鹅，再走向高原、城市与多样的生活。'
country=dict(id='zaf',name='南非',code='ZA',englishName='South Africa',coverage='editorial',revision=1,capital='比勒陀利亚、开普敦、布隆方丹',mediaId='zaf-hero',intro=intro,tagline='从海岸走向高原',facts=facts,timeline=timeline,takeaways=['南非有海岸、山地、高原与多样城市生活。','莱索托是独立国家；厄加勒斯角才是非洲大陆最南端。','从真实材料出发，把看见的线索与猜想分开。'],sources=[dict(title=t,url=u,checkedAt='2026-11-11') for t,u in dict(S.values()).items()],sections=sections)
country['editorial']=dict(subtitle=country['tagline'],introduction=intro,startLabel='从海岸开始',startJourneyId='coast-life',questionArticleIds=['zaf-african-penguins','zaf-two-capes'],factOverrides=facts,directoryTitle='南非 · 探索目录',directory=dict(mediaIds=['zaf-hero','zaf-penguins','zaf-mountains']),timelineTitle='南非 · 历史线索',timeline=timeline,explore=dict(mediaId='zaf-mountains',featuredTaskIds=['zaf-l02','zaf-p05','zaf-o06'],categories=[dict(id=k,title=t,mediaId=zid(m)) for k,t,m in [('location','找地图','agulhas'),('observation','看照片','penguins'),('choice','找证据','mapungubwe'),('open','写观察','city')]]),discoveries=dict(mediaId='zaf-hero',recommendedPlaceIds=['zaf-boulders','zaf-drakensberg'],recommendationTitles=['企鹅的海岸','山地跨越国界']),journeys=journeys,sections={s:dict(title=sectiontitles[i],summary=sectionintro[i],mediaId=zid(sectionmedia[i])) for i,s in enumerate(sections)},featuredPlaceIds=['zaf-boulders','zaf-drakensberg','zaf-agulhas'])
country['editorial']['sections']['daily'].update(primaryMapPlaceId='zaf-johannesburg',primaryLabel='看看内陆城市的位置')
assert len(articles)==30 and len(exercises)==24 and open_count==6 and len(places)==12
(OUT/'zaf.json').write_text(json.dumps(dict(country=country,articles=articles,places=places,exercises=exercises),ensure_ascii=False,indent=2)+'\n')
print('South Africa: 30 complete articles, 24 evidence-linked exercises, 6 observations, 12 places, 3 journeys')
print('Body character range:',min(sum(len(b['text']) for b in a['blocks']) for a in articles),max(sum(len(b['text']) for b in a['blocks']) for a in articles))
