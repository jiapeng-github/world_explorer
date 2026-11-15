"""Import visually checked Commons files with the exact original metadata.
Input: numbered NN.img and NN.chosen.json from Commons imageinfo API.
Original teaching cards are rendered by render_deu_cards.swift.
"""
import json,html,re,hashlib,sys
from pathlib import Path
from fetch_china_media import image_size
ROOT=Path(__file__).resolve().parents[2];src=Path(sys.argv[1]);dest=ROOT/'assets/atlas'
captions={1:'莱茵河谷与卡茨城堡；河流绕过山坡。',2:'柏林施普雷河岸，2019年5月；拍摄时刻的城市水面。',3:'柏林奥伯鲍姆桥，2011年；桥跨越施普雷河。',4:'科布伦茨两河汇合处的航拍，2021年；摩泽尔河汇入莱茵河。',5:'科布伦茨德意志之角与两侧水道，2007年；与另一幅航拍视角不同。',6:'科隆莱茵河岸的公共空间，2014年。',7:'科隆霍亨索伦桥与大教堂，2009年；夜景不表示建筑年代。',8:'汉堡港集装箱装卸设施，2004年。',9:'汉堡港岸边建筑与船只，2016年。',10:'Kurt Rasmussen：莱比锡奥古斯都广场的15路电车，2008年7月15日；不是当前时刻表。',11:'莱比锡有轨电车与站台，2017年。',12:'美因茨古腾堡博物馆历史馆舍外观，2010年；不是当前开放信息。',13:'美因茨古腾堡博物馆展示的手动印刷装置，2019年；不主张是古腾堡亲用原件。',14:'德绍包豪斯建筑外观；来源未注明拍摄日期。',15:'德绍包豪斯建筑另一视角，2025年。',16:'从玛丽安桥方向看新天鹅堡，2011年。',17:'原创建筑史资料摘记：新天鹅堡1869年9月5日奠基；非历史文件原件。',18:'亚斯蒙德国家公园山毛榉林，2024年。',19:'亚斯蒙德国家公园森林的另一视角，2025年；与第一幅不构成同地点前后对照。',20:'比苏姆附近德国瓦登海的潮沟，2018年；单张照片无法判断潮向。',21:'本瑟尔西尔以东的德国瓦登海岸，2021年；包含人工岸边设施。',22:'国王湖与圣巴托洛梅教堂及周围山地，2016年。',23:'从耶纳山看贝希特斯加登周围山地，2021年；画面可能延伸到国界之外。',24:'包岑双语地名牌：德语Bautzen、上索布语Budyšin，2006年。',25:'包岑老城景观，2020年。',26:'金属字版与凸版印刷装置的近景；不主张是古腾堡时期文物。',27:'切开的面包，切面可见孔洞；作为面包结构的一般例子，不代表所有德国面包。',28:'德国阿默塔尔附近的土豆收获作业，2011年。',29:'德国联邦档案馆：1990年7月25日柏林潘科市场；历史影像，不表示当前摊位或价格。',30:'原创虚构食品标签：苹果、千克、产地德国；不表示照片中商品的真实信息。',31:'原创名称卡：Berlin德语、柏林中文，指同一城市。',32:'原创四拍节奏卡，每拍间隔相同。',33:'德国耶拿附近阿尔特格莱斯贝格自然保护区山毛榉林中的倒木，2016年；这是另一处森林，不是亚斯蒙德。',34:'1989年勃兰登堡门附近柏林墙上的人群；历史资料，不等于1990年统一当天。',35:'德国联邦档案馆：1990年9月27日波恩联邦参议院统一相关会议。',36:'原创历史资料类型卡：核对制作或保存机构、形成日期和记录来源；不是档案原件。'}
def clean(v):return html.unescape(re.sub('<[^>]+>','',v)).strip()
rows=[];raw={}
for n in range(1,37):
 id=f'deu-m{n:02}';original=n in [17,30,31,32,36]
 if original:
  path=dest/(id+'.png');b=path.read_bytes();credit='世界大百科 · 原创教学示意';url={17:'https://www.neuschwanstein.de/englisch/palace/history.htm',36:'https://encyclopedia.ushmm.org/content/en/article/introduction-to-the-holocaust'}.get(n,'https://www.bpb.de/kurz-knapp/lexika/kosmos-weltalmanach/65657/deutschland/');license='CC BY 4.0';lu='https://creativecommons.org/licenses/by/4.0/';date='2026-11-11';download=url
 else:
  chosen=json.loads((src/f'{n:02}.chosen.json').read_text());raw[id]=chosen;a=chosen['record']['imageinfo'][0];meta=a['extmetadata'];b=(src/f'{n:02}.img').read_bytes();path=dest/(id+('.png' if b.startswith(b'\x89PNG') else '.jpg'));path.write_bytes(b);credit=clean(meta.get('Artist',{}).get('value','')) or chosen['record']['title'][5:];url=a['descriptionurl'];license=clean(meta['LicenseShortName']['value']);lu=meta.get('LicenseUrl',{}).get('value','') or (url+'#Licensing' if license=='Attribution' else 'https://creativecommons.org/publicdomain/mark/1.0/');date='2008-07-15' if n==10 else clean(meta.get('DateTimeOriginal',{}).get('value','')) or '来源未注明';download=chosen['downloadUrl'];assert not meta.get('Restrictions',{}).get('value'),(id,'restrictions')
 w,h=image_size(b)
 rows.append(dict(id=id,asset=str(path.relative_to(ROOT)),caption=captions[n],alt=captions[n],credit=credit,sourceUrl=url,license=license,licenseUrl=lu.replace('http://','https://'),kind='diagram' if original else 'archive' if n in [29,34,35] else 'realPhoto',width=w,height=h,sha256=hashlib.sha256(b).hexdigest(),downloadUrl=download,checkedAt='2026-11-11',captureDate=date,processing='原创教学卡；非历史档案或现场拍摄，来源链接用于事实核对。' if original else '保留来源画面；采用作品页提供的缩略图尺寸。',focalPoint=dict(x=.5,y=.5)))
(ROOT/'tool/content/editorial/deu_assets.json').write_text(json.dumps(dict(media=rows),ensure_ascii=False,indent=2)+'\n');(ROOT/'tool/content/sources/deu_commons.json').write_text(json.dumps(raw,ensure_ascii=False,indent=2)+'\n')
print('Germany:',len(rows),'media,',len(raw),'Commons records')
