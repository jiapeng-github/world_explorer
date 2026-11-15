"""Import explicitly selected Commons images and preserve exact attribution.

Input is API imageinfo metadata plus a reviewed selection file. Uses system
network settings, never deletes existing assets, and rejects unsupported rights.
"""
import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import ssl
import time
from urllib.request import Request, urlopen
from fetch_china_media import image_size

ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('candidates',type=Path)
parser.add_argument('selection',type=Path)
args=parser.parse_args()
candidates=json.loads(args.candidates.read_text())
selection=json.loads(args.selection.read_text())
manifest=ROOT/'tool/content/editorial/brazil_assets.json'
assets=json.loads(manifest.read_text())

def plain(value):
    return html.unescape(re.sub('<[^>]*>','',value)).strip()

for key,selection in selection.items():
    page=candidates[key][selection['index']]
    info=page['imageinfo'][0];meta=info['extmetadata']
    license=plain(meta.get('LicenseShortName',{}).get('value',''))
    assert license.startswith(('CC BY', 'CC0', 'Public domain')), (key,license)
    url=info.get('thumburl',info['url']).split('?')[0]
    path=ROOT/f'assets/atlas/brazil-{key}.jpg'
    if not path.exists():
        with urlopen(Request(url,headers={'User-Agent':'WorldExplorer/1.0 educational atlas'}),timeout=40,context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')) as response:
            raw=response.read()
        image_size(raw)
        path.write_bytes(raw)
        time.sleep(1)
    raw=path.read_bytes();width,height=image_size(raw)
    row=dict(id='brazil-'+key,asset=str(path.relative_to(ROOT)),caption=selection['caption'],alt=selection['caption'],
        credit=plain(meta.get('Artist',{}).get('value','')),
        sourceUrl=info['descriptionurl'],license=license,
        licenseUrl=(meta.get('LicenseUrl',{}).get('value') or ('https://creativecommons.org/publicdomain/zero/1.0/' if license=='CC0' else 'https://commons.wikimedia.org/wiki/Commons:Public_domain')),
        width=width,height=height,kind=selection.get('kind','realPhoto'),sha256=hashlib.sha256(raw).hexdigest(),
        downloadUrl=url,checkedAt='2026-11-11',captureDate=plain(meta.get('DateTimeOriginal',{}).get('value','未标注')),
        processing='使用来源提供的等比例缩略图；未重绘或修改对象。',
        sourceDescription=plain(meta.get('ImageDescription',{}).get('value','')))
    row['licenseUrl']=row['licenseUrl'].replace('http://','https://')
    assert row['credit'],key
    assets['media']=[m for m in assets['media'] if m['id']!=row['id']]+[row]
    manifest.write_text(json.dumps(assets,ensure_ascii=False,indent=2)+'\n')
    print(key,width,height,license,flush=True)
