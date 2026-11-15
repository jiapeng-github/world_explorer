"""Rebuild UK editorial JSON from reviewed prose and explicit activity metadata."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'tool/content/editorial'
def mid(n):return f'gbr-m{n:02d}'
def aid(s):return 'gbr-'+s
def write(name,obj):(OUT/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
# Primary source ledger; grouped by article, kept separate from image licensing.
S={
'uk':'https://www.ons.gov.uk/methodology/classificationsandstandards/otherclassifications/nationalstatisticscountryclassification/explanatorynotesandcodingguidelines',
'river':'https://www.thames21.org.uk/what-is-the-tidal-thames/',
'rock':'https://www.nationaltrust.org.uk/visit/northern-ireland/giants-causeway/history-of-giants-causeway',
'weather':'https://www.metoffice.gov.uk/research/climate/maps-and-data/regional-climates',
'welsh':'https://www.welshlanguagecommissioner.wales/standard-welsh-place-names/caerdydd',
'glen':'https://www.lochlomond-trossachs.org/discover-the-park/our-heritage-culture/our-gaelic-culture/lochs-glens-straths/',
'tube':'https://tfl.gov.uk/maps/track/tube',
'bridge':'https://www.towerbridge.org.uk/stories/how-does-tower-bridge-work',
'park':'https://www.royalparks.org.uk/visit/parks/st-jamess-park/wildlife',
'oats':'https://www.foodstandards.gov.scot/downloads/FSS_Report_Analysis_Oat_Products_FR002547.pdf',
'bread':'https://museum.wales/collections/welsh-foods/?id=178',
'tea':'https://www.kew.org/plants/tea-plant',
'dance':'https://rscds.org/what-is-a-ceilidh/',
'stage':'https://www.shakespearesglobe.com/discover/about-us/',
'football':'https://www.thefa.com/news/2026/feb/09/four-uk-football-associations-welcome-fifa-womens-world-cup-2035-inspection-visit-20260902',
'bell':'https://www.parliament.uk/about/living-heritage/building/palace/architecture/palacestructure/towers-of-parliament/',
'castle':'https://www.edinburghcastle.scot/the-castle/history/',
'eryri':'https://eryri.gov.wales/discover/culture-language-and-community/place-names/',
'puffin':'https://www.welshwildlife.org/visit/skomer-island',
'coast':'https://www.geolsoc.org.uk/science-and-policy/100-great-geosites/educational/lyme-regis-beaches/',
'valley':'https://www.geolsoc.org.uk/science-and-policy/100-great-geosites/fire-and-ice/glencoe/',
'stone':'https://www.english-heritage.org.uk/visit/places/stonehenge/history-and-stories/',
'rail':'https://collection.sciencemuseumgroup.org.uk/objects/co205767',
'vote':'https://www.parliament.uk/about/living-heritage/transformingsociety/electionsvoting/womenvote/unesco/equal-franchise-act-1928/'
}
rows=[]
for line in (ROOT/'docs/countries/gbr/CONTENT_PLAN.md').read_text().splitlines():
 c=[x.strip() for x in line.split('|')]
 if len(c)>6 and c[2].startswith('gbr-') and c[1] in ['overview','geography','people','daily','food','culture','landmarks','nature','history','questions']:rows.append(c[1:7])
texts={}
for chunk in (ROOT/'tool/content/sources/gbr_articles.txt').read_text().split('@@ ')[1:]:
 lines=chunk.strip().splitlines();texts[aid(lines[0])]=[l.split('|',1) for l in lines[1:] if l]
media_numbers=[1,1,2,2,5,36,11,19,9,2,4,27,28,29,30,31,32,33,3,17,13,16,25,19,21,23,34,14,5,26]
source_keys=['uk','uk','river','river','rock','weather','welsh','glen','uk','tube','bridge','park','oats','bread','tea','dance','stage','football','bell','castle','eryri','puffin','coast','valley','stone','rail','vote','uk','rock','coast']
place_suffixes=['thames-london','thames-london','thames-london','thames-london','giants-causeway','thames-london','cardiff','glencoe','belfast','thames-london','tower-bridge','thames-london',None,None,None,None,'thames-london',None,'thames-london','edinburgh','eryri','skomer','jurassic-coast','glencoe','stonehenge','shildon',None,'belfast','giants-causeway','jurassic-coast']
diagrams={1:'islands-parts',3:'river-city',4:'column-cooling',6:'bilingual',9:'interchange',15:'rhythm',20:'contour',21:'puffin-habitat',27:'islands-parts'}
terms=[('海岸','陆地与海水相接的地带。'),('组成部分','这里指英格兰、苏格兰、威尔士和北爱尔兰。'),('首都','国家主要中央机构所在的城市。'),('河口','河流流入海洋或其它水体的地方。'),('节理','岩石中形成的裂缝。'),('气候','一个地方在较长时期内的天气特征。'),('双语','使用两种语言。'),('地名','人们给地点使用的名称。'),('公共空间','供人们共同使用的地方。'),('换乘','从一条交通线路转到另一条。'),('桥面','供人和车辆通行的桥上部分。'),('树冠','一棵树上部枝叶形成的整体。'),('谷物','可收获籽粒用作食物的一类作物。'),('配方','说明食物材料与制作方法的记录。'),('产地','一种物品种植、生产或加工的地方，要看标签具体指什么。'),('节拍','音乐或动作中有规律的时间单位。'),('剧本','记录角色、台词和舞台动作的文字。'),('代表队','依某项赛事的规则组成的参赛队伍。'),('钟楼','用于安放钟的建筑。'),('岩丘','由岩石构成的隆起地形。'),('等高线','地图上连接海拔相同地点的线。'),('栖息地','生物生活、觅食或繁殖的环境。'),('岩层','一层层形成的岩石。'),('冰川','在重力作用下缓慢移动的大量冰。'),('考古证据','帮助研究过去的人类活动的遗物、遗迹和相关材料。'),('蒸汽动力','利用受热产生的蒸汽推动机械。'),('档案','保存下来、用于查考过去活动的记录。'),('岛屿','四面被水围绕的陆地。'),('猜想','还需要证据检验的解释。'),('对照','把不同材料放在一起比较。')]
open_specs={
'O01':('街区里的一天','你看到了什么公共设施？照片还不能告诉你谁的一天？',[9,8]),
'O02':('桥怎样连接两岸','两座桥的形状和两端有哪些不同？用途需要查什么？',[2,4]),
'O03':('面包里的小点','哪些是图中看见的，哪些只能从配方知道？',[29]),
'O04':('山谷的形状','山谷有什么形状？你还想知道它怎样形成？',[19,20]),
'O05':('看见与猜想','写下一条看见的线索，再写一个需要验证的猜想。',[5,6]),
'O06':('两处不同的海岸','除了颜色，你还能比较哪些线索？',[5,26])}
# question, options (correct first), evidence indices
choices=[
('英格兰属于哪个范围？',['英国的一个组成部分','整个英国','整个爱尔兰岛'],[2,3,4]),
('例图中，桥把什么连接起来？',['河流两岸','两片天空','两个河口'],[3]),
('了解一个地方的气候，应看哪类资料？',['同地点多年的天气记录','今天的一张雨景照片','明天的一次天气预报'],[2,3,4]),
('例图中的换乘点在哪里？',['乙站：两条线共同的站点','甲站','丙站'],[2,3]),
('哪份材料可确认一碗粥的成分？',['包装或配方中的配料说明','粥表面的颜色','碗的形状'],[4,5]),
('想查茶叶产地，先看什么？',['产地标签或供应方来源资料','在哪里喝到这杯茶','茶杯上的图案'],[2]),
('台词通常先写在哪份材料中？',['剧本','天气记录','地铁线路图'],[1,2]),
('想知道某场赛事有哪些代表队，应看什么？',['该赛事官方参赛名单','只看一张国家地图','猜球衣的颜色'],[3,4,5]),
('严格说，Big Ben 的名称指什么？',['塔中的大钟','整座钟楼','整座议会建筑'],[2,3]),
('海鹦在哪儿获得鱼类食物？',['海里','草地上'],[2,3]),
('巨石阵的所有用途都确定了吗？',['还有尚未确定的问题','所有用途都已经确定','没有任何考古线索'],[3,4]),
('判断 1928 年规定的内容，应看什么？',['相关法案及档案解释','一张没有日期的照片','城堡的高度'],[3,4,5])]
locations=[
('在世界地图上找到英国。',[('gbr','英国'),('egypt','埃及'),('usa','美国')],[1,2,3]),
('在英国地图上找到伦敦河岸。',[('gbr-thames-london','伦敦河岸'),('gbr-edinburgh','爱丁堡'),('gbr-belfast','贝尔法斯特')],[1,2,3]),
('格伦科属于哪个组成部分？',[('gbr-part-scotland','苏格兰'),('gbr-part-england','英格兰'),('gbr-part-wales','威尔士'),('gbr-part-northern-ireland','北爱尔兰')],[1,5]),
('在地图上找到爱丁堡。',[('gbr-edinburgh','爱丁堡'),('gbr-cardiff','卡迪夫'),('gbr-belfast','贝尔法斯特')],[5]),
('找到威尔士的 Eryri 山地。',[('gbr-eryri','Eryri 山地'),('gbr-glencoe','格伦科'),('gbr-giants-causeway','巨人堤')],[5]),
('哪一部分位于爱尔兰岛东北部并属于英国？',[('gbr-part-northern-ireland','北爱尔兰'),('gbr-part-wales','威尔士'),('gbr-part-scotland','苏格兰')],[3,4,5])]
photos=[
('哪条可见线索符合石柱开裂？',['柱间的裂缝','想象的巨人脚印','天空里的云'],[2,3],5),
('文字卡中的 Caerdydd 和 Cardiff 指同一个城市吗？',['是，都是卡迪夫','不是，是两个国家','只表示一种语言'],[2,3],11),
('照片中的哪一处可见树冠？',['湖岸上方的枝叶轮廓','画面下方的湖水','中央远处的天空'],[2],27),
('哪一组和四拍示范有同样的拍数与均匀间隔？',['1—2—3—4，每拍间隔相同','1—2，只有两拍','1—2——3—4，间隔不同'],[2,3],31),
('哪一处可以观察岩层条带？',['崖壁上深浅相间的横向纹理','画面上的天空','海面反光'],[2],26),
('机车照片中，哪个部位是车轮？',['车身下方的圆形部件','车身上方的烟囱','背景建筑的窗户'],[1,2],23)]
articles=[];exercises=[]
media_by_id={m['id']:m for m in json.loads((OUT/'gbr_assets.json').read_text())['media']}
for i,(section,id,title,outline,activity,_) in enumerate(rows):
 blocks=[dict(id=f'{id}-b{j+1}',title=t,text=p) for j,(t,p) in enumerate(texts[id])]
 a=dict(id=id,countryId='gbr',sectionId=section,title=title,summary=blocks[0]['text'].split('。')[0]+'。',mediaId=mid(media_numbers[i]),blocks=blocks,term=terms[i][0],definition=terms[i][1],glossary=[dict(term=terms[i][0],definition=terms[i][1])],sourceUrls=[S[source_keys[i]],media_by_id[mid(media_numbers[i])]['sourceUrl']],readingMinutes=4,revision=1,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-09',reviewStatus='sourceChecked')
 if place_suffixes[i]:a['placeId']=aid(place_suffixes[i])
 if i in diagrams:a['diagram']=aid(diagrams[i])
 extra={3:(1,4),4:(2,6),6:(1,10),7:(3,20),10:(1,2),18:(1,35),19:(2,18),20:(2,13),21:(1,15),22:(1,26),23:(2,20),24:(1,22),25:(3,24),29:(2,5)}
 if i in extra:b,n=extra[i];blocks[b]['mediaId']=mid(n)
 if activity.startswith('O'):
  t,p,mm=open_specs[activity];a['activity']=dict(id='gbr-'+activity.lower(),type='open',title=t,prompt=p,fields=['我看见','我猜想','我还想知道'],mediaIds=[mid(n) for n in mm],suggestedArticleIds=[id])
 else:
  typ=activity[0];n=int(activity[1:])-1
  q,opts,ev= (locations if typ=='L' else choices if typ=='C' else photos)[n][:3]
  options=[dict(id=k,text=v) for k,v in opts] if typ=='L' else [dict(id=f'option-{j+1}',text=t) for j,t in enumerate(opts)]
  answer=options[0]['id'];options=options[n%len(options):]+options[:n%len(options)]
  e=dict(id='gbr-'+activity.lower(),countryId='gbr',articleId=id,type={'L':'location','C':'choice','P':'observation'}[typ],question=q,hint='读一读「'+blocks[ev[0]-1]['title']+'」，再找对应的线索。',explanation=blocks[ev[0]-1]['text'],options=options,answerId=answer,evidenceBlockIds=[f'{id}-b{b}' for b in ev])
  if typ=='L':e['mapScope']='world' if n==0 else 'country'
  if typ=='P':e['mediaId']=mid(photos[n][3]);e['diagram']=a.get('diagram','')
  if typ=='C' and 'diagram' in a:e['diagram']=a['diagram']
  exercises.append(e);a['exerciseId']=e['id']
 if i==14:a['sourceUrls'].append('https://www.nationalarchives.gov.uk/help-with-your-research/research-guides/indian-indentured-labourers/')
 if i==25:a['sourceUrls'].append('https://www.railwaymuseum.org.uk/sites/default/files/2023-10/Pages%20from%20LOCOMOTION%20report%20part%201.pdf')
 articles.append(a)
# Anchors are public place/landscape representatives, not animal nest coordinates.
place_specs=[
('thames-london','泰晤士河 · 伦敦',51.5009,-.1195,'英格兰 · 威斯敏斯特南岸',[1,2,3],'river','Thames|London|伦敦|泰晤士河','从南岸看河湾、桥与钟楼。','地图点表示威斯敏斯特南岸的一处观察区域，并不代表整条泰晤士河。河水从这里继续向东，流向河口。','先找水面，再找桥的两端。'),
('tower-bridge','伦敦塔桥',51.5055,-.0754,'英格兰 · 伦敦',[4],'bridge','Tower Bridge|塔桥','有两座塔楼、跨越泰晤士河的桥。','Tower Bridge 与西边的 London Bridge 是不同桥梁。桥面可开启，让合适的船只通过；照片展示桥面关闭的时刻。','看看桥面、塔楼和水面怎样排列。'),
('giants-causeway','巨人堤',55.2408,-6.5116,'北爱尔兰 · 安特里姆海岸',[5,6,7],'rock',"Giant’s Causeway|Giants Causeway|巨人之路",'玄武岩石柱排列在海岸。','熔岩冷却后收缩，形成裂缝和柱状节理。石柱的边数并非全部相同。巨人故事属于传说，不能代替地质证据。','比较柱顶的边和柱子之间的裂缝。'),
('belfast','贝尔法斯特',54.5965,-5.9301,'北爱尔兰 · 市中心',[8,9],'uk','Belfast','从市政厅与商场附近认识城市。','锚点是市政厅附近的公共空间。两张照片来自不同位置与时间，可观察建筑和行人空间，不能代表所有居民的生活。','找一种大家共同使用的设施。'),
('cardiff','卡迪夫',51.4814,-3.1811,'威尔士 · 市中心',[10,11],'welsh','Cardiff|Caerdydd','看城堡，也看一块双语站牌。','城市点在卡迪夫中心。站牌照片拍于 Cardiff Bay 站，其中 Bae／Bay 表示海湾；Caerdydd／Cardiff 都指卡迪夫。','把两行文字中表示同一地点的词找出来。'),
('eryri','Eryri 山地 · Llyn Idwal',53.1154,-4.0253,'威尔士 · 伊德瓦尔湖区域',[12,13],'eryri','Snowdonia|斯诺登尼亚|Llyn Idwal','湖面与山坡共同组成山地景观。','锚点是 Eryri 山地中的伊德瓦尔湖区域。两幅照片从不同方向看湖和山坡，不能只凭照片估计海拔。','先找湖岸，再沿山坡轮廓向上看。'),
('skomer','斯科默岛',51.737,-5.293,'威尔士 · 彭布罗克郡海岸外',[14,15,16],'puffin','Skomer|海鹦','海岸与海洋连接着海鹦的生活。','地图使用岛屿代表点，不标出巢穴位置。海鹦在海中找鱼，繁殖季回到岸边育雏；照片不是全年活动的完整记录。','看看衔鱼的海鹦，再想想食物从哪里来。'),
('edinburgh','爱丁堡城堡',55.9486,-3.1999,'苏格兰 · 城堡岩',[17,18],'castle','Edinburgh|Edinburgh Castle','城堡立在高于周围街道的岩丘上。','地图标记城堡位置，草市广场照片从下方望向城堡。岩丘与建筑共同构成城市轮廓，照片角度会影响高度感。','分开辨认岩坡和建筑墙体。'),
('glencoe','格伦科山谷',56.667,-4.986,'苏格兰 · 高地',[19,20],'valley','Glencoe|Glen Coe|Gleann Comhann','在山坡之间观察宽阔的谷地。','锚点是公开的三姊妹山观景区域。这里有古老火山岩，也受后来的冰川塑造；一张照片不能独自证明全部形成过程。','用手指沿山坡与谷底的连接处画一条线。'),
('stonehenge','巨石阵',51.1789,-1.8262,'英格兰 · 威尔特郡',[21,22],'stone','Stonehenge','石圈与遗址平面留下考古线索。','石圈约在公元前2500年建成，遗址经历多个阶段。平面图表示遗存与位置，并不是今天现场每一块石头都完整竖立。','对照照片与平面图，看见什么、还缺什么？'),
('shildon','希尔登 · Locomotion 博物馆',54.6213,-1.6428,'英格兰 · 达勒姆郡',[23,24],'rail','Shildon|Locomotion|希尔登','从一台早期机车读铁路故事。','此处标记今天的博物馆。机车照片摄于2009年的达灵顿旧陈列地；另一张是后来出版的1825年铁路开通题材插图，不是当日照片。','在真实机车图里找车轮，再比较历史插图。'),
('jurassic-coast','侏罗纪海岸 · 莱姆里吉斯',50.724,-2.948,'英格兰 · 多塞特',[25,26],'coast','Jurassic Coast|Lyme Regis|多塞特','海边岩层保留着漫长变化的线索。','这里选择莱姆里吉斯附近的蓝里阿斯岩层与海蚀平台。整段侏罗纪海岸跨越不同地质年代，不能把所有白色海崖当成同一层岩石。','比较崖壁的条带与海边平台的形状。')]
places=[]
for slug,name,lat,lon,region,mm,src,aliases,summary,desc,obs in place_specs:
 places.append(dict(id=aid(slug),countryId='gbr',name=name,category='城市' if slug in ['thames-london','belfast','cardiff'] else '历史' if slug in ['stonehenge','shildon','edinburgh'] else '自然',latitude=lat,longitude=lon,region=region,summary=summary,description=desc,observation=obs,mediaIds=[mid(n) for n in mm],sourceUrl=S[src],aliases=aliases.split('|'),articleIds=[a['id'] for a in articles if a.get('placeId')==aid(slug)],coordinateSource='WGS84 公共地点／景观代表锚点；与作品拍摄点分开说明',hotspots=[]))
# Hotspots are normalized against full uncropped source images.
hotspots=[(1,.87,.40,'钟楼','伊丽莎白塔高于旁边的议会建筑。'),(4,.38,.40,'塔楼','塔楼立在桥面上方。'),(5,.56,.50,'柱间裂缝','相邻石柱之间的暗线形成纵向裂缝。'),(9,.60,.75,'街道空间','建筑前方留有行人使用的道路。'),(10,.76,.74,'城堡建筑','石砌建筑位于草地后方。'),(13,.53,.35,'湖面','水面被山坡环绕。'),(16,.70,.45,'衔着的小鱼','鱼从喙边垂下，正文解释它来自海中。'),(17,.62,.25,'城堡轮廓','城堡的石墙在岩丘之上。'),(19,.65,.63,'谷底','两侧山坡之间是较低的谷地。'),(21,.56,.43,'横放的石头','横石跨在竖石上方。'),(23,.55,.84,'车轮','车身下方可见轮缘与辐条。'),(26,.65,.50,'岩层条带','深浅相间的纹理沿崖壁延伸。')]
for p,(n,x,y,label,explanation) in zip(places,hotspots):
 p['hotspots']=[dict(mediaId=mid(n),x=x,y=y,label=label,explanation=explanation)]
for id,coords in {'gbr-p03':[(.17,.49),(.5,.86),(.5,.14)],'gbr-p05':[(.65,.50),(.12,.12),(.08,.85)],'gbr-p06':[(.55,.84),(.29,.25),(.055,.55)]}.items():
 e=next(e for e in exercises if e['id']==id)
 for o in e['options']:o.update(zip(('x','y'),coords[int(o['id'][-1])-1]))
 e['mediaIds']=[e['mediaId']]
# M26 has no sea: distractor is the foreground below the cliff, not imaginary water.
e=next(e for e in exercises if e['id']=='gbr-p05')
next(o for o in e['options'] if o['id']=='option-3')['text']='崖脚的碎石'
section_titles=['国家名片','地理与气候','人们与语言','城市里的一天','饮食与物产','艺术与活动','城市与地标','海岸与自然','历史线索','有趣的问题']
sections={s:[a['id'] for a in articles if a['sectionId']==s] for s,*_ in rows}
timeline=[]
for key,period,title,body,n,slug in [('stonehenge','约公元前2500年','石圈留下的线索','巨石阵分阶段建造，它的全部用途仍有尚未确定的问题。',21,'stonehenge'),('railway','1825年','铁路带来的变化','用机车实物和历史插图，区分不同种类的证据。',23,'railway-change'),('votes','1928年','投票资格的变化','女性获得与男性相同的21岁投票年龄资格；查法案了解条件。',34,'voting-rights')]:timeline.append(dict(id='gbr-timeline-'+key,period=period,title=title,body=body,mediaId=mid(n),articleIds=[aid(slug)]))
facts=[dict(label='位置',value='欧洲西北'),dict(label='首都',value='伦敦'),dict(label='组成',value='四个部分')]
intro='沿着泰晤士河出发，看看桥怎样连接两岸。再走向石柱海岸、威尔士山地和苏格兰山谷，从照片、地图和档案里找到自己的发现。'
journeys=[]
for id,title,sub,n,slugs,stops in [('river-city','沿着河流进城','从河岸走向桥，再辨认钟与钟楼。',2,['thames-city','bridge-banks','bell-tower'],['河流穿城','连接两岸','钟与钟楼']),('coast','去海岸找线索','看岩层、石柱与海鹦，把照片和资料放在一起。',6,['jurassic-coast','causeway-columns','puffin-coast'],['层层岩石','石柱裂缝','海鹦的家']),('time','顺着时间找证据','从石圈、机车到一份改变投票资格的法案。',21,['stonehenge','railway-change','voting-rights'],['巨石阵','铁路的变化','投票的故事'])]:journeys.append(dict(id=id,title=title,subtitle=sub,coverTitle=title,mediaId=mid(n),articleIds=[aid(s) for s in slugs],stopTitles=stops))
source_titles=dict(zip(S, ['英国国家统计局 · 国家分类','Thames21 · 潮汐泰晤士河','National Trust · 巨人堤','英国气象局 · 区域气候','威尔士语言专员 · 卡迪夫地名','国家公园 · 盖尔语地名','伦敦交通局 · 地铁地图','伦敦塔桥 · 运行原理','皇家公园 · 圣詹姆斯公园生态','苏格兰食品标准局 · 燕麦食品','威尔士博物馆 · 果干面包','邱园 · 茶树','苏格兰乡村舞协会 · 凯利舞','莎士比亚环球剧场 · 建筑与历史','英足总 · 英国四地足球协会','英国议会 · 钟楼','爱丁堡城堡 · 历史','Eryri 国家公园 · 地名','威尔士野生动物信托 · 斯科默岛','英国地质学会 · 莱姆里吉斯','英国地质学会 · 格伦科','English Heritage · 巨石阵','科学博物馆集团 · Locomotion No.1','英国议会 · 1928年法案']))
country=dict(id='gbr',name='英国',code='GB',englishName='United Kingdom',coverage='editorial',revision=1,capital='伦敦',mediaId=mid(1),intro=intro,tagline='沿着泰晤士河出发',facts=facts,timeline=timeline,takeaways=['英国有英格兰、苏格兰、威尔士和北爱尔兰四个组成部分。','英国、大不列颠岛和爱尔兰岛指不同的范围。','照片、地图与档案，可以一起帮助我们查证想法。'],sources=[dict(title=source_titles[k],url=v,checkedAt='2026-11-09') for k,v in S.items()],sections=sections)
country['editorial']=dict(subtitle=country['tagline'],introduction=intro,startLabel='从泰晤士河开始',startJourneyId='river-city',questionArticleIds=[aid('four-parts'),aid('causeway-columns')],factOverrides=facts,directoryTitle='英国 · 探索目录',directory=dict(mediaIds=[mid(2),mid(5),mid(15)]),featuredDirectoryPlaceId=aid('giants-causeway'),featuredDirectoryTitle='下一站，去石柱海岸',timelineTitle='英国 · 历史线索',timeline=timeline,explore=dict(mediaId=mid(6),featuredTaskIds=['gbr-l03','gbr-p01','gbr-c10'],categories=[dict(id=k,title=t,mediaId=mid(n)) for k,t,n in [('location','找地图',12),('observation','看照片',5),('choice','找证据',23),('open','写观察',19)]]),discoveries=dict(mediaId=mid(2),recommendedPlaceIds=[aid('giants-causeway'),aid('skomer')],recommendationTitles=['再看石柱海岸','去找海鹦的家']),journeys=journeys,sections={s:dict(title=section_titles[i],summary=articles[i*3]['summary'],mediaId=mid(media_numbers[i*3])) for i,s in enumerate(sections)},featuredPlaceIds=[aid('giants-causeway'),aid('edinburgh'),aid('skomer')])
country['editorial']['sections']['daily'].update(primaryMapPlaceId=aid('thames-london'),primaryLabel='看看伦敦在地图哪里')
write('gbr.json',dict(country=country,articles=articles,places=places,exercises=exercises))
assert len(articles)==30 and len(exercises)==24 and len(places)==12
print('UK: 30 articles, 24 exercises, 6 observations, 12 places, 3 journeys')
