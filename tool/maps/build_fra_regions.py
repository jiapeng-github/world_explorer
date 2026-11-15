#!/usr/bin/env python3
"""France teaching atlas. Lambert-93 (GRS80) for Europe, local equirectangular overseas.
Natural Earth 10m map units, river lines; NASA raster resampled independently.
Coordinates kilometres, screen y south. No cross-inset distance comparison.
"""
import json,math,sys,tempfile
from pathlib import Path
from build_usa_regions import read,feature,project_polygons,bounds,extent,source
from build_detail import ROOT,polygons,shapefile_rings
from build_china_rivers import polylines
import build_gbr_regions as raster
class Projection:
 def __init__(self,lon,lat,europe=False):self.lon,self.lat,self.europe=lon,lat,europe
 def project(self,lon,lat):
  if not self.europe:return [6371.0088*math.radians(lon-self.lon)*math.cos(math.radians(self.lat)),6371.0088*math.radians(self.lat-lat)]
  p=math.radians(lat);e=.0818191910428158
  L=math.log(math.tan(math.pi/4+p/2)*((1-e*math.sin(p))/(1+e*math.sin(p)))**(e/2));r=11754.255426096*math.exp(-.725607765053267*L);a=.725607765053267*math.radians(lon-3)
  return [700+r*math.sin(a),r*math.cos(a)-12655.612049876]
 def inverse(self,x,y):
  if not self.europe:return self.lon+math.degrees(x/(6371.0088*math.cos(math.radians(self.lat)))),self.lat-math.degrees(y/6371.0088)
  r=math.hypot(x-700,y+12655.612049876);L=-math.log(r/11754.255426096)/.725607765053267;e=.0818191910428158;p=2*math.atan(math.exp(L))-math.pi/2
  for _ in range(8):p=2*math.atan(math.exp(L)*((1+e*math.sin(p))/(1-e*math.sin(p)))**(e/2))-math.pi/2
  return 3+math.degrees(math.atan2(x-700,y+12655.612049876)/.725607765053267),math.degrees(p)
REGIONS={'metropole':('FXX','法国欧洲部分',3,46.5),'guadeloupe':('GLP','瓜德罗普',-61.5,16.2),'martinique':('MTQ','马提尼克',-61,14.65),'guiana':('GUF','法属圭亚那',-53.2,4),'reunion':('REU','留尼汪',55.5,-21.1),'mayotte':('MYT','马约特',45.15,-12.8)}
def build(units,rivers,relief):
 rows=list(read(units,'ne_10m_admin_0_map_units',shapefile_rings));rs=list(read(rivers,'ne_10m_rivers_lake_centerlines',polylines));out={}
 for key,(code,name,lon,lat) in REGIONS.items():
  p=Projection(lon,lat,key=='metropole');features=[]
  row,rings=next((r,s) for r,s in rows if r['GU_A3']==code);ps=polygons(rings)
  if key=='metropole':
   corsica=[q for q in ps if any(8.5<x<9.7 and 41.3<y<43.1 for x,y in q[0])];main=[q for q in ps if q not in corsica]
   for slug,title,poly in [('metropole','法国欧洲大陆部分',main),('corsica','科西嘉',corsica)]:features.append(feature('fra-part-'+slug,title,'part','MultiPolygon',project_polygons(poly,p)))
   for r,s in rows:
    if r['GU_A3'] in ['ESP','ITA','DEU','BEL','CHE','LUX','AND','MCO','ENG']:
     poly=[q for q in polygons(s) if any(-7<x<13 and 40<y<53 for x,y in q[0])]
     if poly:features.append(feature('fra-context-'+r['GU_A3'].lower(),{'ESP':'西班牙','ITA':'意大利','DEU':'德国','BEL':'比利时','CHE':'瑞士','LUX':'卢森堡','AND':'安道尔','MCO':'摩纳哥','ENG':'英国'}.get(r['GU_A3'],r['ADMIN']),'context','MultiPolygon',project_polygons(poly,p)))
   for qid,slug,title in [('Q1471','seine','塞纳河'),('Q1469','loire','卢瓦尔河'),('Q602','rhone','罗讷河')]:
    lines=[line for r,parts in rs if r.get('wikidataid')==qid for line in parts];assert lines,title
    features.append(feature('fra-feature-'+slug,title,'river','MultiLineString',[[p.project(x,y) for x,y in line] for line in lines]))
  else:features.append(feature('fra-part-'+key,name,'part','MultiPolygon',project_polygons(ps,p)))
  box=extent(bounds([v for f in features if f['properties']['kind']=='part' for poly in f['geometry']['coordinates'] for ring in poly for v in ring]),35 if key=='metropole' else 8,35 if key=='metropole' else 8)
  data={'bounds':box,'reliefBounds':extent(box,20,20),'features':features,'projection':{'type':'EPSG:2154' if key=='metropole' else 'local-equirectangular','center':[lon,lat]}}
  raster.P=p
  with tempfile.TemporaryDirectory() as tmp:
   raster.OUT=Path(tmp);raster.render(relief,data);(Path(tmp)/'gbr-relief.jpg').replace(ROOT/f'assets/atlas/fra-{key}-relief.jpg')
  out[key]=data
 # Regenerate UK raster was never intended to mutate: caller preserves it.
 result={'schemaVersion':1,'regions':out,'sources':[source(units,'Natural Earth 10m Map Units','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/'),source(rivers,'Natural Earth 10m Rivers','https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/')],'scopeNote':'五个海外省和地区不等于全部法国海外领土。马约特由法国实际管辖，科摩罗提出主权主张。'}
 (ROOT/'assets/atlas/fra-regions.json').write_text(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n')
if __name__=='__main__':
 build(Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3]))
