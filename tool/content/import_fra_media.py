"""Import reviewed Commons downloads. Input includes chosen.json original metadata.
Run after render_fra_cards.swift. Reproduction retains exact source URLs and hashes.
"""
import json,html,re,hashlib,sys,shutil
from pathlib import Path
from fetch_china_media import image_size
ROOT=Path(__file__).resolve().parents[2];src=Path(sys.argv[1]);dest=ROOT/'assets/atlas'
captions={1:'巴黎塞纳河与埃菲尔铁塔，白天的河岸与船只。',2:'巴黎塞纳河与新桥，河流经过两岸建筑。',3:'巴黎塞纳河岸 André-Gorz 步道，2015年2月。',4:'埃菲尔铁塔的全貌。',5:'埃菲尔铁塔南支脚的杆件近景。',6:'Louis-Émile Durandelle：1888年铁塔施工阶段照片。',7:'圣米歇尔山建筑群的当代外观；不是实时潮位图。',8:'圣米歇尔海湾露出的潮滩与行人；与全景视角不同。',9:'圣米歇尔山与前方水道，2011年7月；与另一张全景不是同一视角。',10:'从蒙坦维尔看冰海冰川；宽幅山谷全景。',11:'冰海冰川与石屑覆盖的谷地，2018年。',12:'约1900年的冰海冰川历史影像；视角不同，不作定量前后对照。',13:'卡马格瓦卡雷斯潟湖水面与岸边。',14:'卡马格的火烈鸟，长腿立在浅水中。',15:'卡马格 Pont de Gau 鸟类园，火烈鸟将头伸入水中觅食，2017年。',16:'富尔奈斯火山口与凝固岩面。',17:'留尼汪富尔奈斯火山凝固熔岩表面的纹理；作品记录为2004年熔岩流。',18:'从2007年熔岩流区域看2026年2月熔岩流，摄于2026年3月9日；不是实时活动信息。',19:'从科尔特看周围山地，2024年9月27日。',20:'科尔特周边山地的另一视角，2024年9月27日。',21:'卢浮宫庭院及玻璃金字塔；外部建筑景观。',22:'卢浮宫方形沙龙的天花装饰；不是展品说明牌。',23:'里昂圣安托万市场的摊位；商品信息以各自标签为准。',24:'原创练习标签：名称苹果、单位千克、产地法国；非实拍商品标签。',25:'马赛老港与周围城市全景。',26:'马赛老港岸边公共空间与水面。',27:'从昂布瓦斯看卢瓦尔河、桥与聚落。',28:'昂布瓦斯城堡及塔楼建筑。',29:'斯特拉斯堡小法兰西街区，2011年。',30:'原创名称卡：Strasbourg法语、Straßburg德语、斯特拉斯堡中文；不是现场路牌。',31:'切开的法棍面包，切面可见孔洞。',32:'Rouzaire Camembert 奶酪包装；原料须查产品资料，不能凭颜色猜测。',33:'克洛德·莫奈《印象·日出》，1872年，公版画作的数字复制；不是现场摄影。',34:'法国 Villemanoche 的2023年音乐节演出；一场具体活动。',35:'Le Barbier：1789年《人权和公民权宣言》相关画作，卡纳瓦雷博物馆藏；不是1944年法规。',36:'原创时间关系卡：1944法规、1945选举；非档案影像。'}
def clean(v):return html.unescape(re.sub('<[^>]+>','',v)).strip()
rows=[];raw={}
for n in range(1,37):
 k=f'M{n:02}';id='fra-'+k.lower();original=n in [24,30,36]
 if original:
  path=dest/(id+'.png');b=path.read_bytes();credit='世界大百科 · 原创教学示意';url='https://www.visitstrasbourg.fr/de/' if n==30 else 'https://www.archives-nationales.culture.gouv.fr/evenements/ordonnance-instituant-le-droit-de-vote-des-femmes-1944' if n==36 else 'https://www.economie.gouv.fr/dgccrf/les-fiches-pratiques/etiquetage-des-denrees-alimentaires-les-regles-connaitre';license='CC BY 4.0';lu='https://creativecommons.org/licenses/by/4.0/';date='2026-11-10';download=url
 else:
  chosen=json.loads((src/(k+'.chosen.json')).read_text());raw[id]=chosen;a=chosen['record']['imageinfo'][0];meta=a['extmetadata'];b=(src/(k+'.img')).read_bytes();path=dest/(id+('.png' if b.startswith(b'\x89PNG') else '.jpg'));path.write_bytes(b);credit=clean(meta.get('Artist',{}).get('value','')) or chosen['record']['title'][5:];url=a['descriptionurl'];license=clean(meta['LicenseShortName']['value']);lu=meta.get('LicenseUrl',{}).get('value','') or 'https://creativecommons.org/publicdomain/mark/1.0/';date=clean(meta.get('DateTimeOriginal',{}).get('value','')) or '来源未注明';download=chosen['downloadUrl'];assert not meta.get('Restrictions',{}).get('value'),(id,'restrictions')
 w,h=image_size(b)
 rows.append(dict(id=id,asset=str(path.relative_to(ROOT)),caption=captions[n],alt=captions[n],credit=credit,sourceUrl=url,license=license,licenseUrl=lu.replace("http://","https://"),kind='diagram' if original else 'archive' if n in [6,12,33,35] else 'realPhoto',width=w,height=h,sha256=hashlib.sha256(b).hexdigest(),downloadUrl=download,checkedAt='2026-11-10',captureDate=date,processing='原创文字图解，来源链接为事实依据；制作脚本 tool/content/render_fra_cards.swift' if original else '保留来源画面；采用作品页提供的缩略图尺寸。',focalPoint=dict(x=.5,y=.5)))
(ROOT/'tool/content/editorial/fra_assets.json').write_text(json.dumps(dict(media=rows),ensure_ascii=False,indent=2)+'\n')
(ROOT/'tool/content/sources/fra_commons.json').write_text(json.dumps(raw,ensure_ascii=False,indent=2)+'\n')
print('Imported',len(rows),'assets')
