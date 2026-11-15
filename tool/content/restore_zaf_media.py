"""Restore missing South Africa media from the reviewed manifest, verifying hashes.
Existing files are never replaced unless byte-identical to the reviewed asset.
Uses the normal system HTTPS/proxy configuration. No search or automatic licence
selection takes place: changing a source requires a new editorial review.
"""
import hashlib,json,ssl,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
 manifest=json.loads((ROOT/'tool/content/sources/zaf_media_manifest.json').read_text())
 for m in manifest['media']:
  p=ROOT/m['asset']
  if p.exists():
   assert hashlib.sha256(p.read_bytes()).hexdigest()==m['sha256'],m['id']+' local bytes differ'
   continue
  req=urllib.request.Request(m['downloadUrl'],headers={'User-Agent':'WorldExplorer educational atlas media restoration'})
  with urllib.request.urlopen(req,timeout=60,context=ssl.create_default_context()) as response:b=response.read()
  assert hashlib.sha256(b).hexdigest()==m['sha256'],m['id']+' downloaded bytes differ; review required'
  p.write_bytes(b)
  print(m['id'],'restored')
if __name__=='__main__':main()
