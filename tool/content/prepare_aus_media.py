"""Fetch explicitly selected Commons assets; metadata remains available for review."""
import json,ssl,time,html,re,hashlib
from pathlib import Path
from urllib.request import build_opener,ProxyHandler,HTTPSHandler,Request
from urllib.parse import urlencode
from fetch_china_media import image_size
ROOT=Path(__file__).resolve().parents[2];DIR=ROOT/'tool/content/sources/aus_media_candidates';OUT=ROOT/'tool/content/drafts/aus_assets.json'
op=build_opener(ProxyHandler({'https':'http://127.0.0.1:7897'}),HTTPSHandler(context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')))
def get(u):return op.open(Request(u,headers={'User-Agent':'WorldExplorer educational atlas attribution review'}),timeout=35).read()
def clean(v):return html.unescape(re.sub('<[^>]*>','',v)).strip()
selections=[('sydney',None,'Sydney Opera House and Harbour Bridge Dusk (2) 2019-06-21.jpg','悉尼歌剧院与海港大桥，黄昏景观。'),('canberra',2,0,'堪培拉伯利·格里芬湖与桥梁。'),('melbourne',3,1,'墨尔本的电车与城市街道，2008年。'),('reef',4,0,'大堡礁 Flynn Reef 的珊瑚群落。'),('daintree',5,1,'丹特里雨林中的植被景观。'),('kakadu',6,2,'卡卡杜国家公园观景区域。'),('murray',8,3,'亚拉旺加附近的墨累河景观。'),('apostles',9,0,'十二使徒岩海岸，2019年。'),('perth',10,0,'从国王公园看珀斯与天鹅河。'),('joey',14,2,'袋鼠与育儿袋中露头的幼崽。'),('platypus',15,0,'Scottsdale 拍摄的鸭嘴兽。'),('koala',16,0,'抱着桉树的考拉。'),('ferry',17,1,'悉尼的 Balmoral 渡轮。'),('market',18,0,'墨尔本维多利亚女王市场，2019年。'),('wheat',19,1,'西澳大利亚 Brookton 的麦田。')]
selections += [('cradle',None,'Cradle Mountain Behind Dove Lake.jpg','塔斯马尼亚摇篮山与鸽湖。'),('kangaroo-island',None,'Remarkable Rocks, Kangaroo Island.jpg','袋鼠岛 Remarkable Rocks 的岩石景观。')]
rows=[]
for slug,query,index,caption in selections:
 cache=DIR/(slug+'-selected.json')
 try:
  if cache.exists():r=json.loads(cache.read_text())
  elif query:
   rs=sorted(json.loads((DIR/f'{query:02}.json').read_text())['query']['pages'].values(),key=lambda r:r.get('index',999));r=rs[index];cache.write_text(json.dumps(r,ensure_ascii=False,indent=2))
  else:
   u='https://commons.wikimedia.org/w/api.php?'+urlencode(dict(action='query',format='json',titles='File:'+index,prop='imageinfo',iiprop='url|extmetadata|size',iiurlwidth=1200));r=next(v for v in json.loads(get(u))['query']['pages'].values() if v.get('imageinfo'));cache.write_text(json.dumps(r,ensure_ascii=False,indent=2))
  a=r['imageinfo'][0];m=a['extmetadata'];license=clean(m.get('LicenseShortName',{}).get('value',''));assert license and not m.get('Restrictions',{}).get('value'),license
  file=ROOT/f'assets/atlas/aus-{slug}.jpg'
  if not file.exists():file.write_bytes(get(a.get('thumburl') or a['url']));time.sleep(3)
  b=file.read_bytes();w,h=image_size(b)
  rows.append(dict(id='aus-'+slug,asset=str(file.relative_to(ROOT)),caption=caption,alt=caption,credit=clean(m.get('Artist',{}).get('value','')) or r['title'],sourceUrl=a['descriptionurl'],license=license,licenseUrl=(m.get('LicenseUrl',{}).get('value') or 'https://creativecommons.org/publicdomain/mark/1.0/').replace('http://','https://'),kind='realPhoto',width=w,height=h,sha256=hashlib.sha256(b).hexdigest(),captureDate=clean(m.get('DateTimeOriginal',{}).get('value','')) or '未注明',checkedAt='2026-11-11',downloadUrl=a.get('thumburl') or a['url'],processing='来源缩略图，未改变内容'))
  print(slug,'OK',flush=True)
 except Exception as e:print(slug,str(e),flush=True)
 OUT.write_text(json.dumps(dict(media=rows),ensure_ascii=False,indent=2)+'\n')
