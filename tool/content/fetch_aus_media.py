"""Discover Australia Commons media; preserves metadata for manual depiction review.
Never publishes automatically. Usage: python3 tool/content/fetch_aus_media.py
"""
import json,ssl,time
from pathlib import Path
from urllib.request import build_opener,ProxyHandler,HTTPSHandler,Request
from urllib.parse import urlencode
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'tool/content/sources/aus_media_candidates';OUT.mkdir(exist_ok=True)
queries=['Sydney Harbour Opera House daylight','Canberra Lake Burley Griffin','Melbourne tram street','Great Barrier Reef coral underwater','Daintree rainforest','Kakadu wetland','Uluru landscape','Murray River Australia','Twelve Apostles Australia coast','Perth Swan River','Kangaroo Island kangaroo','Cradle Mountain Tasmania','coral polyp','kangaroo joey pouch','platypus Australia','koala eucalyptus','Sydney ferry','Melbourne Queen Victoria Market','Australian wheat field','Australia Federation 1901']
opener=build_opener(ProxyHandler({'https':'http://127.0.0.1:7897'}),HTTPSHandler(context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')))
for i,q in enumerate(queries,1):
 path=OUT/f'{i:02}.json'
 if path.exists():continue
 url='https://commons.wikimedia.org/w/api.php?'+urlencode(dict(action='query',format='json',generator='search',gsrsearch=q+' filetype:bitmap',gsrnamespace=6,gsrlimit=5,prop='imageinfo',iiprop='url|extmetadata|size',iiurlwidth=1200))
 try:
  data=json.loads(opener.open(Request(url,headers={'User-Agent':'WorldExplorer educational atlas media review'}),timeout=30).read());path.write_text(json.dumps(data,ensure_ascii=False,indent=2));print(i,q,len(data.get('query',{}).get('pages',{})),flush=True)
 except Exception as e:print(i,str(e),flush=True)
 time.sleep(2)
