"""Kenya atlas, Natural Earth geometry and ellipsoidal LAEA centered 0N 38E."""
import json,sys,hashlib
from pathlib import Path
from pyproj import Transformer,CRS
from shapely.geometry import shape,mapping,MultiPolygon,box,LineString
from shapely.ops import transform,unary_union
from PIL import Image
from build_usa_regions import read,feature,source
from build_detail import ROOT,polygons,shapefile_rings
from build_china_rivers import polylines
p=Path(sys.argv[1]);base=Path(sys.argv[2]);out=ROOT/'assets/atlas'
crs=CRS.from_proj4('+proj=laea +lat_0=0 +lon_0=38 +datum=WGS84 +units=m +no_defs');tx=Transformer.from_crs(4326,crs,always_xy=True);inv=Transformer.from_crs(crs,4326,always_xy=True)
def project(x,y,z=None):
 a,b=tx.transform(x,y);return a/1000,-b/1000
def geom(ps):return shape(dict(type='MultiPolygon',coordinates=polygons(ps))).buffer(0)
def poly(id,name,kind,g,**extra):
 g=transform(project,g)
 if g.geom_type=='Polygon':g=MultiPolygon([g])
 return feature('kenya-'+id,name,kind,'MultiPolygon',mapping(g)['coordinates'],**extra)
rows=list(read(base/'units2.zip','ne_10m_admin_0_map_units',shapefile_rings));ke=unary_union([geom(s) for r,s in rows if r['GU_A3']=='KEN']);features=[]
for code,name in [('UGA','乌干达'),('TZA','坦桑尼亚'),('ETH','埃塞俄比亚'),('SOM','索马里'),('SDS','南苏丹')]:
 g=unary_union([geom(s) for r,s in rows if r['GU_A3']==code or (code=='SOM' and r['ADM0_A3']=='SOM')]).intersection(box(31,-7,45,8))
 if not g.is_empty:features.append(poly('context-'+code.lower(),name,'context',g))
features.append(poly('part-kenya','肯尼亚','part',ke))
disputes=[geom(s) for r,s in read(p/'disputed.zip','ne_10m_admin_0_disputed_areas',shapefile_rings) if r['BRK_A3'] in ['B17','B74']]
features.append(poly('disputed-ilemi','伊莱米三角 · 争议区','disputed',unary_union(disputes)))
for r,s in read(p/'lakes.zip','ne_10m_lakes',shapefile_rings):
 if r['name'] in ['Lake Victoria','Lake Turkana']:
  slug,name={'Lake Victoria':('victoria','维多利亚湖'),'Lake Turkana':('turkana','图尔卡纳湖')}[r['name']]
  features.append(poly('lake-'+slug,name,'lake',geom(s),english=r['name']))
# Reference latitude, generated mathematically; never an administrative boundary.
features.append(feature('kenya-equator','赤道 · 0°','reference','MultiLineString',[[project(31+i*.1,0) for i in range(141)]]))
# Inland boundary segments from original country boundary source, no invented join.
lines=[]
for r,ps in read(p/'boundaries.zip','ne_10m_admin_0_boundary_lines_land',polylines):
 if 'KEN' in [r.get('ADM0_A3_L'),r.get('ADM0_A3_R')]:lines+=ps
assert lines,'Kenya boundary records missing'
features.append(feature('kenya-border','陆地国界 · 参照线','border','MultiLineString',[[project(x,y) for x,y in line] for line in lines]))
# Coast is derived by removing inland boundaries from original country outline.
from shapely.geometry import MultiLineString
landlines=MultiLineString(lines)
coast=ke.boundary.difference(landlines.buffer(.002)).intersection(box(39,-5,42.2,-1.4))
coastlines=[list(x.coords) for x in getattr(coast,'geoms',[coast]) if x.geom_type=='LineString']
features.append(feature('kenya-coast','印度洋海岸','coast','MultiLineString',[[project(x,y) for x,y in line] for line in coastlines]))
g=transform(project,ke);x0,y0,x1,y1=g.bounds;bounds=[x0-130,y0-65,x1+100,y1+65];rb=[x0-240,y0-160,x1+230,y1+160]
sources=[source(base/'units2.zip','Natural Earth · Map Units','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/'),source(p/'lakes.zip','Natural Earth · Lakes','https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-lakes/'),source(p/'boundaries.zip','Natural Earth · Land Boundaries','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-boundary-lines/'),source(p/'disputed.zip','Natural Earth · disputed areas','https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-details/')]
relief=p/'relief.jpg'
try:src=Image.open(relief).convert('RGB');extent=[31,-7,45,8];relief_source='https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi'
except Exception:relief=out/'earth-relief.jpg';src=Image.open(relief).convert('RGB');extent=[-180,-90,180,90];relief_source='https://visibleearth.nasa.gov/collection/1484/blue-marble'
sources.append(dict(name='NASA Blue Marble',url=relief_source,sha256=hashlib.sha256(relief.read_bytes()).hexdigest(),inputBounds=extent,outputCRS=crs.to_string(),processing='Reprojected and softened; background imagery, not live or elevation measurement.'))
w=1250;h=round(w*(rb[3]-rb[1])/(rb[2]-rb[0]));dst=Image.new('RGB',(w,h));pixels=dst.load()
for row in range(h):
 yy=rb[1]+(row+.5)*(rb[3]-rb[1])/h;xs=[(rb[0]+(col+.5)*(rb[2]-rb[0])/w)*1000 for col in range(w)];lons,lats=inv.transform(xs,[-yy*1000]*w)
 for col,(lon,lat) in enumerate(zip(lons,lats)):
  sx=max(0,min(src.width-1,int((lon-extent[0])/(extent[2]-extent[0])*src.width)));sy=max(0,min(src.height-1,int((extent[3]-lat)/(extent[3]-extent[1])*src.height)));r,g,b=src.getpixel((sx,sy));pixels[col,row]=(min(245,int(65+r*.74)),min(245,int(84+g*.65)),min(240,int(57+b*.64)))
dst.save(out/'kenya-all-relief.jpg',quality=90)
data=dict(bounds=bounds,reliefBounds=rb,features=features,projection={'type':'LAEA','lat0':0,'lon0':38,'datum':'WGS84','units':'km','screenY':'negative northing'})
result=dict(schemaVersion=1,regions={'all':data},sources=sources,boundaryNote='Natural Earth representation. Ilemi Triangle: administered by Kenya and claimed by South Sudan; shown separately as disputed, not an uncontested boundary.',projectionChecks=[dict(lat=lat,lon=lon,xy=project(lon,lat)) for lat,lon in [(-1.286,36.817),(-.152,37.308),(-2.269,40.903),(3.5,36.1)]])
(out/'kenya-regions.json').write_text(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n');print('Kenya',len(features),'features',src.size)
