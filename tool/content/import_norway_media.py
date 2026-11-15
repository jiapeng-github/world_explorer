"""Import reviewed Commons files and explicitly original teaching cards."""
import json,html,re,hashlib
from pathlib import Path
from fetch_china_media import image_size
ROOT=Path(__file__).resolve().parents[2];src=Path('/private/tmp/norway-media');dest=ROOT/'assets/atlas'
captions={1:'从鹰之路观景方向看盖朗厄尔峡湾，2013年6月；海水伸入群山之间。',2:'从Flydalsjuvet方向看盖朗厄尔聚落与峡湾，2013年6月。',3:'卑尔根布吕根临港木建筑；记录作品页所示拍摄时刻。',4:'布吕根木建筑之间的通道，可见木板、立柱与接缝。',5:'奥斯陆歌剧院与公共空间；现代建筑与行人在同一画面中。',6:'奥斯陆Jernbanetorget的12路电车；不是当前班次信息。',7:'纳柔依峡湾的山坡与海湾；阴云天气只是拍摄时刻的情况。',8:'纳柔依峡湾水面与两侧山地的另一视角。',9:'从北侧看乌尔内斯木教堂；不是博尔贡木教堂。',10:'乌尔内斯木教堂北墙入口的雕刻；形状与含义应分开观察。',11:'雷讷附近的Hammarskaftet山与聚落，2015年9月。',12:'罗弗敦晾鱼架上的风干鱼，2009年；不代表所有鱼的加工方式。',13:'从Fjellheisen方向看特罗姆瑟城市与水面。',14:'特罗姆瑟桥上的午夜太阳，2025年7月7日00:39；作品页说明为当地太阳午夜附近。',15:'阿尔塔岩画材料；具体位置与拍摄信息见作品页。',16:'阿尔塔岩画，2012年7月17日；画面中的红色显影不用于推断原始色彩。',17:'卡拉绍克的萨米议会建筑外观，认识当代公共生活。',18:'卡拉绍克的道路与社区环境；一条道路不能代表所有萨米人的生活。',19:'埃兹沃尔历史建筑外观；不是1814年当时的照片。',20:'埃兹沃尔建筑屋顶与立面细节；维修年代需另查记录。',21:'2022年的朗伊尔城景观，周围积雪不代表全年状况。',22:'原创资料摘记：朗伊尔城位于斯瓦尔巴，有城镇生活及科学文化活动；不是设施实拍。',23:'尼加尔冰川远景；它是约斯特达尔冰川的一条冰舌，具体拍摄日期见来源。',24:'原创冰川比较条件卡：核对具体冰舌、日期、季节与机位；不是冰川前后对比照片。',25:'挪威开放式面包与配料，2007年；是食物组合实例，不是全国统一便当。',26:'罗弗敦Å村的晾鱼架，2015年6月8日；干制不等于盐渍。',27:'原创虚构食品标签：名称面包、计量克、产地挪威；不是真实商品标签。',28:'原创术语卡：Bokmål和Nynorsk是挪威语的两种书面规范。',29:'特隆赫姆的儿童宪法日游行，2009年5月17日；不标注个人身份。',30:'原创故事版本资料卡：讲述者、译者与出版信息帮助理解来源；不是历史书页。',31:'原创事实摘记：1814年宪法历史与1905年联合解体，两个年份对应不同事件。',32:'原创事实摘记：1940年纳粹德国入侵，经历占领、迫害与抵抗，1945年解放。',33:'斯瓦尔巴以北浮冰区域的北极熊；海冰是动物生活空间，不能据一张图判断长期趋势。',34:'特罗姆瑟地区的极光照片；曝光与处理可能影响色彩，不代表实时观测。',35:'原创过程卡：冰川运动与侵蚀、谷地变化、冰退后地形显露；不是历史实拍。',36:'原创布吕根证据卡：火灾与修复记录说明旧样式不等于每块木材同样古老。',37:'原创公共空间示意：缓坡、台阶与站牌；非现场照片或工程尺寸标准。'}
originals={22,24,27,28,30,31,32,35,36,37};replacements={3:103,4:104,5:105,14:114,34:134}
# Additional selected replacements, if reviewed and explicitly recorded.
selection=ROOT/'tool/content/sources/norway_selection.json'
if selection.exists():replacements.update({int(k):v for k,v in json.loads(selection.read_text()).items()})
urls={22:'https://npolar.no/en/maps/',24:'https://www.nve.no/hydrology/glaciers/glacier-monitoring/nigardsbreen/',27:'https://www.nfk.no/_f/p1/i1bd327e2-4d6b-4d3e-a6ef-b5e44464f9d5/matglede-i-boks.pdf',28:'https://www.regjeringen.no/no/om-nettstedet/innholdsstrategi/ti-bud-for-godt-innhold-pa-regjeringen.no/skriveregler-for-regjeringen.no/skriftsprak/id2551245/',30:'https://collection.nationalmuseum.se/en/collection/item/36656/',31:'https://www.kongehuset.no/historie/grunnlov-og-union-1814-1905',32:'https://www.stortinget.no/en/In-English/About-the-Storting/historical-highlights/the-storting-during-world-war-ii/',35:'https://whc.unesco.org/en/list/1195/',36:'https://whc.unesco.org/en/list/59/',37:'https://ruter.no/en/plan-journey/timetables-and-route-maps'}
def clean(v):return html.unescape(re.sub('<[^>]+>','',v)).strip()
rows=[];raw={}
for n in range(1,38):
 id=f'norway-m{n:02}';original=n in originals
 if original:
  path=dest/(id+'.png');b=path.read_bytes();credit='世界大百科 · 原创教学示意';url=urls[n];license='CC BY 4.0';lu='https://creativecommons.org/licenses/by/4.0/';date='2026-11-12';download=url
 else:
  k=replacements.get(n,n);chosen=json.loads((src/f'm{k:02}.json').read_text());raw[id]=chosen;a=chosen['record']['imageinfo'][0];meta=a['extmetadata'];b=(src/f'm{k:02}.img').read_bytes();path=dest/(id+('.png' if b.startswith(b'\x89PNG') else '.jpg'));path.write_bytes(b);credit=clean(meta.get('Artist',{}).get('value','')) or chosen['record']['title'][5:];url=a['descriptionurl'];license=clean(meta['LicenseShortName']['value']);lu=meta.get('LicenseUrl',{}).get('value','') or ('https://creativecommons.org/publicdomain/mark/1.0/');date=clean(meta.get('DateTimeOriginal',{}).get('value','')) or '来源未注明';download=chosen['downloadUrl'];assert not meta.get('Restrictions',{}).get('value'),(id,'restrictions')
  if n==34:date='作品页元数据日期：'+date+'；不据此推断实际观测时刻。'
 w,h=image_size(b)
 rows.append(dict(id=id,asset=str(path.relative_to(ROOT)),caption=captions[n],alt=captions[n],credit=credit,sourceUrl=url,license=license,licenseUrl=lu.replace('http://','https://'),kind='diagram' if original else 'realPhoto',width=w,height=h,sha256=hashlib.sha256(b).hexdigest(),downloadUrl=download,checkedAt='2026-11-12',captureDate=date,processing='原创教学卡；非档案或现场摄影。' if original else '保留原画面；采用来源提供的缩略尺寸，页面内可查看完整图。',focalPoint=dict(x=.5,y=.5)))
(ROOT/'tool/content/editorial/norway_assets.json').write_text(json.dumps(dict(media=rows),ensure_ascii=False,indent=2)+'\n');(ROOT/'tool/content/sources/norway_commons.json').write_text(json.dumps(raw,ensure_ascii=False,indent=2)+'\n');print('Norway:',len(rows),'media,',len(raw),'Commons records')
