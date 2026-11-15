"""Product map grouping. Preserve source polygons; do not invent island extents."""
def merge_china(collection):
    rows = collection['features']
    china = next(f for f in rows if f['properties']['code'] == 'CHN')
    taiwan = [f for f in rows if f['properties']['code'] == 'TWN']
    if not taiwan:
        return collection
    def polygons(f):
        g=f['geometry']
        return g['coordinates'] if g['type']=='MultiPolygon' else [g['coordinates']]
    china['geometry']={'type':'MultiPolygon','coordinates':polygons(china)+[p for f in taiwan for p in polygons(f)]}
    collection['features']=[f for f in rows if f not in taiwan]
    collection['displayPolicy']='China grouping: CHN + TWN source polygons; small islands use sourced point annotations, not invented polygons.'
    return collection

def normalize_catalog(catalog):
    catalog['countries']=[c for c in catalog['countries'] if c['id']!='twn']
    return catalog
