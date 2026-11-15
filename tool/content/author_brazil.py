"""Compile Brazil's thirty reviewed readings, keeping legacy IDs addressable.

Run after importing brazil_assets.json. No network, no other country edits.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EDITORIAL = ROOT / 'tool/content/editorial/brazil.json'
data = json.loads(EDITORIAL.read_text())
plan = json.loads((ROOT / 'tool/content/drafts/brazil_plan.json').read_text())
texts = {}
for chunk in (ROOT / 'tool/content/sources/brazil_expanded.txt').read_text().split('@@ ')[1:]:
    lines = chunk.strip().splitlines()
    texts[lines[0]] = [line.split('|', 1) for line in lines[1:]]

S = {
 'biomes': 'https://educa.ibge.gov.br/jovens/conheca-o-brasil/territorio/18307-biomas-brasileiros.html',
 'amazon': 'https://whc.unesco.org/en/list/998/',
 'pantanal': 'https://whc.unesco.org/en/list/999/',
 'cerrado': 'https://whc.unesco.org/en/list/1035/',
 'brasilia': 'https://whc.unesco.org/en/list/445/',
 'rio': 'https://whc.unesco.org/en/list/1100/',
 'salvador': 'https://whc.unesco.org/en/list/309/',
 'iguazu': 'https://whc.unesco.org/en/list/355/',
 'archaeology': 'https://whc.unesco.org/en/list/606/',
 'people': 'https://www.ibge.gov.br/brasil-indigena/',
 'languages': 'https://educa.ibge.gov.br/criancas/voce-sabia/23084-linguas-indigenas.html',
 'climate': 'https://www.ncei.noaa.gov/news/weather-vs-climate',
 'frevo': 'https://bcr.iphan.gov.br/bens-culturais/frevo/',
 'capoeira': 'https://ich.unesco.org/en/RL/capoeira-circle-00892',
 'cassava': 'https://www.fao.org/4/x5458e/x5458e05.htm',
 'cacao': 'https://www.kew.org/read-and-watch/kew-gardens-cacao-how-to-make-chocolate',
 'capybara': 'https://zoo.sandiegozoo.org/animals/capybara',
 'abolition': 'https://www12.senado.leg.br/institucional/arquivo/documentos-apenas/arquivos-lei-aurea',
 'river-transport': 'https://sophia.antaq.gov.br/Terminal/Busca/Download?codigoArquivo=51506&tipoMidia=0',
}
# slug: cover, source keys, glossary term, definition, place (where applicable)
specs = {
 'find-brazil': ('rio-panorama','biomes','方位','描述一个地方相对另一个地方的位置。',''),
 'capital': ('brasilia-congress','brasilia','首都','国家中央政府所在的城市。','brasilia'),
 'landscapes': ('pampa','biomes','景观','一个地方可以观察到的自然与人文要素组合。',''),
 'weather-climate': ('pantanal','climate','气候','一个地区经过较长时间观察得到的天气特征。','brazil-pantanal'),
 'languages': ('salvador','languages people','官方语言','国家制度中规定使用的语言；不等于居民只会这一种语言。',''),
 'place-names': ('brasilia-cathedral','brasilia','地名','人们用来识别某个地方的名称。','brasilia'),
 'community': ('belem-market','people','社区','人们共同生活与活动形成的联系，内部仍有不同经历。','brazil-belem-market'),
 'river-transport': ('boat','river-transport amazon','码头','船只停靠、人员上下或货物装卸的设施。','brazil-manaus-meeting-waters'),
 'market-labels': ('acai','cacao','产地','商品或原料生产的地方，与名称、价格是不同信息。','brazil-belem-market'),
 'public-space': ('park','brasilia','公共空间','供人们共同使用的空间，例如公园与广场。','brasilia'),
 'cassava': ('cassava','cassava','木薯','一种热带作物，根部可作为经过适当加工的食物原料。',''),
 'cacao': ('cacao','cacao','可可豆','可可果实中的种子，是制作巧克力的原料之一。',''),
 'regional-food': ('fruit','biomes','地方差异','不同地区在环境、生活与习惯等方面呈现的差别。','brazil-belem-market'),
 'frevo': ('frevo','frevo','弗雷沃','与巴西伯南布哥地区联系密切的音乐、舞蹈及集体文化实践。','brazil-recife'),
 'capoeira': ('capoeira','capoeira','卡波耶拉','把动作、音乐与集体参与联系起来的非裔巴西文化实践。','brazil-salvador'),
 'rhythm': ('berimbau','capoeira frevo','节拍','组织音乐时间的拍点与间隔关系。',''),
 'rio-bay': ('rio-panorama','rio','海湾','海洋伸入陆地的部分，与外侧海域相连。','brazil-rio-guanabara'),
 'salvador': ('lacerda','salvador','高差','两个位置之间的高度差别。','brazil-salvador'),
 'capybara': ('capybara','capybara pantanal','栖息地','动物生活、取食、休息等活动所依赖的环境。','brazil-pantanal'),
 'forest-layers': ('forest','amazon','树冠','树木上部枝叶形成的部分。','brazil-anavilhanas'),
 'cerrado': ('cerrado','biomes cerrado','塞拉多','包含草地、灌木和树木等环境的巴西生物群系。','brazil-chapada-veadeiros'),
 'before-arrival': ('pottery','archaeology people','考古材料','通过遗址、器物等研究过去人类活动的材料。',''),
 'abolition': ('abolition','abolition','废奴','废除奴隶制度；后续社会生活仍需要继续研究。',''),
 'new-capital': ('construction','brasilia','档案','记录具体事件、过程或制度的原始材料。','brasilia'),
 'iguazu': ('iguazu-detail','iguazu','视角','观察或拍摄对象的位置与方向。','iguazu'),
 'observation': ('meeting-waters','amazon','证据','能够支持或检验某个判断的材料。','brazil-manaus-meeting-waters'),
}
open_slugs = {'landscapes','community','public-space','regional-food','water-evidence','observation'}
observations = {'place-names','market-labels','frevo','rhythm','new-capital','capybara'}
locations = {'find-brazil','capital','river-transport','rio-bay','salvador','iguazu'}
diagrams = {'meeting-waters':'meeting-waters','six-biomes':'six-biomes','capybara':'wetland','forest-layers':'forest-layers','market-labels':'market-labels','cacao':'cacao','rhythm':'rhythm','place-names':'place-names'}
questions = {
 'weather-climate': ('比较一个地区的气候，哪种材料更合适？','同一时期的多年降水记录','只看今天的一场雨'),
 'languages': ('认识巴西居民的语言，哪句话更准确？','葡萄牙语广泛使用，语言生活仍然多样','所有人只会使用同一种语言'),
 'place-names': ('地名卡中，Brasília 对应哪个中文名称？','巴西利亚','里约热内卢'),
 'market-labels': ('在示例标签中，哪一项告诉我们产地？','产地：巴西·巴伊亚州','名称：可可豆'),
 'cassava': ('木薯根与木薯粉有什么关系？','从植物原料到加工食品','只是把外皮涂成白色'),
 'cacao': ('巧克力中的可可原料来自哪里？','可可果实里的种子经过加工','直接把完整果皮变成糖块'),
 'frevo': ('理解这张弗雷沃照片，哪组材料更充分？','照片、音乐舞蹈说明与地区背景','只看一把彩色小伞'),
 'capoeira': ('卡波耶拉圆圈里的音乐有什么作用？','联系动作、回应与共同参与','与所有动作毫无关系'),
 'rhythm': ('哪种回应与图解中的等间隔四拍相同？','四次，间隔均匀','两次，间隔随意'),
 'capybara': ('切换水位示意后，水位变化可能影响什么？','动物可以使用的水面与陆地空间','巴西国界的位置'),
 'forest-layers': ('森林分层图帮助比较什么？','不同高度与光线等环境线索','把森林分成互不联系的房间'),
 'cerrado': ('塞拉多只有草吗？','不是，草、灌木与树都可能出现','是，任何地方都不可能有树'),
 'before-arrival': ('欧洲航海者到来前，这里是否已有人生活？','有，考古材料支持长期的人类活动','没有，所有历史从欧洲人到来才开始'),
 'abolition': ('《黄金法》能证明所有不平等立即消失吗？','不能，还需要研究之后的生活资料','能，一张法律文本说明所有人的生活'),
 'new-capital': ('研究巴西利亚建设阶段，哪张材料更合适？','有日期与地点说明的施工照片','没有出处的想象效果图'),
}
place_specs = [
 ('brazil-anavilhanas','阿纳维利亚纳斯','自然',-2.65,-60.75,'北部 · 内格罗河','河流、岛屿与森林交错的环境。','anavilhanas','amazon',['forest-layers','river-transport']),
 ('brazil-belem-market','贝伦 · Ver-o-Peso市场','生活',-1.452,-48.504,'北部 · 贝伦','从市场建筑与商品寻找地方生活线索。','belem-market','amazon',['market-labels','community','regional-food']),
 ('brazil-rio-guanabara','里约 · 瓜纳巴拉湾','城市',-22.95,-43.17,'东南部 · 里约热内卢','山体、海湾与城市在这里相邻。','rio-panorama','rio',['rio-bay']),
 ('brazil-tijuca','蒂茹卡森林','自然',-22.954,-43.284,'东南部 · 里约热内卢','从瀑布与植被认识城市中的森林。','tijuca','rio',['rio-bay','six-biomes']),
 ('brazil-salvador','萨尔瓦多','城市',-12.972,-38.510,'东部 · 巴伊亚州','连接高处与低处的历史城市。','salvador','salvador',['salvador','capoeira']),
 ('brazil-recife','累西腓','文化',-8.063,-34.871,'东北部 · 伯南布哥州','从广场与弗雷沃活动认识具体的文化背景。','recife','frevo',['frevo','rhythm']),
 ('brazil-pantanal','潘塔纳尔湿地','自然',-17.1,-56.6,'中西部 · 北潘塔纳尔','水位变化联系水面、植物与动物活动。','pantanal','pantanal',['capybara','weather-climate']),
 ('brazil-chapada-veadeiros','查帕达－多斯－维阿迪罗斯','自然',-14.1,-47.65,'中部 · 戈亚斯州','在国家公园观察塞拉多多样的植被景观。','cerrado','cerrado',['cerrado']),
 ('brazil-caatinga','卡廷加 · Queimadas','自然',-7.36,-35.90,'东北部 · 帕拉伊巴州','从有出处的植被照片认识半干旱环境。','caatinga','biomes',['six-biomes']),
]
def put(kind,row):
    data[kind] = [r for r in data.get(kind,[]) if r['id'] != row['id']] + [row]

for section, rows in plan['sections'].items():
    for slug,title in rows:
        aid='brazil-'+slug
        if slug not in texts:
            a=next(a for a in data['articles'] if a['id']==aid)
        else:
            media,sources,term,definition,place=specs[slug]
            blocks=[dict(id=f'{aid}-b{i+1}',title=t,text=b) for i,(t,b) in enumerate(texts[slug])]
            a=dict(id=aid,countryId='brazil',sectionId=section,title=title,summary=blocks[0]['text'].split('。')[0]+'。',
                   blocks=blocks,mediaId='brazil-'+media,sourceUrls=[S[s] for s in sources.split()],
                   term=term,definition=definition,readingMinutes=4,revision=1,schemaVersion=1,locale='zh-CN',updatedAt='2026-11-11',reviewStatus='sourceChecked')
            if place:a['placeId']=place
        a['glossary']=[dict(term=a['term'],definition=a['definition'])]
        if slug in diagrams:a['diagram']='brazil-'+diagrams[slug]
        if slug in open_slugs:
            a.pop('exerciseId',None)
            a['activity']=dict(id='brazil-o-water' if slug=='water-evidence' else f'brazil-open-{slug}',type='open',title='记录自己的发现',
                prompt='选一处可见线索，区分看见的内容、暂时的猜想与还想知道的问题。',fields=['我看见','我猜想','我还想知道'],
                mediaIds=[a['mediaId']],suggestedArticleIds=['brazil-meeting-waters','brazil-capybara'])
        elif slug in texts:
            eid=aid+'-check';a['exerciseId']=eid
            e=dict(id=eid,countryId='brazil',articleId=aid,type='location' if slug in locations else 'observation' if slug in observations else 'choice',
                   hint='先阅读正文，再用名称、图片说明与图解核对线索。',explanation=a['blocks'][-1]['text'],evidenceBlockIds=[a['blocks'][0 if slug=='river-transport' else -1]['id']])
            if slug in locations:
                if slug=='find-brazil':
                    e.update(question='先找到南美洲，再选择巴西。',mapScope='world',options=[dict(id=id,text=t) for id,t in [('brazil','巴西'),('egypt','埃及'),('china','中国')]],answerId='brazil')
                else:
                    answer={'capital':'brasilia','river-transport':'brazil-manaus-meeting-waters','rio-bay':'brazil-rio-guanabara','salvador':'brazil-salvador','iguazu':'iguazu'}[slug]
                    names={'brasilia':'巴西利亚','brazil-manaus-meeting-waters':'马瑙斯 · 两河交汇','brazil-rio-guanabara':'里约 · 瓜纳巴拉湾','brazil-salvador':'萨尔瓦多','iguazu':'伊瓜苏瀑布'}
                    candidates=list(dict.fromkeys([answer,'brasilia','brazil-rio-guanabara','brazil-manaus-meeting-waters']))[:3]
                    e.update(question='在地图上找到'+names[answer]+'。',mapScope='country',options=[dict(id=p,text=names[p]) for p in candidates],answerId=answer)
            else:
                q,correct,wrong=questions[slug]
                # Alternating positions prevents a constant first-choice shortcut.
                options=[dict(id='evidence',text=correct),dict(id='appearance',text=wrong)]
                if sum(map(ord,slug))%2:options.reverse()
                e.update(question=q,options=options,answerId='evidence')
                if slug in observations:
                    if slug in diagrams:e['diagram']='brazil-'+diagrams[slug]
                    else:e['mediaIds']=[a['mediaId']]
            put('exercises',e)
        put('articles',a)

a=next(a for a in data['articles'] if a['id']=='brazil-river-transport')
a['blocks'][0]['text'] += '本页港口照片拍摄于北部城市马瑙斯，可在两河交汇地点附近找到它的位置。'
# Supplemental photographs stay next to the paragraph they illustrate.
block_media = {
 'landscapes': [(1,'caatinga'),(2,'pampa'),(3,'pantanal')],
 'six-biomes': [(1,'tijuca'),(2,'pampa'),(3,'caatinga')],
 'river-transport': [(1,'anavilhanas')],
 'cassava': [(1,'flour'),(3,'cassava-processing')],
 'cacao': [(2,'cacao-beans')],
 'regional-food': [(1,'acai'),(2,'fruit')],
 'capoeira': [(2,'berimbau')],
 'brasilia': [(2,'brasilia-congress'),(3,'brasilia-cathedral')],
 'salvador': [(2,'salvador')],
 'capybara': [(2,'pantanal'),(3,'caiman')],
 'forest-layers': [(3,'anavilhanas')],
 'iguazu': [(1,'iguazu')],
}
# Clear this obsolete illustration link from earlier drafts: the macaw photo is
# from Pantanal, not proof of a species occurring at Anavilhanas.
next(a for a in data['articles'] if a['id']=='brazil-forest-layers')['blocks'][1].pop('mediaId',None)
for slug,rows in block_media.items():
    article=next(a for a in data['articles'] if a['id']=='brazil-'+slug)
    for index,media in rows:article['blocks'][index]['mediaId']='brazil-'+media

# A current, sourced map is now available; don't leave provisional wording behind.
a=next(a for a in data['articles'] if a['id']=='brazil-six-biomes')
a['mediaId']='brazil-cerrado';a['revision']=2
a['blocks'][-1]['text']='如果有人问“巴西到处都是雨林吗”，可以回答不是，并举出湿地或草地等案例。进一步比较，可以打开标明IBGE二〇一九年版本的生态地图，寻找六个区域的位置。生态区边界不等于今天仍被植被覆盖的范围；比较现状还需要日期与方法明确的调查资料。'
next(e for e in data['exercises'] if e['id']=='brazil-six-biomes-check')['explanation']=a['blocks'][-1]['text']
# Stable IDs for the old three questions remain resolvable in archived history.
base=json.loads((ROOT/'assets/content/catalog.json').read_text())
legacy=next(c for c in base['countries'] if c['id']=='brazil')['quiz']
for q in legacy:
    q=dict(q);q.update(countryId='brazil',articleId='brazil-geography' if q['type']=='location' else 'brazil-nature',status='archived',archivedAt='2026-11-11',replacementExerciseId='brazil-find-brazil-check' if q['type']=='location' else 'brazil-six-biomes-check')
    put('archivedExercises',q)

for pid,name,category,lat,lon,region,summary,media,source,slugs in place_specs:
    put('places',dict(id=pid,countryId='brazil',name=name,category=category,latitude=lat,longitude=lon,region=region,summary=summary,
        description=summary+'地图标记是区域观察锚点，不表示保护区边界或现场导航位置。请结合图片说明核对具体拍摄地点与时间。',
        observation='找一个清楚可见的细节，再提出一个需要更多资料的问题。',mediaIds=['brazil-'+media],sourceUrl=S[source],coordinateSource='WGS84，城市或区域的概略观察位置；照片地点见媒体来源。',aliases=[name,media],articleIds=['brazil-'+s for s in slugs],hotspots=[]))
for pid,media,articles in [('brasilia',['brasilia-night','brasilia-congress','brasilia-cathedral','park','construction'],['brasilia','capital','public-space','new-capital']),('iguazu',['iguazu','iguazu-detail'],['iguazu']),('brazil-pantanal',['pantanal','capybara','caiman','macaw'],['capybara','weather-climate']),('brazil-belem-market',['belem-market','acai'],['market-labels','community']),('brazil-salvador',['salvador','lacerda','capoeira'],['salvador','capoeira']),('brazil-recife',['recife','frevo'],['frevo','rhythm'])]:
    p=next((p for p in data['places'] if p['id']==pid),None)
    if p is None:
        p=dict(id=pid,countryId='brazil',name='伊瓜苏瀑布',category='自然',latitude=-25.69,longitude=-54.44,region='南部 · 巴西与阿根廷交界附近',summary='瀑布、水雾与森林相联系。',description='从有出处的照片比较整体与局部，不把不同视角当成水量变化记录。',observation='观察水流、岩壁与植被的位置关系。',sourceUrl=S['iguazu'],coordinateSource='WGS84，瀑布区域观察锚点，非步道导航。',aliases=['Iguaçu','Iguazu'],hotspots=[])
    p['mediaIds']=['brazil-'+m for m in media];p['articleIds']=['brazil-'+a for a in articles];put('places',p)

hotspots = {
 'brazil-manaus-meeting-waters': [('meeting-waters',.36,.48,'深色河水','内格罗河的深色水带；颜色本身不能证明水质。'),('meeting-waters',.64,.68,'黄褐色河水','携带泥沙的河水与另一股水流相遇。')],
 'brasilia': [('brasilia-congress',.48,.38,'高楼与穹顶','两座高楼与较低建筑共同构成国会建筑群。')],
 'brazil-rio-guanabara': [('rio-panorama',.55,.40,'海湾水面','湾内水面与山体、城市空间相邻；照片视角不表示真实距离。')],
 'brazil-pantanal': [('capybara',.42,.50,'水豚与水面','水豚身体靠近水面，岸边的陆地仍是环境的一部分。'),('capybara',.18,.62,'头部的位置','头部靠近水面；照片没有显示所有脚部结构。')],
 'brazil-belem-market': [('belem-market',.53,.39,'市场建筑','建筑与外围空间共同构成这次市场观察。')],
 'brazil-anavilhanas': [('anavilhanas',.40,.45,'森林与水道','森林岛屿与水道相邻，照片下方还可见飞机机翼。')],
 'brazil-tijuca': [('tijuca',.55,.60,'落水与植物','水沿高差落下，周围可以看见植物。')],
 'brazil-salvador': [('salvador',.46,.57,'街道与建筑','不同立面的建筑沿街分布；不能据此推断每位居民的经历。')],
 'brazil-recife': [('recife',.50,.58,'广场边缘','建筑面向广场，图片只是这个公共空间的一次记录。')],
 'brazil-chapada-veadeiros': [('cerrado',.25,.67,'不同高度的植被','可以同时观察较低植物与较高木本植物，塞拉多不只有草。')],
 'iguazu': [('iguazu-detail',.57,.43,'落水与水雾','白色水花与雾气是可见线索，不等于流量测量结果。')],
 'brazil-caatinga': [('caatinga',.50,.49,'枝干与植被','这个地点的照片呈现许多枝干；不能由一个时刻推断全年情况。')],
}
for pid,points in hotspots.items():
    p=next(p for p in data['places'] if p['id']==pid)
    p['hotspots']=[dict(mediaId='brazil-'+m,x=x,y=y,label=label,explanation=explanation) for m,x,y,label,explanation in points]

c=data['country'];c['revision']=3;c['mediaId']='brazil-rio-panorama'
c['sections']={s:['brazil-'+slug for slug,_ in rows] for s,rows in plan['sections'].items()}
c['timeline']=[dict(period=p,title=t,body=b) for p,t,b in [
 ('欧洲航海者到来以前','长期的人类活动','考古遗址与器物提供具体地区的线索，不能把不同人群和年代混为一谈。'),
 ('1549—1763年','萨尔瓦多作为首都','历史中心连接城市建设、殖民历史与不同人群的经历。'),
 ('1888年5月13日','废除奴隶制','《黄金法》确立法律变化，之后人们的生活仍需要继续研究。'),
 ('1956—1960年','建设巴西利亚','规划与众多建设者的劳动共同形成新首都，1960年迁都。'),
 ('今天','继续认识多样的巴西','结合具体社区、生态区和有日期的材料更新自己的认识。')]]
e=c['editorial']
e['timelineTitle']='巴西 · 历史线索'
e['timelineIntro']=dict(title='先看材料，再问年代',summary='器物、法律与施工照片分别能回答什么？',articleId='brazil-before-arrival')
e['timeline']=[dict(id='brazil-timeline-'+slug,period=period,title=title,body=body,mediaId='brazil-'+media,articleIds=['brazil-'+slug]) for slug,period,title,body,media in [
 ('before-arrival','欧洲航海者到来以前','器物与遗址中的生活线索','材料类型：考古遗物。图中为博物馆藏马拉若文化陶器，不代表所有地区或今天所有原住民。','pottery'),
 ('salvador','1549—1763年','萨尔瓦多作为首都','材料类型：当代街景。照片帮助观察保留下来的城市空间，不是殖民时代的现场照片。','salvador'),
 ('abolition','1888年5月13日','《黄金法》废除奴隶制','材料类型：法律档案。法律改变制度，之后人们的生活仍需结合更多资料研究。','abolition'),
 ('new-capital','1959年施工记录','建造新的首都','材料类型：有日期的施工照片。巴西利亚于1960年成为首都；现场记录呈现建设过程的一部分。','construction'),
 ('brasilia','2011年夜间影像','从上方观察城市布局','材料类型：宇航员实拍。灯光帮助观察道路连接，不是实时交通或居民统计。','brasilia-night'),
]]
for j in e['journeys']:
    spec=next(s for s in plan['journeys'] if s['id']==j['id']);j['articleIds']=['brazil-'+s for s in spec['articleIds']]
    j['stopTitles']={'river-forest':['两河交汇','水路与生活','森林的层次'],'city-life':['读懂城市布局','山海之间','连接高低城区'],'nature-rhythm':['湿地与水豚','塞拉多的植物','瀑布与观察']}[j['id']]
    j['mediaId']='brazil-'+{'river-forest':'meeting-waters','city-life':'brasilia-cathedral','nature-rhythm':'capybara'}[j['id']]
    j['subtitle']='三站阅读 · 按线索连接不同地点'
section_media=['rio-panorama','meeting-waters','salvador','belem-market','cacao','frevo','lacerda','capybara','construction','iguazu-detail']
section_names=['国家名片','地理与环境','人们与语言','日常生活','食物的来处','文化与节奏','城市与地标','自然与生命','历史线索','大问题与观察']
for (s,rows),m,title in zip(plan['sections'].items(),section_media,section_names):
    e['sections'][s].update(title=title,mediaId='brazil-'+m,summary=' · '.join(t.rstrip('？') for _,t in rows[:2]))
e['directory']['mediaIds']=['brazil-forest','brazil-macaw','brazil-iguazu']
e['featuredPlaceIds']=['brasilia' if s=='brasilia' else 'iguazu' if s=='iguazu' else 'brazil-'+s for s in plan['places']]
e['discoveries'].update(mediaId='brazil-capybara',recommendedPlaceIds=['brazil-pantanal','brazil-salvador','iguazu'],recommendationTitles=['观察湿地与水豚','寻找城市的高差','比较瀑布的视角'])
e['explore'].update(mediaId='brazil-capybara',featuredTaskIds=['brazil-find-brazil-check','brazil-capybara-check','brazil-market-labels-check'])
for cat in e['explore']['categories']:
    cat['mediaId']='brazil-'+{'location':'rio-panorama','observation':'capybara','choice':'meeting-waters','open':'belem-market'}[cat['id']]
for key,url in S.items():
    if not any(s['url']==url for s in c['sources']):c['sources'].append(dict(title='巴西内容参考 · '+key,url=url,checkedAt='2026-11-11'))
asset_rows=json.loads((ROOT/'tool/content/editorial/brazil_assets.json').read_text())['media']
asset_sources={m['id']:m['sourceUrl'] for m in asset_rows}
for article in data['articles']:
    if article['id'] in {aid for group in c['sections'].values() for aid in group}:
        source=asset_sources.get(article['mediaId'])
        if source and source not in article['sourceUrls']:article['sourceUrls'].append(source)
EDITORIAL.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print('Brazil: 30 new readings, 24 active tasks, 6 open activities, 12 curated places; legacy records preserved.')
