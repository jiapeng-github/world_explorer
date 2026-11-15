"""Reproducible WGS84 LAEA maps; Natural Earth map units, separate islands."""
import sys,json,hashlib,shutil
from pathlib import Path
from pyproj import CRS,Transformer
from shapely.geometry import shape,mapping,MultiPolygon,box,MultiLineString
from shapely.ops import transform,unary_union
from PIL import Image
from build_usa_regions import read,feature,source
from build_detail import ROOT,polygons,shapefile_rings
from build_china_rivers import polylines
out=ROOT/'assets/atlas'; inputs=ROOT/'tool/maps/sources/norway';inputs.mkdir(parents=True,exist_ok=True)
for name,old in [('units.zip','/private/tmp/deu-geo/units2.zip'),('boundaries.zip','/private/tmp/kenya-geo/boundaries.zip')]:
 if not (inputs/name).exists():shutil.copy2(old,inputs/name)
rows=list(read(inputs/'units.zip','ne_10m_admin_0_map_units',shapefile_rings))
def geom(ps):return shape(dict(type='MultiPolygon',coordinates=polygons(ps))).buffer(0)
units={r['GU_A3']:geom(s) for r,s in rows if r['ADM0_A3']=='NOR'}
src=Image.open(out/'earth-relief.jpg').convert('RGB');regions={};checks=[]
# IAU mean obliquity polynomial at J2000 + 26.86 Julian years (2026-11-12).
t=(2026.863-2000)/100;eps=(84381.406-46.836769*t-.0001831*t*t+.0020034*t**3)/3600;circle=90-eps
for key,code,lat0,lon0 in [('mainland','NOW',65,15),('svalbard','NSV',78,20),('jan-mayen','NJM',71,-8)]:
 crs=CRS.from_proj4(f'+proj=laea +lat_0={lat0} +lon_0={lon0} +datum=WGS84 +units=m +no_defs');tx=Transformer.from_crs(4326,crs,always_xy=True);inv=Transformer.from_crs(crs,4326,always_xy=True)
 def project(x,y,z=None):
  a,b=tx.transform(x,y);return a/1000,-b/1000
 def poly(id,name,kind,g):
  g=transform(project,g)
  if g.geom_type=='Polygon':g=MultiPolygon([g])
  return feature('norway-'+id,name,kind,'MultiPolygon',mapping(g)['coordinates'])
 features=[]
 if key=='mainland':
  for cc,name in [('SWE','瑞典'),('FIN','芬兰'),('RUS','俄罗斯')]:
   g=unary_union([geom(s) for r,s in rows if r['ADM0_A3']==cc]).intersection(box(2,56,35,72))
   features.append(poly('context-'+cc.lower(),name,'context',g))
 features.append(poly('part-'+key,{'mainland':'挪威本土','svalbard':'斯瓦尔巴','jan-mayen':'扬马延'}[key],'part',units[code]))
 landlines=[]
 if key=='mainland':
  for r,ps in read(inputs/'boundaries.zip','ne_10m_admin_0_boundary_lines_land',polylines):
   if 'NOR' in [r.get('ADM0_A3_L'),r.get('ADM0_A3_R')]:landlines+=ps
  assert landlines
  features.append(feature('norway-border','陆地国界','border','MultiLineString',[[project(x,y) for x,y in line] for line in landlines]))
  features.append(feature('norway-arctic-circle','北极圈 · 约66.56°N','reference','MultiLineString',[[project(2+i*.1,circle) for i in range(331)]]))
 coast=units[code].boundary
 if landlines:coast=coast.difference(MultiLineString(landlines).buffer(.002))
 lines=[list(g.coords) for g in getattr(coast,'geoms',[coast]) if g.geom_type=='LineString']
 features.append(feature('norway-coast' if key=='mainland' else 'norway-coast-'+key,'海岸线','coast','MultiLineString',[[project(x,y) for x,y in line] for line in lines]))
 g=transform(project,units[code]);x0,y0,x1,y1=g.bounds;pad=max(5,(x1-x0)*.08);bounds=[x0-pad,y0-pad,x1+pad,y1+pad];rb=[x0-pad*2,y0-pad*2,x1+pad*2,y1+pad*2]
 w=1100;h=min(1900,round(w*(rb[3]-rb[1])/(rb[2]-rb[0])));im=Image.new('RGB',(w,h));pix=im.load()
 for row in range(h):
  yy=rb[1]+(row+.5)*(rb[3]-rb[1])/h;xs=[(rb[0]+(col+.5)*(rb[2]-rb[0])/w)*1000 for col in range(w)];lons,lats=inv.transform(xs,[-yy*1000]*w)
  for col,(lon,lat) in enumerate(zip(lons,lats)):
   sx=max(0,min(src.width-1,int((lon+180)/360*src.width)));sy=max(0,min(src.height-1,int((90-lat)/180*src.height)));r,g,b=src.getpixel((sx,sy));pix[col,row]=(min(245,int(35+r*.82)),min(245,int(55+g*.78)),min(245,int(45+b*.78)))
 im.save(out/f'norway-{key}-relief.jpg',quality=90)
 regions[key]=dict(bounds=bounds,reliefBounds=rb,features=features,projection=dict(type='LAEA',lat0=lat0,lon0=lon0,datum='WGS84',units='km',screenY='negative northing'))
 for lat,lon in [(lat0,lon0),(lat0+.5,lon0+1),(lat0-1,lon0-2)]:checks.append(dict(region=key,lat=lat,lon=lon,xy=project(lon,lat)))
 print(key,len(features),units[code].bounds,flush=True)
result=dict(schemaVersion=1,regions=regions,projectionChecks=checks,entityMapping=dict(NOW='norway',NSV='norway',NJM='norway'),excludedUnits=['BVT'],arcticCircle=dict(latitude=circle,epoch='2026-11-12',method='90 degrees minus IAU 2006 mean obliquity polynomial; educational approximation'),sources=[source(inputs/'units.zip','Natural Earth · Map Units','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/'),source(inputs/'boundaries.zip','Natural Earth · Land Boundaries','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-boundary-lines/'),dict(name='NASA Blue Marble',url='https://visibleearth.nasa.gov/collection/1484/blue-marble',sha256=hashlib.sha256((out/'earth-relief.jpg').read_bytes()).hexdigest(),processing='Independent region reprojection; illustrative background, not elevation measurements')])
(out/'norway-regions.json').write_text(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n')
