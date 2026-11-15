"""Produce and install missing offline article narration from the fixed voice profile."""

import argparse
from collections import Counter
import fcntl
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'assets/audio/narrations.json'
WORK = ROOT / 'tool/audio/.production'
PROFILE = ROOT / 'tool/audio/voice_profile.json'
ASSET = re.compile(r'assets/audio/[a-zA-Z0-9_-]+\.mp3')
LOOPBACK = 'http://127.0.0.1:3900'
LOUDNESS = -18
PEAK = -2.5
BITRATE = '48k'
DIGITS = str.maketrans('0123456789', '零一二三四五六七八九')


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write_json(path, data):
    temporary = path.with_suffix('.json.tmp')
    temporary.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
    )
    temporary.replace(path)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def read_articles():
    articles = []
    article_ids, block_ids = set(), set()
    for name in ('catalog.json', 'antarctica-region.json'):
        for article in read_json(ROOT / 'assets/atlas' / name)['articles']:
            article_id = article['id']
            if article_id in article_ids or not article['blocks']:
                raise ValueError(f'Duplicate or empty article: {article_id}')
            article_ids.add(article_id)
            for block in article['blocks']:
                block_id = block['id']
                if block_id in block_ids or not ASSET.fullmatch(f'assets/audio/{block_id}.mp3'):
                    raise ValueError(f'Duplicate or unsafe block ID: {block_id}')
                block_ids.add(block_id)
            articles.append(article)
    return articles


def source_track(article, block, profile):
    title = block['title'].strip()
    body = ' '.join(block['text'].split())
    script = f'{title}{"。" if title and title[-1] not in "。！？!?" else ""}{body}'
    # Year digits are read individually in Mandarin, including the start of a range.
    script = re.sub(
        r'(?<![0-9])([0-9]{4})(?=\s*(?:年|至\s*[0-9]{4}\s*年))',
        lambda m: m[1].translate(DIGITS),
        script,
    )
    script = re.sub(r'(\d{2})\.(\d+)(?=度)', spoken_latitude, script)
    return {
        'articleId': article['id'],
        'revision': article.get('revision', 1),
        'blockId': block['id'],
        'sourceHash': sha(f"{block['title']}\n{block['text']}".encode()),
        'script': script,
        'scriptReviewed': False,
        'voiceId': profile['voiceId'],
        'modelId': profile['modelId'],
    }


def spoken_latitude(match):
    tens, units = match[1].translate(DIGITS)
    whole = (tens if tens != '一' else '') + '十' + (units if units != '零' else '')
    return whole + '点' + match[2].translate(DIGITS)


def matches(old, track):
    return all(old.get(field) == track[field]
               for field in ('articleId', 'revision', 'blockId', 'sourceHash'))


def installed(old, track):
    asset = old.get('asset') or ''
    return (
        matches(old, track)
        and old.get('reviewStatus') == 'approved'
        and bool(ASSET.fullmatch(asset))
        and (ROOT / asset).is_file()
        and (ROOT / asset).stat().st_size > 1000
    )


def cache_key(track, profile, seed=None):
    if seed is None:
        seed = profile['seed']
    return sha(json.dumps([track, profile, seed], ensure_ascii=False, sort_keys=True).encode())


def staging(track, profile, seed=None):
    key = cache_key(track, profile, seed)
    return WORK / 'takes' / f"{track['blockId']}-{key[:16]}"


def synthesize(session, track, profile, reference, seed):
    data = {
        'text': track['script'],
        'language': profile['language'],
        'engine': profile['engine'],
        'instruct': profile['instruct'],
        'seed': str(seed),
        'effect_preset': profile['effect_preset'],
        'denoise': str(profile['denoise']).lower(),
    }
    response = session.post(
        LOOPBACK + '/generate',
        data=data,
        files={'ref_audio': (reference.name, reference.read_bytes(), 'audio/wav')},
        timeout=(5, 600),
    )
    response.raise_for_status()
    return response.content


