"""Fetch selected CC/PD image candidates; metadata retained for review."""
import json,time,concurrent.futures
from urllib.request import Request
from fetch_norway_media import opener,OUT,work
choices={1:(1,27441401),2:(1,29777506),3:(3,75476054),4:(4,127793132),6:(6,85584101),7:(7,1095223),8:(8,65980511),9:(9,50600690),10:(10,50600625),13:(13,108470738),14:(14,169533345),16:(16,24034497),18:(18,2123364),19:(19,775138),20:(19,35599442),21:(21,121624754),23:(23,106093711)}
def download(row):
 n,(q,id)=row
 if (OUT/f'm{n:02}.img').exists():return
 record=json.loads((OUT/f'{q:02}.json').read_text())['query']['pages'][str(id)];ii=record['imageinfo'][0];u=ii.get('thumburl',ii['url'])
 for attempt in range(3):
  try:
   b=opener().open(Request(u,headers={'User-Agent':'WorldExplorer educational atlas'}),timeout=60).read();(OUT/f'm{n:02}.img').write_bytes(b);(OUT/f'm{n:02}.json').write_text(json.dumps(dict(record=record,downloadUrl=u),ensure_ascii=False,indent=2));print('Downloaded',n,len(b),flush=True);return
  except Exception as e:print(n,repr(e),flush=True);time.sleep(3)
if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(download,choices.items()))
 for n,q in [(105,'Oslo Opera House'),(111,'Reine Lofoten'),(112,'Lofoten stockfish'),(115,'Alta museum rock carvings'),(117,'Sametinget Karasjok'),(125,'Matpakke'),(129,'17 mai barnetog'),(133,'Svalbard polar bear ice'),(134,'Tromso aurora')]:work((n,q))
