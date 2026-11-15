"""Assemble reviewed Australia pack, preserving independent country packs.
Run author_aus.py before this script. Network-free; media were checked visually.
"""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
D=ROOT/'tool/content/drafts'
j=json.loads((D/'aus.json').read_text())
media={m['id']:m for f in ['aus_assets.json','aus_more_assets.json'] for m in json.loads((D/f).read_text())['media']}
assert len(media)==17
cards=[('study','阅读人与土地的故事','https://aiatsis.gov.au/explore/first-peoples-australia'),('history-before','历史不从殖民开始','https://aiatsis.gov.au/explore/first-peoples-australia'),('history-colonial','殖民到来与生活变化','https://digital-classroom.nma.gov.au/defining-moments/first-fleet-arrives-sydney-cove'),('history-federal','1901年联邦成立','https://www.nma.gov.au/defining-moments/resources/federation'),('food-label','名称、单位与产地','https://www.foodstandards.gov.au/consumer/labelling/coo')]
for slug,title,url in cards:
 asset=f'assets/atlas/aus-{slug}.png';b=(ROOT/asset).read_bytes()
 media['aus-'+slug]=dict(id='aus-'+slug,asset=asset,caption=title+' · 原创学习卡，非实景或历史影像。',alt=title,credit='世界大百科 · 原创排版与文字示意',sourceUrl=url,license='CC BY 4.0（原创学习卡）',licenseUrl='https://creativecommons.org/licenses/by/4.0/',kind='diagram',width=1200,height=750,sha256=hashlib.sha256(b).hexdigest(),captureDate='不适用：原创学习卡',checkedAt='2026-11-11',processing='tool/content/render_aus_cards.swift；资料链接为知识依据，不表示原机构制作此图。')
for m in media.values():
 assert (ROOT/m['asset']).is_file()
 assert hashlib.sha256((ROOT/m['asset']).read_bytes()).hexdigest()==m['sha256']
 m['reviewStatus']='reviewed';m['displayCrop']='页面封面使用居中裁切；观察热点使用完整原图。'
by={a['id']:a for a in j['articles']}
for slug in ['first-peoples','languages','art-authors','museum-evidence']:
 by['aus-'+slug]['mediaId']='aus-study'
for a in by.values():
 text=''.join(b['text'] for b in a['blocks']);assert 450<=len(re.findall('[\u4e00-\u9fff]',text))<=650
 if a.get('activity'):a['activity']['mediaIds']=[a['mediaId']]
# Observation tasks with literal evidence in image; other tasks compare the limits of evidence.
for e in j['exercises']:
 a=by[e['articleId']]
 if e['type']=='observation':e['mediaId']=a['mediaId']
 if a['id']=='aus-opera-house':
  e.update(question='照片中哪一项可以直接看见？',options=[dict(id='option-1',text='港湾边的弯曲屋顶轮廓'),dict(id='option-2',text='设计者当时的想法'),dict(id='option-3',text='今晚的演出节目')],answerId='option-1',evidenceBlockIds=['aus-opera-house-b1','aus-opera-house-b3'],explanation='照片展示港湾边的屋顶外形。设计意图与演出安排需要其他资料。')
 if a['id']=='aus-before-colonisation':
  e.update(question='这张历史学习卡是哪一种材料？',options=[dict(id='option-1',text='帮助整理问题的原创文字卡'),dict(id='option-2',text='殖民之前拍摄的现场照片'),dict(id='option-3',text='所有社区认可的统一图案')],answerId='option-1',explanation='图注明确标注原创学习卡，并非历史影像，也不代表某个社区的文化图案。',evidenceBlockIds=['aus-before-colonisation-b4','aus-before-colonisation-b6'])
