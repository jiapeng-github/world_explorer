#!/usr/bin/env python3
"""Build the UK teaching atlas from pinned Natural Earth sources.

Inputs: 10m admin_0_map_units, rivers_lake_centerlines, lakes ZIPs; optional
WGS84 NASA Blue Marble BMP. Spherical LCC parameters are shared with Dart.
All output coordinates are km, y south. Never include Ireland in UK parts.
"""
import argparse,json,math,struct,subprocess,tempfile
from pathlib import Path
from build_usa_regions import read,feature,project_polygons,bounds,extent,source,Bmp,NASA
from build_china_rivers import polylines
from build_detail import ROOT,polygons,shapefile_rings
OUT=ROOT/'assets/atlas'
class Projection:
 def __init__(self):
  r=math.radians;p1,p2=r(49),r(61)
  self.n=math.log(math.cos(p1)/math.cos(p2))/math.log(math.tan(math.pi/4+p2/2)/math.tan(math.pi/4+p1/2))
  self.f=math.cos(p1)*math.tan(math.pi/4+p1/2)**self.n/self.n
  self.r0=self.rho(55)
 def rho(self,lat):return 6371.0088*self.f/math.tan(math.pi/4+math.radians(lat)/2)**self.n
 def project(self,lon,lat):
  theta=self.n*math.radians(lon+3);rho=self.rho(lat)
  return [rho*math.sin(theta),rho*math.cos(theta)-self.r0]
 def inverse(self,x,y):
  rho=math.hypot(x,y+self.r0)
  return -3+math.degrees(math.atan2(x,y+self.r0)/self.n),math.degrees(2*math.atan((6371.0088*self.f/rho)**(1/self.n))-math.pi/2)
P=Projection()
PARTS={'ENG':('england','英格兰','England'),'SCT':('scotland','苏格兰','Scotland'),'WLS':('wales','威尔士','Wales'),'NIR':('northern-ireland','北爱尔兰','Northern Ireland')}
def assemble(units,rivers,lakes):
 features=[];mainland={}
 for row,rings in read(units,'ne_10m_admin_0_map_units',shapefile_rings):
  code=row.get('GU_A3');ps=polygons(rings)
  if code in PARTS:
   key,zh,en=PARTS[code];shapes=project_polygons(ps,P)
   features.append(feature('gbr-part-'+key,zh,'part','MultiPolygon',shapes,english=en,code=code,aliases=[en,zh]))
   mainland[code]=max(shapes,key=lambda poly:len(poly[0]))
  elif row.get('ADMIN') in ['Ireland','France','Belgium','Netherlands','Germany','Denmark','Norway','Isle of Man','Jersey','Guernsey']:
   ps=[poly for poly in ps if any(-13<lon<10 and 47<lat<63 for lon,lat in poly[0])]
   if not ps:continue
   zh={'Ireland':'爱尔兰','France':'法国','Belgium':'比利时','Netherlands':'荷兰','Germany':'德国','Denmark':'丹麦','Norway':'挪威','Isle of Man':'马恩岛','Jersey':'泽西岛','Guernsey':'根西岛'}[row['ADMIN']]
   sh=project_polygons(ps,P)
   features.append(feature('gbr-context-'+code.lower(),zh,'context','MultiPolygon',sh,english=row['ADMIN'],aliases=[zh]))
   if code=='IRL':mainland[code]=max(sh,key=lambda poly:len(poly[0]))
 assert sum(f['properties']['kind']=='part' for f in features)==4
 features += [feature('gbr-island-great-britain','大不列颠岛','island','MultiPolygon',[mainland[k] for k in ['ENG','WLS','SCT']],english='Great Britain',aliases=['Britain','大不列颠']),feature('gbr-island-ireland','爱尔兰岛','island','MultiPolygon',[mainland[k] for k in ['IRL','NIR']],english='Island of Ireland',aliases=['Ireland island'])]
 for qid,key,zh in [('Q19686','thames','泰晤士河'),('Q19682','severn','塞文河')]:
  lines=[line for row,parts in read(rivers,'ne_10m_rivers_lake_centerlines',polylines) if row.get('wikidataid')==qid for line in parts]
  assert len(lines)>0
  features.append(feature('gbr-feature-'+key,zh,'river','MultiLineString',[[[round(x,3),round(y,3)] for lon,lat in line for x,y in [P.project(lon,lat)]] for line in lines],english=key.title()))
 for row,rings in read(lakes,'ne_10m_lakes',shapefile_rings):
  if row.get('wikidataid')=='Q49650':features.append(feature('gbr-feature-loch-ness','尼斯湖','lake','MultiPolygon',project_polygons(polygons(rings),P),english='Loch Ness'))
 assert sum(f['properties']['kind']=='lake' for f in features)==1
 boxes={}
 for f in features:
  if f['properties']['kind']=='part':boxes[f['properties']['id'].removeprefix('gbr-part-')]=extent(bounds([p for poly in f['geometry']['coordinates'] for ring in poly for p in ring]),40,40)
 boxes['all']=extent(bounds([p for f in features if f['properties']['kind']=='part' for poly in f['geometry']['coordinates'] for ring in poly for p in ring]),125,60)
 raster=extent(boxes['all'],170,110)
 return dict(schemaVersion=1,projection=dict(type='spherical-lcc',radius=6371.0088,centralMeridian=-3,origin=55,parallels=[49,61]),bounds=boxes,reliefBounds=raster,features=features,sources=[source(units,'Natural Earth 1:10m Map Units · 四组成部分及邻国','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/'),source(rivers,'Natural Earth 1:10m 河流','https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/'),source(lakes,'Natural Earth 1:10m 湖泊','https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-lakes/')],terrain=dict(title='NASA Blue Marble',url=NASA,processing='Inverse LCC resampling; atlas colour tint'))
def render(path,data):
 bmp=Bmp(path);x0,y0,x1,y1=data['reliefBounds'];w=1250;h=round(w*(y1-y0)/(x1-x0));stride=(w*3+3)&~3;pix=bytearray(stride*h)
 for row in range(h):
  y=y1-(row+.5)*(y1-y0)/h
  for col in range(w):
   b,g,r=bmp.pixel(*P.inverse(x0+(col+.5)*(x1-x0)/w,y))
   rgb=(236,213,167) if b>r*1.14 and b>g*1.04 else (min(240,int(94+b*.62)),min(242,int(126+g*.55)),min(244,int(104+r*.70)))
   at=row*stride+col*3;pix[at:at+3]=bytes(rgb)
 with tempfile.TemporaryDirectory() as tmp:
  file=Path(tmp)/'relief.bmp';info=struct.pack('<IiiHHIIiiII',40,w,h,1,24,0,len(pix),0,0,0,0);file.write_bytes(b'BM'+struct.pack('<III',54+len(pix),0,54)+info+pix)
  subprocess.run(['sips','-s','format','jpeg','-s','formatOptions','86',str(file),'--out',str(OUT/'gbr-relief.jpg')],check=True,capture_output=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 for k in ['units','rivers','lakes']:parser.add_argument(k,type=Path)
 parser.add_argument('--relief-bmp',type=Path);args=parser.parse_args();data=assemble(args.units,args.rivers,args.lakes)
 if args.relief_bmp:render(args.relief_bmp,data)
 (OUT/'gbr-regions.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
 print(len(data['features']),'features; view bounds',data['bounds'])
