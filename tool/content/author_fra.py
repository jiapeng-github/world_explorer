"""Compile France's reviewed prose, activity evidence and editorial navigation."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'tool/content/editorial'
def aid(s):return 'fra-'+s
def mid(n):return f'fra-m{n:02}'
S={
'geo':('INSEE · 海外地区','https://www.insee.fr/fr/metadonnees/definition/c2316'),
'paris':('UNESCO · 巴黎塞纳河岸','https://whc.unesco.org/en/list/600/'),
'tide':('SHOM · 潮汐科学','https://refmar.shom.fr/faq'),
'climate':('法国气象局 · 海外气候','https://meteofrance.com/changement-climatique/les-climats-en-outre-mer'),
'names':('斯特拉斯堡旅游局 · 德语城市名称','https://www.visitstrasbourg.fr/de/'),
'reunion':('留尼汪博物馆 · 奴隶制与契约劳工','https://www.musee-villele.re/fr/collections-thematiques'),
'metro':('RATP · 地图','https://www.ratp.fr/plan-metro'),
'label':('DGCCRF · 食品标签','https://www.economie.gouv.fr/dgccrf/les-fiches-pratiques/etiquetage-des-denrees-alimentaires-les-regles-connaitre'),
'bread':('法国自然历史博物馆 · 面包科学','https://www.mnhn.fr/fr/comment-et-depuis-quand-fabrique-t-on-du-pain'),
'baguette':('UNESCO · 法棍制作技艺','https://ich.unesco.org/en/RL/artisanal-know-how-and-culture-of-baguette-bread-01883'),
'art':('莫奈博物馆 · 莫奈藏品','https://www.marmottan.fr/collections/claude-monet/'),
'louvre':('卢浮宫 · 藏品资料库','https://collections.louvre.fr/'),
'music':('法国文化部 · 音乐节','https://www.culture.gouv.fr/evenements-nationaux/fete-de-la-musique'),
'eiffel':('埃菲尔铁塔 · 世界博览会','https://www.toureiffel.paris/en/the-monument/universal-exhibition'),
'loire':('昂布瓦斯王家城堡','https://www.chateau-amboise.com/'),
'corsica':('科西嘉地区自然公园','https://www.pnr.corsica/'),
'glacier':('GLACIOCLIM · 冰川观测','https://www.osug.fr/missions/observation/ocean-atmosphere-surfaces-continentales/glacioclim/'),
'flamingo':('卡马格公园 · 鸟类','https://www.parc-camargue.fr/oiseaux-camargue.html'),
'feeding':('BIOPARC · 火烈鸟食性','https://www.bioparcfuengirola.es/fr/animal/flamant-rose/'),
'volcano':('IPGP · 富尔奈斯观测站','https://www.ipgp.fr/observation/ovpf/'),
'rights':('国民议会 · 1789宣言','https://www.assemblee-nationale.fr/dyn/histoire-et-patrimoine/revolution-francaise/la-declaration-des-droits-de-l-homme-et-du-citoyen'),
'colonial':('国家移民历史博物馆 · 殖民展示','https://www.histoire-immigration.fr/sites/default/files/musee-numerique/documents/ensdoc_figures_du_colonise.pdf'),
'vote':('法国国家档案馆 · 1944法规','https://www.archives-nationales.culture.gouv.fr/evenements/ordonnance-instituant-le-droit-de-vote-des-femmes-1944'),
'vote2':('国民议会 · 女性投票权','https://www.assemblee-nationale.fr/dyn/histoire-et-patrimoine/deuxieme-guerre-mondiale/l-accession-des-femmes-au-droit-de-vote'),
}
rows=[]
for line in (ROOT/'docs/countries/fra/CONTENT_PLAN.md').read_text().splitlines():
 c=[s.strip() for s in line.split('|')]
 if len(c)>6 and c[2].startswith('fra-') and c[1] in ['overview','geography','people','daily','food','culture','landmarks','nature','history','questions']:rows.append(c[1:7])
texts={}
for c in (ROOT/'tool/content/sources/fra_articles.txt').read_text().split('@@ ')[1:]:
 l=c.strip().splitlines();texts[aid(l[0])]=[p.split('|',1) for p in l[1:]]
media=[1,16,2,2,7,10,29,16,25,3,23,3,31,32,23,33,21,34,4,27,19,10,14,16,35,6,36,16,7,17]
sourcekeys=['geo','geo','paris','paris','tide','climate','names','reunion','paris','metro','label','paris','bread','label','label','art','louvre','music','eiffel','loire','corsica','glacier','flamingo','volcano','rights','eiffel','vote','geo','tide','volcano']
placekeys=['seine-paris','fournaise','seine-paris','seine-paris','mont-saint-michel','mer-de-glace','strasbourg','fournaise','marseille-port','seine-paris','lyon-market','seine-paris',None,'lyon-market','lyon-market','louvre','louvre',None,'eiffel','loire-amboise','corte','mer-de-glace','camargue','fournaise',None,'eiffel',None,'fournaise','mont-saint-michel','fournaise']
diagrams={3:'river-city',4:'tides',6:'names',9:'transfer',10:'market',12:'fermentation',13:'cheese',17:'rhythm',18:'triangles',21:'glacier',23:'volcano',26:'votes'}
terms=[('海岸线','地图中表示陆地与海洋相接位置的线。'),('海外地区','相对于欧洲部分而言，位于欧洲以外的地区。'),('首都','国家主要中央机构所在的城市。'),('下游','沿水流方向较后面的河段。'),('潮汐','海面随引力和地球运动等因素出现的周期性升降。'),('气候','较长时期内天气的平均特征与变化规律。'),('地名','人们给地点使用的名称。'),('克里奥尔语','在特定历史和社会环境中形成、拥有自身规则的语言。'),('公共空间','供人们共同使用的地方。'),('换乘','从一条交通线路转到另一条。'),('产地','标签所声明的生产或收获地点，具体含义要看说明。'),('河岸','河流两侧与陆地相接的地带。'),('发酵','微生物参与、使材料发生变化的过程。'),('配料','制作某种食品使用的原料。'),('季节','一年中具有一定自然特点的时段。'),('笔触','画笔留下的痕迹与表现方式。'),('藏品','博物馆等机构收藏并保存研究的物品。'),('节拍','音乐中有规律的时间单位。'),('杆件','构架中一根根连接的结构部件。'),('聚落','人们居住与活动形成的地方。'),('岛屿','四面被水围绕的陆地。'),('冰川','由长期积雪形成、在重力作用下缓慢移动的大量冰。'),('栖息地','生物生活、觅食与繁殖的环境。'),('熔岩','到达地表的熔融岩石。'),('宣言','公开表达原则、主张或立场的文件。'),('档案','保存下来、可用于查考过去活动的记录。'),('选举','按一定规则通过投票选择代表或公职人员的过程。'),('比例尺','地图距离与现实距离之间的比例关系。'),('猜想','仍需证据检验的解释。'),('对照','把材料放在一起比较相同与不同之处。')]
C=[
('只看欧洲部分的地图，能看到法国全部地区吗？',['不能，还有欧洲以外的地区','能，所有地区都在巴黎附近','能，海洋以外没有地区'],[2,3,4,5]),
('图中的桥主要连接什么？',['河流两岸','两片天空','两个河口'],[3]),
('比较两地气候，应选择什么材料？',['同一时期的多年记录','今天的一张照片','一次天气预报'],[2,5]),
('虚构线路在哪里换乘？',['两条线共同的乙站','只有蓝线的甲站','只有橙线的丙站'],[2,3]),
('发酵中什么帮助面团膨起？',['产生的气体','藏进去的小石头','面粉变成金属'],[2,3]),
('判断奶酪原料应该看什么？',['配料说明与产品资料','表面的颜色','包装的形状'],[2,4]),
('想了解展品材料与年代，应先看哪里？',['说明牌与藏品资料','游客排队长度','展厅窗户大小'],[1,2]),
('结构示意中哪种形状反复出现？',['三角形','圆形','五角星'],[2,3]),
('研究冰川变化应看什么？',['同地点多次测量','一张没有日期的照片','今天游客穿什么'],[4,5]),
('火烈鸟在浅水中常进行哪种活动？',['寻找食物','种植树木','建造桥梁'],[2,3]),
('一份宣言能证明当时人人已实际享有平等权利吗？',['不能，还要查规定与现实','能，文件出现就全部实现','能，不必了解任何背景'],[3,4,5]),
('1944法规与1945选举说明什么？',['法律确立与实际参与有先后','两件事发生在同一天','法规只是天气记录'],[1,2,3]),
]
L=[
('在世界地图找到法国欧洲部分。',[('fra','法国'),('egypt','埃及'),('usa','美国')],[1,2,3]),
('在地图上找到巴黎。',[(aid('seine-paris'),'巴黎'),(aid('lyon-market'),'里昂'),(aid('marseille-port'),'马赛')],[1,2]),
('留尼汪位于哪个海洋区域？',[('fra-ocean-indian','印度洋'),('fra-ocean-atlantic','大西洋'),('fra-ocean-pacific','太平洋')],[1]),
('在地图上找到昂布瓦斯。',[(aid('loire-amboise'),'昂布瓦斯'),(aid('corte'),'科尔特'),(aid('mont-saint-michel'),'圣米歇尔山')],[1,5]),
('哪一块真实岛面是科西嘉？',[('fra-part-corsica','科西嘉'),('fra-part-metropole','欧洲大陆部分')],[1,5]),
('选择正确地区，再找到留尼汪岛面。',[('fra-part-reunion','留尼汪'),('fra-part-martinique','马提尼克'),('fra-part-guiana','法属圭亚那')],[2,3,4]),
]
P=[
('哪种对照更可靠？',['同一地点、可比视角的不同潮位','两个地点的不同天气','不同海岸的不同光线'],[1,2,5],7),
('名称卡中的语言标签说明什么？',['同一地点的不同语言名称','两个不同国家的名字','两个人的身份'],[2,3],30),
('练习标签中哪个字段说明产地？',['③产地：法国','①名称：苹果','②单位：千克'],[2,3],24),
('哪组回应与四拍示范相同？',['1—2—3—4，每拍等间隔','1—2，只有两拍','1—2——3—4，间隔不同'],[2,3,4],34),
('凝固熔岩照片能直接帮助观察什么？',['岩面的形状和纹理','精确的岩石年龄','现在是否正在喷发'],[2,3],17),
('哪件材料直接显示施工阶段？',['有日期和来源的施工照片','今天完整的铁塔照片','原创结构示意图'],[2,5],6),
]
opens={
'O01':('街区观察','找一种公共设施；照片不能告诉你哪些居民经历？',[25,26]),
'O02':('河岸步道','水、路与桥在哪里？和自己的街区有什么不同？',[2,3]),
'O03':('市场与季节','哪些食物看得清？还需要哪些产地和日期信息？',[23,24]),
'O04':('光与颜色','描述颜色与笔触，再写下自己的解释。',[33]),
'O05':('看见与猜想','一条可见线索，一个待验证的猜想。',[7,9]),
'O06':('两处海岸','除了颜色，比较形状、纹理和水的位置。',[8,17]),
}
articles=[];exercises=[]
for i,(section,id,title,outline,activity,_) in enumerate(rows):
 blocks=[dict(id=f'{id}-b{j+1}',title=t,text=p) for j,(t,p) in enumerate(texts[id])]
 a=dict(id=id,countryId='fra',sectionId=section,title=title,summary=blocks[0]['text'],mediaId=mid(media[i]),blocks=blocks,term=terms[i][0],definition=terms[i][1],glossary=[dict(term=terms[i][0],definition=terms[i][1])],sourceUrls=[S[sourcekeys[i]][1]],readingMinutes=4,revision=1,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-10',reviewStatus='sourceChecked')
 if placekeys[i]:a['placeId']=aid(placekeys[i])
 if i in diagrams:a['diagram']=aid(diagrams[i])
 for b,n in {3:[(2,3)],4:[(1,8)],6:[(1,30)],10:[(1,24)],12:[(2,31)],16:[(2,22)],18:[(1,5)],21:[(2,11),(4,12)],23:[(2,17),(3,18)],25:[(4,4)],29:[(1,8)]}.get(i,[]):blocks[b]['mediaId']=mid(n)
 for key in {7:['geo'],12:['baguette'],22:['feeding'],24:['reunion'],25:['colonial'],26:['vote2']}.get(i,[]):a['sourceUrls'].append(S[key][1])
 if activity.startswith('O'):
  t,p,mm=opens[activity];a['activity']=dict(id=aid(activity.lower()),type='open',title=t,prompt=p,fields=['我看见','我猜想','我还想知道'],mediaIds=[mid(n) for n in mm],suggestedArticleIds=[id])
 else:
  typ=activity[0];n=int(activity[1:])-1;q,opts,ev=(L if typ=='L' else C if typ=='C' else P)[n][:3]
  options=[dict(id=k,text=v) for k,v in opts] if typ=='L' else [dict(id=f'option-{j+1}',text=t) for j,t in enumerate(opts)]
  answer=options[0]['id'];options=options[n%len(options):]+options[:n%len(options)]
  e=dict(id=aid(activity.lower()),countryId='fra',articleId=id,type={'L':'location','C':'choice','P':'observation'}[typ],question=q,hint='再读「'+blocks[ev[0]-1]['title']+'」，寻找对应的证据。',explanation=blocks[ev[0]-1]['text'],options=options,answerId=answer,evidenceBlockIds=[f'{id}-b{x}' for x in ev])
  if typ=='L':e['mapScope']='world' if n==0 else 'country'
  if typ=='P':e['mediaId']=mid(P[n][3])
  if 'diagram' in a:e['diagram']=a['diagram']
  if typ=='P' and n==5:e['mediaIds']=[mid(6),mid(4)];e['diagram']='fra-triangles'
  exercises.append(e);a['exerciseId']=e['id']
 articles.append(a)
place_specs=[
('seine-paris','塞纳河 · 巴黎',48.8584,2.293,'欧洲部分 · 巴黎',[1,2,3],'paris','Seine|Paris|巴黎|塞纳河','沿河岸观察桥、步道与城市。','这里以巴黎塞纳河岸为代表锚点。照片来自不同河段，摄影点不等于地图代表点。','先找水面，再找连接两岸的桥。'),
('eiffel','埃菲尔铁塔',48.85826,2.2945,'欧洲部分 · 巴黎',[4,5,6],'eiffel','Eiffel Tower|Tour Eiffel|铁塔','从杆件和施工档案认识地标。','铁塔为1889年博览会建造。全貌、杆件近景与1888年施工档案，分别回答不同问题。','在近景里找三角构件。'),
('mont-saint-michel','圣米歇尔山与海湾',48.636,-1.5115,'欧洲部分 · 诺曼底海湾',[7,8,9],'tide','Mont Saint Michel|圣米歇尔','岩岛与潮滩，随水位呈现不同关系。','照片展示岩岛、建筑与潮滩；不同视角的照片不作为潮位定量对照。低潮与高潮关系见原创图解。','找岩岛，再看水与潮滩在哪里。'),
('mer-de-glace','阿尔卑斯 · 冰海冰川',45.932,6.926,'欧洲部分 · 霞慕尼',[10,11,12],'glacier','Mer de Glace|Chamonix|阿尔卑斯|冰海','冰、石屑与谷地共同留下线索。','历史影像与当代照片视角不同，不能用它们直接计算退缩或流速。变化应依据同地点多次测量。','分辨冰与裸露岩石。'),
('camargue','卡马格湿地',43.504,4.445,'欧洲部分 · 罗讷河口',[13,14,15],'flamingo','Camargue|火烈鸟','在浅水与鸟类姿态中认识湿地。','这是湿地公开景观的代表点，不标记巢穴。火烈鸟觅食解释结合鸟类资料，不单凭姿态猜测。','看看长腿、颈部和喙的位置。'),
('fournaise','留尼汪 · 富尔奈斯火山',-21.244,55.708,'留尼汪 · 印度洋',[16,17,18],'volcano','Piton de la Fournaise|Réunion|Reunion|留尼汪|富尔奈斯','火山地形与凝固熔岩的纹理。','照片有各自日期；历史活动影像不代表当前状态。岩石年代、活动判断须查观测资料。','描述一种岩面纹理。'),
('corte','科西嘉 · 科尔特山地',42.306,9.15,'欧洲部分 · 科西嘉内陆',[19,20],'corsica','Corte|Corsica|Corse|科西嘉|科尔特','岛屿内部也有山地和谷地。','锚点位于科尔特，周边山地照片来自不同视角。岛屿不仅有海岸，也有内陆环境。','沿山坡向谷地描一条线。'),
('louvre','卢浮宫',48.8606,2.3376,'欧洲部分 · 巴黎',[21,22],'louvre','Louvre|卢浮宫','从建筑走向藏品资料。','外部庭院与内部建筑照片只是参观线索。学习藏品时，要另外核对名称、年代、材料及收藏来源。','区分建筑与展品资料。'),
('lyon-market','里昂 · 市场观察点',45.762,4.831,'欧洲部分 · 圣安托万河岸',[23,24],'label','Lyon|Saint Antoine|里昂|市场','观察摊位，再练习读标签。','市场实拍与原创标签分开标注。练习标签不表示照片中某件商品的真实产地或现价。','名称、单位与产地分别在哪里？'),
('marseille-port','马赛 · 老港公共区域',43.2955,5.374,'欧洲部分 · 地中海岸',[25,26],'paris','Marseille|Vieux Port|马赛|老港','水面、船与城市公共空间。','港口照片是一处具体区域和一个时刻，无法概括所有居民的一天。','找一种直接看见的公共设施。'),
('loire-amboise','卢瓦尔河 · 昂布瓦斯',47.414,0.985,'欧洲部分 · 卢瓦尔河畔',[27,28],'loire','Loire|Amboise|昂布瓦斯|卢瓦尔','河流、城堡与聚落的位置关系。','代表点位于昂布瓦斯河岸附近。建筑年代需查具体资料，不能由照片颜色推断。','从河面向城堡描出视线。'),
('strasbourg','斯特拉斯堡',48.581,7.744,'欧洲部分 · 阿尔萨斯',[29,30],'names','Strasbourg|Straßburg|斯特拉斯堡','用地名认识语言与位置。','名称卡是原创语言练习，法语 Strasbourg 与德语 Straßburg 指同一城市；德语不等于阿尔萨斯语。','先读语言标签，再核对地点。'),
]
places=[]
for slug,name,lat,lon,region,mm,sk,aliases,summary,desc,obs in place_specs:
 places.append(dict(id=aid(slug),countryId='fra',name=name,category='自然' if slug in ['mont-saint-michel','mer-de-glace','camargue','fournaise','corte'] else '城市',latitude=lat,longitude=lon,region=region,summary=summary,description=desc,observation=obs,mediaIds=[mid(n) for n in mm],sourceUrl=S[sk][1],aliases=aliases.split('|'),articleIds=[a['id'] for a in articles if a.get('placeId')==aid(slug)],coordinateSource='WGS84 公共地点代表锚点；Natural Earth 与公开地点资料交叉定位；不等同摄影点',hotspots=[]))
# Hotspots reviewed in uncropped source coordinates. PhotoPoints uses contain.
hotspots=[('seine-paris',1,.23,.38,'铁塔','远处的铁塔位于河岸建筑之间。'),('eiffel',5,.55,.48,'交叉杆件','斜向杆件组成开放构架。'),('mont-saint-michel',7,.45,.64,'岩石高地','建筑下方可见岩石与植被。'),('mer-de-glace',11,.60,.54,'冰川谷地','冰与石屑沿谷地延伸。'),('camargue',14,.50,.72,'浅水','鸟的腿部伸入浅水区域。'),('fournaise',17,.70,.43,'岩面褶皱','凝固熔岩表面可见弯曲纹理。'),('corte',19,.50,.40,'山坡','山体向两侧和谷地方向延伸。'),('louvre',21,.52,.70,'庭院建筑','庭院、金字塔与宫殿构成不同形状。'),('lyon-market',23,.35,.50,'市场摊位','遮棚下有商品与通行空间。'),('marseille-port',26,.50,.60,'港口水面','水面与岸边公共空间相接。'),('loire-amboise',27,.40,.40,'河流','河道延伸向远方，桥连接两岸。'),('strasbourg',29,.50,.75,'水道','水道穿过建筑之间。')]
for slug,n,x,y,label,explanation in hotspots:
 next(p for p in places if p['id']==aid(slug))['hotspots']=[dict(mediaId=mid(n),x=x,y=y,label=label,explanation=explanation)]
next(p for p in places if p['id']=='fra-mont-saint-michel')['hotspots'].append(dict(mediaId=mid(7),x=.50,y=.91,label='水道',explanation='前方水道与滩地相接；单张照片不能判断涨退潮方向。'))
e=next(e for e in exercises if e['id']=='fra-p05');e['question']='哪个编号指向凝固熔岩表面的褶皱纹理？';e['mediaIds']=[mid(17)]
for o in e['options']:
 n=int(o['id'][-1])-1;x,y,text=[(.70,.43,'岩面上的褶皱纹理'),(.75,.05,'上方天空'),(.18,.22,'左侧树木')][n];o.update(x=x,y=y,text=text)
sections={s:[a['id'] for a in articles if a['sectionId']==s] for s,*_ in rows}
timeline=[dict(id=aid('timeline-'+slug),period=period,title=title,body=body,mediaId=mid(n),articleIds=[aid(slug)]) for slug,period,title,body,n in [('rights-document','1789年','文字与现实之间','读宣言，也看谁仍被排除在权利之外。',35),('exhibition-1889','1889年','铁塔与博览会','施工影像、技术劳动与殖民时代背景。',6),('voting-change','1944—1945年','从规定到参与','区分法律确立与实际投票的时间。',36)]]
journeys=[dict(id=k,title=t,subtitle=sub,coverTitle=t,mediaId=mid(n),articleIds=[aid(a) for a in aa],stopTitles=stops) for k,t,sub,n,aa,stops in [('river-city','河岸里的城市','沿着河流认识桥、步道与地标。',2,['seine-city','river-walk','eiffel-structure'],['河流穿城','河岸步道','铁塔结构']),('changing-land','山海的变化','潮汐、冰川与火山，留下不同的变化线索。',7,['bay-tides','moving-glacier','reunion-volcano'],['潮水往返','冰川缓行','熔岩成岩']),('objects-time','物件里的时间','用档案和建筑，追问过去发生了什么。',35,['rights-document','exhibition-1889','voting-change'],['宣言与权利','铁塔的建造','参与投票'])]]
facts=[dict(label='首都',value='巴黎'),dict(label='范围',value='欧洲与海外'),dict(label='语言',value='法语')]
intro='法国在欧洲和海外都有地区。沿着河流认识城市，再去发现山海与生活。'
country=dict(id='fra',name='法国',code='FR',englishName='France',coverage='editorial',revision=1,capital='巴黎',mediaId=mid(1),intro=intro,tagline='从塞纳河走向山海',facts=facts,timeline=timeline,takeaways=['法国既有欧洲部分，也有海外地区。','照片、地图与长期观测，能回答不同的问题。','把看见的线索与需要验证的猜想分开记录。'],sources=[dict(title=t,url=u,checkedAt='2026-11-10') for t,u in S.values()],sections=sections)
sectiontitles=['国家名片','地理与气候','人们与语言','日常生活','饮食与物产','艺术与节日','城市与地标','动物与生态','历史故事','有趣问题']
country['editorial']=dict(subtitle=country['tagline'],introduction=intro,startLabel='从塞纳河开始',startJourneyId='river-city',questionArticleIds=[aid('bay-tides'),aid('europe-overseas')],factOverrides=facts,directoryTitle='法国 · 探索目录',directory=dict(mediaIds=[mid(1),mid(7),mid(10)]),timelineTitle='法国 · 历史线索',timeline=timeline,explore=dict(mediaId=mid(19),featuredTaskIds=['fra-l05','fra-p05','fra-o05'],categories=[dict(id=k,title=t,mediaId=mid(n)) for k,t,n in [('location','找地图',19),('observation','看照片',17),('choice','找证据',6),('open','写观察',7)]]),discoveries=dict(mediaId=mid(2),recommendedPlaceIds=[aid('mont-saint-michel'),aid('mer-de-glace')],recommendationTitles=['再看潮汐','冰川会移动吗']),journeys=journeys,sections={s:dict(title=sectiontitles[i],summary=articles[i*3]['summary'],mediaId=mid(media[i*3])) for i,s in enumerate(sections)},featuredPlaceIds=[aid('mont-saint-michel'),aid('mer-de-glace'),aid('fournaise')])
country['editorial']['sections']['geography']['mediaId']=mid(10)
country['editorial']['sections']['nature']['mediaId']=mid(14)
country['editorial']['sections']['questions']['mediaId']=mid(7)
country['editorial']['sections']['daily'].update(primaryMapPlaceId=aid('seine-paris'),primaryLabel='看看巴黎在地图哪里')
(OUT/'fra.json').write_text(json.dumps(dict(country=country,articles=articles,places=places,exercises=exercises),ensure_ascii=False,indent=2)+'\n')
assert len(articles)==30 and len(exercises)==24 and len(places)==12
print('France: 30 articles,24 exercises,6 observations,12 places,3 journeys')
