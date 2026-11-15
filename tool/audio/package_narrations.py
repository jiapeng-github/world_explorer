"""Validate generated takes and make article previews without approving them."""
import json,hashlib,subprocess,html,zipfile
from pathlib import Path
import numpy as np
import soundfile as sf
import imageio_ffmpeg
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'tool/audio/generated'
records=json.loads((OUT/'manifest.json').read_text())
tracks=json.loads((ROOT/'assets/audio/narrations.json').read_text())['tracks']
assert len(records)==len(tracks)==15
articles={}
for r,t in zip(records,tracks):
 assert all(r[k]==t[k] for k in ['blockId','script','sourceHash','revision','voiceId','modelId'])
 wav=OUT/r['wav']; assert hashlib.sha256(wav.read_bytes()).hexdigest()==r['sha256']
 a,sr=sf.read(wav); assert sr==24000 and a.ndim==1 and np.isfinite(a).all() and np.sqrt(np.mean(a*a))>.001
 articles.setdefault(r['articleId'],[]).append(a)
titles={'china-geography':'中国：地势有什么不同？','egypt-geography':'埃及：尼罗河流向哪里？','antarctica-where':'南极：一块大陆，还是一个点？'}
summaries=[]; previews=[]
for article,parts in articles.items():
 combined=[]
 for i,a in enumerate(parts):
  if i: combined.append(np.zeros(12000))
  combined.append(a)
 wav=OUT/(article+'-full.wav'); sf.write(wav,np.concatenate(combined),24000,subtype='PCM_16')
 mp3=wav.with_suffix('.mp3')
 subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-v','error','-y','-i',str(wav),'-codec:a','libmp3lame','-b:a','128k',str(mp3)],check=True)
 duration=round(sum(map(len,combined))/24000,2)
 summaries.append({'articleId':article,'title':titles[article],'durationSeconds':duration,'file':mp3.name})
 previews.append('<article><h2>'+html.escape(titles[article])+'</h2><audio controls preload="none" src="'+mp3.name+'"></audio><p>'+str(duration)+' 秒 · 整篇试听</p></article>')
page=OUT/'index.html'; content=page.read_text(); content=content.replace('<h1>亲切向导 · 现有讲解录音</h1>','<h1>亲切向导 · 现有讲解录音</h1>'+''.join(previews)); page.write_text(content)
(OUT/'articles.json').write_text(json.dumps(summaries,ensure_ascii=False,indent=2)+'\n')
with zipfile.ZipFile(OUT.parent/'friendly-guide-narrations.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(OUT.iterdir()):
  if p.suffix in {'.mp3','.json','.html'}: z.write(p,p.name)
print(json.dumps(summaries,ensure_ascii=False,indent=2))