def wav_details(blob, script):
    import numpy as np
    import soundfile as sf

    samples, rate = sf.read(io.BytesIO(blob), dtype='float32')
    duration = len(samples) / rate
    voiced_chars = len(re.sub(r'[^\w]', '', script))
    if (
        rate != 24000 or samples.ndim != 1 or not np.isfinite(samples).all()
        or duration < max(0.65, voiced_chars / 10)
        or duration > max(12, voiced_chars / 1.5)
        or np.mean(samples**2) < 0.000001
    ):
        raise ValueError(f'Invalid audio: {duration:.2f} seconds, {rate} Hz for {voiced_chars} characters')
    # Check for a dropped start/end or a long gap within a recording.
    frames = samples[: len(samples) // 2400 * 2400].reshape(-1, 2400)
    audible = np.flatnonzero(np.max(np.abs(frames), axis=1) > .004)
    if (not audible.size or audible[0] > 26 or len(frames) - audible[-1] > 31
            or np.max(np.diff(audible), initial=0) > 43):
        raise ValueError('Unexpected silence in generated WAV')
    return round(duration, 3)


def encode(ffmpeg, source, output):
    normalizer = f'loudnorm=I={LOUDNESS}:TP={PEAK}:LRA=11'
    prefix = [ffmpeg, '-nostdin', '-hide_banner', '-i', str(source)]
    measurement = subprocess.run(
        prefix + ['-af', normalizer + ':print_format=json', '-f', 'null', '-'],
        capture_output=True, text=True, check=True,
    ).stderr
    measured, _ = json.JSONDecoder().raw_decode(measurement[measurement.rfind('{'):])
    fields = {
        'measured_I': 'input_i',
        'measured_TP': 'input_tp',
        'measured_LRA': 'input_lra',
        'measured_thresh': 'input_thresh',
        'offset': 'target_offset',
    }
    for parameter, field in fields.items():
        normalizer += f':{parameter}={measured[field]}'
    temporary = output.with_suffix('.tmp.mp3')
    subprocess.run(
        prefix + [
            '-v', 'error', '-y', '-af', normalizer + ':linear=true',
            '-ar', '24000', '-ac', '1', '-codec:a', 'libmp3lame', '-b:a', BITRATE,
            str(temporary),
        ],
        check=True,
    )
    temporary.replace(output)
    return float(measured['input_i'])


def read_take(track, profile, seed):
    path = staging(track, profile, seed)
    meta = path.with_suffix('.json')
    mp3 = path.with_suffix('.mp3')
    if not meta.is_file() or not mp3.is_file():
        return None
    take = read_json(meta)
    if take.get('mp3Sha256') != sha(mp3.read_bytes()):
        return None
    return take, mp3


def finish_take(track, profile, seed, blob, *, engine, elapsed, ffmpeg):
    path = staging(track, profile, seed)
    wav = path.with_suffix('.wav')
    mp3 = path.with_suffix('.mp3')
    seconds = wav_details(blob, track['script'])
    temporary = wav.with_suffix('.wav.tmp')
    temporary.write_bytes(blob)
    temporary.replace(wav)
    input_loudness = encode(ffmpeg, wav, mp3)
    take = {
        'durationSeconds': seconds,
        'generationId': path.name,
        'generationSeconds': round(elapsed, 2),
        'synthesisRunner': engine,
        'seed': seed,
        'inputLoudnessLufs': input_loudness,
        'mp3Sha256': sha(mp3.read_bytes()),
    }
    write_json(path.with_suffix('.json'), take)
    print(f"TAKE {track['blockId']} {seconds:.2f}s ({elapsed:.1f}s)", flush=True)
    return take, mp3


def install_article(pending, profile, approved_at):
    manifest = read_json(MANIFEST)
    # Recheck against the current source before making any files playable.
    current = {a['id']: a for a in read_articles()}[pending[0][0]['articleId']]
    current_tracks = {
        row['blockId']: row
        for row in (source_track(current, b, profile) for b in current['blocks'])
    }
    old_tracks = {row['blockId']: row for row in manifest['tracks']}
    additions = {}
    for track, (take, mp3) in pending:
        key = track['blockId']
        if key not in current_tracks or not matches(track, current_tracks[key]):
            raise RuntimeError(f'Source changed during recording: {key}')
        if installed(old_tracks.get(key, {}), track):
            continue
        relative = f'assets/audio/{key}.mp3'
        dest = ROOT / relative
        temporary = WORK / (key + '.mp3.installing')
        shutil.copyfile(mp3, temporary)
        temporary.replace(dest)
        additions[key] = track | take | {
            'asset': relative,
            'reviewStatus': 'approved',
            'approvalBasis': 'userRequestedProductionReplacement',
            'approvedAt': approved_at,
            'targetLoudnessLufs': LOUDNESS,
        }
    if additions:
        merged = old_tracks | additions
        for key, track in current_tracks.items():
            if not installed(merged.get(key, {}), track):
                raise RuntimeError(f'Cannot install an incomplete article: {key}')
        manifest['tracks'] = list(merged.values())
        write_json(MANIFEST, manifest)


def inventory(profile):
    old_tracks = {t['blockId']: t for t in read_json(MANIFEST)['tracks']}
    counts = Counter()
    jobs = []
    for article in read_articles():
        tracks = [source_track(article, b, profile) for b in article['blocks']]
        pending = []
        for track in tracks:
            old = old_tracks.get(track['blockId'], {})
            if not installed(old, track):
                if matches(old, track) and old.get('scriptReviewed') and old.get('script'):
                    track['script'] = old['script']
                    track['scriptReviewed'] = True
                pending.append(track)
        counts.update(articles=1, tracks=len(tracks), remaining_articles=bool(pending),
                      remaining_tracks=len(pending))
        if pending:
            jobs.append((article, pending))
    return counts, jobs


def verify(profile, counts):
    if counts['remaining_tracks']:
        raise SystemExit(f"{counts['remaining_tracks']} passages still need bundled audio.")
    tracks = read_json(MANIFEST)['tracks']
    if len(tracks) != counts['tracks']:
        raise ValueError('The installed manifest contains extra or duplicate tracks.')
    total_size = 0
    total_seconds = 0
    for track in tracks:
        if track['voiceId'] != profile['voiceId'] or track['modelId'] != profile['modelId']:
            raise ValueError(f"Unexpected voice profile for {track['blockId']}")
        data = (ROOT / track['asset']).read_bytes()
        if track.get('mp3Sha256') and sha(data) != track['mp3Sha256']:
            raise ValueError(f"File checksum mismatch: {track['asset']}")
        total_size += len(data)
        total_seconds += track['durationSeconds']
    print(json.dumps({'audioBytes': total_size, 'audioSeconds': round(total_seconds, 2)}))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_mutually_exclusive_group(required=True)
    commands.add_argument('--status', action='store_true')
    commands.add_argument('--verify', action='store_true', help='Require complete offline audio.')
    commands.add_argument('--publish', metavar='DATE', help='Produce, validate and install offline audio.')
    options = parser.parse_args()
    profile = read_json(PROFILE)
    counts, jobs = inventory(profile)
    print(json.dumps(counts), flush=True)
    if options.verify:
        verify(profile, counts)
        return
    if not options.publish or not jobs:
        return

    import imageio_ffmpeg
    import requests

    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', options.publish):
        parser.error('--publish requires YYYY-MM-DD')
    reference = ROOT / profile['referenceAudio']
    if sha(reference.read_bytes()) != profile['referenceSha256']:
        raise ValueError('The selected voice reference does not match its recorded checksum.')
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    (WORK / 'takes').mkdir(parents=True, exist_ok=True)
    errors = []
    with (WORK / 'publish.lock').open('w') as lock, requests.Session() as session:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        session.trust_env = False
        for article, tracks in jobs:
            try:
                completed = []
                for track in tracks:
                    for seed in (profile['seed'], profile['seed'] + 1, profile['seed'] + 2):
                        take = read_take(track, profile, seed)
                        if take is not None:
                            break
                        start = time.monotonic()
                        try:
                            raw = staging(track, profile, seed).with_suffix('.wav')
                            blob = raw.read_bytes() if raw.is_file() else synthesize(
                                session, track, profile, reference, seed,
                            )
                            take = finish_take(
                                track, profile, seed, blob, engine='VoiceStudio CosyVoice3',
                                elapsed=time.monotonic() - start, ffmpeg=ffmpeg,
                            )
                            break
                        except (requests.RequestException, ValueError, RuntimeError) as error:
                            print(f"RETRY {track['blockId']} {seed}: {error}", flush=True)
                            if seed == profile['seed'] + 2:
                                raise
                            time.sleep(2)
                    completed.append((track, take))
                install_article(completed, profile, options.publish)
                print(f"INSTALLED {article['id']} {article['title']}", flush=True)
            except (requests.RequestException, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
                print(f"FAILED {article['id']}: {error}", flush=True)
                errors.append(article['id'])
    counts, _ = inventory(profile)
    print(json.dumps(counts), flush=True)
    if errors or counts['remaining_articles']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
