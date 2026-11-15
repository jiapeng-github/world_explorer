"""Download Commons candidates and metadata for review; no catalog mutation."""
import json,ssl,time,concurrent.futures
from pathlib import Path
from urllib.request import build_opener,ProxyHandler,HTTPSHandler,Request
from urllib.parse import urlencode
OUT=Path('/private/tmp/norway-media');OUT.mkdir(exist_ok=True)
queries={1:'Geirangerfjord landscape',2:'Geiranger village fjord',3:'Bryggen Bergen waterfront',4:'Bryggen wooden alley',5:'Oslo Opera House waterfront',6:'Oslo tram street',7:'Naeroyfjord landscape',8:'Nærøyfjord fjord',9:'Urnes stave church exterior',10:'Urnes stave church carving portal',11:'Reine Lofoten landscape',12:'Lofoten stockfish racks',13:'Tromso city bridge',14:'Tromso midnight sun',15:'Alta rock carvings landscape',16:'Alta rock carvings',17:'Sami Parliament Karasjok building',18:'Karasjok town',19:'Eidsvoll building',20:'Eidsvoll house exterior',21:'Longyearbyen town',23:'Nigardsbreen glacier',25:'Norwegian matpakke bread',26:'Lofoten stockfish drying',29:'Norway constitution day children parade',33:'Svalbard polar bear sea ice',34:'Tromso aurora borealis'}
def opener():return build_opener(ProxyHandler({'https':'http://127.0.0.1:7897'}),HTTPSHandler(context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')))
def work(row):
 n,q=row;p=OUT/f'{n:02}.json'
 if p.exists():return
 u='https://commons.wikimedia.org/w/api.php?'+urlencode(dict(action='query',format='json',generator='search',gsrsearch=q+' filetype:bitmap',gsrnamespace=6,gsrlimit=5,prop='imageinfo',iiprop='url|extmetadata|size',iiurlwidth=1200))
 for attempt in range(3):
  try:
   data=json.loads(opener().open(Request(u,headers={'User-Agent':'WorldExplorer educational atlas'}),timeout=40).read());p.write_text(json.dumps(data,ensure_ascii=False,indent=2));print(n,len(data.get('query',{}).get('pages',{})),flush=True);break
  except Exception as e:print(n,type(e).__name__,flush=True);time.sleep(3)
 time.sleep(2)
if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:list(pool.map(work,queries.items()))
