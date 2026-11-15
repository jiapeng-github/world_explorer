"""Fetch Commons candidates for manual review, preserving source metadata."""
import json,ssl,time,concurrent.futures
from pathlib import Path
from urllib.request import build_opener,ProxyHandler,HTTPSHandler,Request
from urllib.parse import urlencode
OUT=Path('/private/tmp/kenya-media');OUT.mkdir(exist_ok=True)
queries=['Mount Kenya Batian Nelion landscape','Mount Kenya alpine vegetation','Nairobi skyline KICC','Nairobi matatu street','Lamu waterfront','Lamu carved door','Mombasa port containers','Mombasa harbour','Amboseli elephant swamp','Amboseli wetland','Lake Nakuru landscape','Lake Nakuru shore birds','Lake Naivasha landscape','Lake Naivasha shore','Lake Turkana landscape','Lake Turkana shore','Kisumu city','Kisumu Lake Victoria','Kakamega forest','Kakamega forest trees','Watamu coast','Mida creek mangrove','Nairobi National Museum exterior','Nairobi National Museum hall','Kenya maize','Ugali Kenya','Kenya tea leaves','Isukuti dance','Lamu door detail']
def work(row):
 n,q=row;p=OUT/f'{n:02}.json'
 if p.exists():return
 op=build_opener(ProxyHandler({'https':'http://127.0.0.1:7897'}),HTTPSHandler(context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')))
 u='https://commons.wikimedia.org/w/api.php?'+urlencode(dict(action='query',format='json',generator='search',gsrsearch=q+' filetype:bitmap',gsrnamespace=6,gsrlimit=5,prop='imageinfo',iiprop='url|extmetadata|size',iiurlwidth=1200))
 try:
  data=json.loads(op.open(Request(u,headers={'User-Agent':'WorldExplorer educational atlas'}),timeout=45).read());p.write_text(json.dumps(data,ensure_ascii=False,indent=2));print(n,q,len(data.get('query',{}).get('pages',{})),flush=True)
 except Exception as e:print(n,e,flush=True)
 time.sleep(8)
with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:list(pool.map(work,enumerate(queries,1)))
