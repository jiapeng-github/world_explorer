#!/usr/bin/env python3
"""Germany teaching atlas. Requires pyproj, shapely and Pillow.
WGS84 input -> ETRS89 LAEA EPSG:3035 metres -> screen kilometres (negative northing).
Usage: python3 tool/maps/build_deu_regions.py SOURCE_DIRECTORY
"""
import json,sys,hashlib
from pathlib import Path
from pyproj import Transformer
from shapely.geometry import shape,mapping,Polygon,MultiPolygon,box
from shapely.ops import transform,unary_union
from PIL import Image
from build_usa_regions import read,feature,source
from build_detail import ROOT,polygons,shapefile_rings
from build_china_rivers import polylines
p=Path(sys.argv[1]);out=ROOT/'assets/atlas';tx=Transformer.from_crs(4326,3035,always_xy=True);inv=Transformer.from_crs(3035,4326,always_xy=True)
def project(x,y,z=None):
 a,b=tx.transform(x,y);return a/1000,-b/1000
def geom(parts):return shape(dict(type='MultiPolygon',coordinates=polygons(parts))).buffer(0)
def fpoly(id,name,kind,g,**extra):
 g=transform(project,g)
 if g.geom_type=='Polygon':g=MultiPolygon([g])
 return feature('deu-'+id,name,kind,'MultiPolygon',mapping(g)['coordinates'],**extra)
rows=list(read(p/'units2.zip','ne_10m_admin_0_map_units',shapefile_rings));de=next(geom(s) for r,s in rows if r['GU_A3']=='DEU');features=[]
context={'FXX':'法国','BFR':'比利时','BWR':'比利时','BCR':'比利时','NLX':'荷兰','LUX':'卢森堡','CHE':'瑞士','AUT':'奥地利','CZE':'捷克','POL':'波兰','DNK':'丹麦'}
for code,name in context.items():
 if code in ['BWR','BCR']:continue
 parts=[geom(s) for r,s in rows if r['GU_A3'] in (['BFR','BWR','BCR'] if code=='BFR' else [code])]
 features.append(fpoly('context-'+('bel' if code=='BFR' else code.lower()),name,'context',unary_union(parts).intersection(box(2,44,20,58))))
features.append(fpoly('part-germany','德国','part',de))
reg={r['NAME']:geom(s) for r,s in read(p/'regions2.zip','ne_10m_geography_regions_polys',shapefile_rings) if r['NAME'] in ['ALPS','NORTHERN EUROPEAN PLAIN']}
regions=[('north','北部低地',reg['NORTHERN EUROPEAN PLAIN'].intersection(de)),('alps','德国阿尔卑斯',reg['ALPS'].intersection(de))]
# Central uplands is a deliberately generalized teaching extent, not an official boundary.
central=Polygon([(6,50.1),(6.5,51.5),(8.0,52.05),(9.3,52.25),(10.8,51.9),(12,51.4),(14.8,51.05),(14,50.3),(13,49.2),(12.2,48.65),(11,49.0),(9.5,48.7),(8,48.45),(7.3,49.1)])
# Cultural area around Upper and Lower Lusatia. Not the legal Sorbian settlement area.
lusatia=Polygon([(13.65,51.1),(13.7,51.7),(14.1,52.05),(14.75,52.0),(15.05,51.4),(14.95,50.85),(14.35,50.85)])
regions += [('central','中部山地 · 概略',central.intersection(de).difference(reg['NORTHERN EUROPEAN PLAIN'])),('lusatia','劳西茨 · 文化区域示意',lusatia.intersection(de))]
for slug,name,g in regions:features.append(fpoly('terrain-'+slug,name,'terrain',g,aliases=['教学区域','概略范围']))
rs=list(read(p/'rivers2.zip','ne_10m_rivers_lake_centerlines',polylines))
for q,slug,name in [('Q584','rhine','莱茵河'),('Q1667','moselle','摩泽尔河'),('Q1644','elbe','易北河'),('Q1653','danube','多瑙河')]:
 lines=[line for r,ps in rs if r.get('wikidataid')==q for line in ps]
 if not lines:
  en={'rhine':'Rhine','moselle':'Mosel','elbe':'Elbe','danube':'Danube'}[slug]
  lines=[line for r,ps in rs if en.lower() in r.get('name','').lower() for line in ps]
 assert lines,(q,name)
 features.append(feature('deu-feature-'+slug,name,'river','MultiLineString',[[project(x,y) for x,y in line] for line in lines]))
g=transform(project,de);x0,y0,x1,y1=g.bounds;b=[x0-85,y0-45,x1+85,y1+45];rb=[x0-200,y0-160,x1+200,y1+160]
data=dict(bounds=b,reliefBounds=rb,features=features,projection={'type':'EPSG:3035','units':'km','screenY':'negative northing'})
result=dict(schemaVersion=1,regions={'all':data},sources=[source(p/'units2.zip','Natural Earth · 10m Map Units','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/'),source(p/'rivers2.zip','Natural Earth · 10m Rivers','https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/'),source(p/'regions2.zip','Natural Earth · Geography Regions','https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-geography-regions/')],teachingRegions={'north/alps':'Natural Earth natural regions intersected with Germany. Generalized physical extents, not legal boundaries.','central':'Authored generalized central upland outline, clipped to Germany; excludes northern plain. Geography reference: https://www.bpb.de/kurz-knapp/lexika/kosmos-weltalmanach/65657/deutschland/','lusatia':'Authored illustrative cultural extent in Germany, not an official settlement boundary. Reference: Domowina/FUEN Non-Kin-State brochure pp18–19.'},projectionChecks=[dict(lat=lat,lon=lon,xy=project(lon,lat)) for lat,lon in [(52.52,13.405),(50.364,7.607),(47.56,12.98),(54.18,8.82)]])
if (p/'relief.jpg').exists():
 result['sources'].append(dict(name='NASA GIBS · Blue Marble Shaded Relief',url='https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi',layer='BlueMarble_ShadedRelief_Bathymetry',inputBounds=[3,45,18,57],inputCRS='EPSG:4326',outputCRS='EPSG:3035',sha256=hashlib.sha256((p/'relief.jpg').read_bytes()).hexdigest(),processing='Reprojected to ETRS89 LAEA, softened for readable teaching map; not a live image.'))
(out/'deu-regions.json').write_text(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n')
if (p/'relief.jpg').exists():
 src=Image.open(p/'relief.jpg').convert('RGB');w=1250;h=round(w*(rb[3]-rb[1])/(rb[2]-rb[0]));dst=Image.new('RGB',(w,h));pixels=dst.load()
 for row in range(h):
  yy=rb[1]+(row+.5)*(rb[3]-rb[1])/h
  xs=[(rb[0]+(col+.5)*(rb[2]-rb[0])/w)*1000 for col in range(w)]
  lons,lats=inv.transform(xs,[-yy*1000]*w)
  for col,(lon,lat) in enumerate(zip(lons,lats)):
   sx=max(0,min(src.width-1,int((lon-3)/15*src.width)));sy=max(0,min(src.height-1,int((57-lat)/12*src.height)));r,g,b=src.getpixel((sx,sy));pixels[col,row]=(min(245,int(104+r*.63)),min(245,int(118+g*.55)),min(240,int(94+b*.60)))
 dst.save(out/'deu-all-relief.jpg',quality=88)
print('Germany:',len(features),'features;',[(a,round(g.area,2)) for a,_,g in regions])
