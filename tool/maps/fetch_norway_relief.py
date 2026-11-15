"""Fetch NASA GIBS Blue Marble inputs; public imagery, per-region bounds."""
import json,ssl,concurrent.futures
from pathlib import Path
from urllib.request import build_opener,ProxyHandler,HTTPSHandler
from urllib.parse import urlencode
out=Path('tool/maps/sources/norway')
regions={'mainland':([2,56,35,73],1800,1600),'svalbard':([8,73,35,82],1600,1000),'jan-mayen':([-9.5,70.5,-7.5,71.5],1000,800)}
def work(row):
 name,(bounds,w,h)=row
 params=dict(SERVICE='WMS',REQUEST='GetMap',VERSION='1.1.1',LAYERS='BlueMarble_ShadedRelief_Bathymetry',STYLES='',FORMAT='image/jpeg',SRS='EPSG:4326',BBOX=','.join(map(str,bounds)),WIDTH=w,HEIGHT=h)
 url='https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi?'+urlencode(params)
 op=build_opener(ProxyHandler({'https':'http://127.0.0.1:7897'}),HTTPSHandler(context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')))
 data=op.open(url,timeout=90).read();assert data[:2]==b'\xff\xd8';(out/(name+'-relief.jpg')).write_bytes(data);(out/(name+'-relief-source.json')).write_text(json.dumps(dict(url=url,bounds=bounds,layer=params['LAYERS']),indent=2));print(name,len(data),flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as p:list(p.map(work,regions.items()))
