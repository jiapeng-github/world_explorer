"""Generate resumable, fixed-voice narration takes; never self-approve recordings."""
import hashlib, io, json, time, wave, subprocess, html
from pathlib import Path
import requests
import imageio_ffmpeg
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tool/audio/generated'
OUT.mkdir(exist_ok=True)
profile = json.loads((ROOT / 'tool/audio/voice_profile.json').read_text())
manifest = json.loads((ROOT / 'assets/audio/narrations.json').read_text())
ref = ROOT / profile['referenceAudio']
assert hashlib.sha256(ref.read_bytes()).hexdigest() == profile['referenceSha256']
records = []
for i, track in enumerate(manifest['tracks'], 1):
    key = hashlib.sha256(json.dumps({'track':track,'profile':profile},sort_keys=True,ensure_ascii=False).encode()).hexdigest()
    dest = OUT / (track['blockId'] + '.wav')
    meta = dest.with_suffix('.json')
    if meta.exists() and dest.exists() and json.loads(meta.read_text()).get('generationKey') == key:
        record = json.loads(meta.read_text())
        print('REUSE', track['blockId'], flush=True)
    else:
        print('START', i, track['blockId'], flush=True)
        start = time.monotonic()
        with ref.open('rb') as f:
            response = requests.post('http://127.0.0.1:3900/generate', data={
                'text':track['script'], 'language':profile['language'], 'engine':profile['engine'],
                'instruct':profile['instruct'], 'seed':str(profile['seed']),
                'effect_preset':profile['effect_preset'], 'denoise':str(profile['denoise']).lower(),
            }, files={'ref_audio':(ref.name,f,'audio/wav')}, timeout=900)
        response.raise_for_status()
        with wave.open(io.BytesIO(response.content)) as wav:
            assert wav.getnframes() > wav.getframerate()
        dest.write_bytes(response.content)
        samples, sr = sf.read(dest)
        assert np.isfinite(samples).all() and np.max(np.abs(samples)) > 0
        record = dict(track, generationKey=key, generationId=dest.stem+'-'+key[:12],
            voiceProfile=profile, wav=dest.name, durationSeconds=round(len(samples)/sr,3),
            sampleRate=sr, rms=round(float(np.sqrt(np.mean(samples**2))),5),
            peak=round(float(np.max(np.abs(samples))),5),
            sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),
            generatedAt=time.strftime('%Y-%m-%dT%H:%M:%S%z'),
            generationSeconds=round(time.monotonic()-start,2), reviewStatus='awaitingReview')
        meta.write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')
    mp3 = dest.with_suffix('.mp3')
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-v','error','-y','-i',str(dest),'-codec:a','libmp3lame','-b:a','128k',str(mp3)],check=True)
    records.append(record)
    (OUT/'manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n')
    print('DONE',i,track['blockId'],record['durationSeconds'],flush=True)

cards=[]
for r in records:
    cards.append('<article><h2>'+html.escape(r['blockId'])+'</h2><p>'+html.escape(r['script'])+'</p><audio controls preload="none" src="'+r['wav']+'"></audio><p>'+str(r['durationSeconds'])+' 秒 · <a download href="'+r['wav']+'">WAV</a> · <a download href="'+r['wav'].replace('.wav','.mp3')+'">MP3</a></p></article>')
(OUT/'index.html').write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>世界大百科 · 亲切向导讲解</title><style>body{background:#f3f6f9;color:#143653;font:17px/1.8 system-ui;margin:24px auto;padding:20px;max-width:900px}article{background:white;border-radius:16px;padding:24px;margin:20px 0}h2{font-size:20px}audio{width:100%}a{color:#006088}</style><h1>亲切向导 · 现有讲解录音</h1><p>中国地势、埃及尼罗河、南极洲，共 15 段。已检查文件完整性，待逐段听审。</p>'''+''.join(cards)+'''<script>document.querySelectorAll('audio').forEach(a=>a.onplay=()=>document.querySelectorAll('audio').forEach(b=>{if(a!==b)b.pause()}))</script></html>''')
print('COMPLETE',len(records),sum(r['durationSeconds'] for r in records),flush=True)