# Every place has its own account and observation instead of repeating a caption.
descriptions={
'sydney-harbour':('悉尼港把水上交通、城市地标和岸边生活放在一起。先看歌剧院，再找海港大桥，最后观察它们与水面的关系。封面为黄昏景观，不能用天空亮度判断全年天气。','找出屋顶轮廓、桥与水面。哪些结构跨过水面，哪些位于岸边？'),
'canberra':('堪培拉是澳大利亚首都。伯利·格里芬湖与桥、步道和公共空间共同构成城市景观。地点标记代表湖岸附近，照片从桥梁附近看水面，并不等于整座首都的全景。','观察桥下结构的方向，再找水面。跨越水面与沿岸移动有什么区别？'),
'melbourne':('墨尔本的电车与街道共同组成城市交通空间。本页照片拍摄于2008年，适合观察车体与轨道，不能代替当前运营资料。文章用虚构甲乙丙站点练习换乘，再说明如何查阅真实线路图。','找到车体、轨道和架空线。照片能告诉你下一班车何时到吗？'),
'great-barrier-reef':('大堡礁由许多礁体、岛屿和周围海域共同构成复杂环境。这里使用Flynn Reef的水下照片作为具体观察点。多种外形的珊瑚群体相邻生长；标记不是大堡礁整体轮廓或海洋公园边界。','点击照片里的珊瑚群体，描述分枝、片状外形与周围水体。颜色不能单独证明整个礁区健康。'),
'daintree':('丹特里位于昆士兰北部，是认识热带雨林的地点之一。照片里不同高度的植物、叶片与林下空间提供观察线索。把这里与内陆干旱区域比较，可以发现澳大利亚并不是只有一种自然环境。','沿画面从地面看到林冠，寻找植物在不同高度占据的空间。不要只凭一片叶子推断整片森林的物种。'),
'kakadu':('卡卡杜位于北领地，具有自然与文化两方面的重要意义。封面展示公开观景区域的岩壁与植被。北部的湿季和干季帮助理解环境变化，但这张照片只记录一个时刻；本页不展示敏感文化地点。','记录岩壁与植被的分布，再提出一个需要季节记录才能回答的问题。'),
'uluru':('乌鲁鲁是岩体，也是与当地Aṉangu生活和文化持续相连的地方。这里使用原创学习卡和地图位置，配合公园公开资料理解地形与文化。部分文化知识和摄影有明确分享条件；学习以当地公开说明为依据。','阅读公开资料，记下讲述者与地点的关系。你还想向资料提出什么问题？'),
'murray-yarrawonga':('墨累河流经澳大利亚东南部。亚拉旺加附近的照片记录一个河段的水面与岸边环境，国家地图则显示更长的河道。河道、岸边湿地与流域不是同一种范围，不要把代表点当作河流起点。','观察水面与岸边的相对位置，再沿地图河线寻找上游和下游方向。'),
'twelve-apostles':('十二使徒岩位于维多利亚州海岸。石灰岩海蚀柱与临海悬崖是长期海岸变化留下的景观。名称不表示每个时期、每个角度都能看见十二根石柱。照片拍摄于2019年，适合观察形状，不代表今日数量。','找出与岸壁分开的岩柱。哪些部分是直接看见的，哪些形成过程需要地质资料解释？'),
'perth':('珀斯位于澳大利亚西部。本页从国王公园方向看城市与天鹅河，水面和建筑帮助建立城市空间的印象。它与东海岸的悉尼相距很远，不能把两地的河流、港湾或气候资料混用。','描述水面与建筑的位置。切换国家地图，看看珀斯与悉尼分别位于大陆哪一侧。'),
'kangaroo-island':('袋鼠岛位于南澳大利亚外海。这里的照片展示弗林德斯蔡斯国家公园的Remarkable Rocks岩石景观。名字中有袋鼠，不表示每张岛上照片都有袋鼠；风景与动物都应按具体画面和资料认识。','观察大岩石的外形与周围地面。能从照片直接判断岩石形成用了多久吗？'),
'cradle-mountain':('摇篮山位于塔斯马尼亚。山体与鸽湖帮助认识澳大利亚岛屿上的山地环境，不能把澳大利亚全部想象成炎热沙漠。地图把塔斯马尼亚与大陆放在相同地理位置关系中，便于比较海峡和陆地。','找湖面与山脊的轮廓，再回到地图找大陆和塔斯马尼亚之间的巴斯海峡。')}
for p in j['places']:
 p['description'],p['observation']=descriptions[p['id'][4:]]
 if p['id']=='aus-kangaroo-island':p['coordinateSource']='South Australian Tourism Commission 景点页 Open in Maps 公共代表点（WGS84）；不等于摄影点'
 p['aliases'] += {'aus-sydney-harbour':['Sydney','悉尼歌剧院'],'aus-canberra':['Canberra','堪培拉'],'aus-melbourne':['Melbourne'],'aus-great-barrier-reef':['Great Barrier Reef','Flynn Reef','大堡礁'],'aus-murray-yarrawonga':['Murray','Yarrawonga'],'aus-cradle-mountain':['Tasmania','Cradle Mountain','塔斯马尼亚']}.get(p['id'],[])
 if p['id']=='aus-great-barrier-reef':p['hotspots']=[dict(mediaId='aus-reef',x=.38,y=.58,label='片状外形',explanation='这部分珊瑚群体呈现层叠的片状外形。形状描述不等于确定物种。'),dict(mediaId='aus-reef',x=.75,y=.24,label='周围水体',explanation='群体周围还有水下空间；照片只记录礁区的一小部分。')]
# Refresh images in section headers after editorial substitutions.
for sid,section in j['country']['editorial']['sections'].items():
 section['mediaId']=next(a['mediaId'] for a in by.values() if a['sectionId']==sid)
j['media']=list(media.values())
(ROOT/'tool/content/editorial/aus.json').write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n')
print(f"Australia: {len(by)} articles, {len(j['places'])} places, {len(j['exercises'])} exercises, {len(media)} images")
