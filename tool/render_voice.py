#!/usr/bin/env python3
"""يسجّل كل الأصوات العربية للتطبيق بصوت مصري عصبي (Microsoft Neural TTS).

المصادر:
  tool/clips.tsv    مقاطع مفاتيح بتتركّب لأسئلة الحساب (n3 + plus + n4 …)
  tool/phrases.tsv  كل جملة كاملة — بيولّده: flutter test tool/voice_phrases_test.dart

الناتج: assets/audio/clips/<key>.m4a و lib/core/audio/clip_manifest.g.dart.
المقاطع اللي نصها وصوتها ماتغيروش مابتتسجلش تاني (tool/voice_rendered.tsv).

الصوت:
  VOICE=ar-EG-SalmaNeural (الافتراضي، ست) أو ar-EG-ShakirNeural (راجل)
  RATE=-5%  — أبطأ سنة عشان الأطفال؛ المقاطع لوحدها بتاخد سرعتها من phrases.tsv.
  من غير تغيير طبقة الصوت: الـ pitch بيخلّي الصوت العصبي يبان آلي

المحرّك:
  - من غير مفاتيح: edge-tts (pip install edge-tts) — نفس أصوات Azure، للتجربة بس.
    خدمة Edge مش مرخّصة للاستخدام التجاري.
  - للنشر: AZURE_SPEECH_KEY و AZURE_SPEECH_REGION (الباقة المجانية F0 بتكفي؛
    التطبيق كله حوالي ٣٠ ألف حرف). Azure بيدّيك حق استخدام الصوت الناتج تجاريًا.
    شغّل بـ FORCE=1 أول مرة بالمفتاح عشان كل المقاطع تتسجّل من Azure.
"""
import array
import asyncio
import hashlib
import os
import subprocess
import sys
import tempfile
import urllib.request
import wave
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets/audio/clips'
CACHE = ROOT / 'tool/voice_rendered.tsv'
MANIFEST = ROOT / 'lib/core/audio/clip_manifest.g.dart'

VOICE = os.environ.get('VOICE', 'ar-EG-SalmaNeural')
RATE = os.environ.get('RATE', '-5%')
PITCH = os.environ.get('PITCH', '+0Hz')
AZURE_KEY = os.environ.get('AZURE_SPEECH_KEY')
AZURE_REGION = os.environ.get('AZURE_SPEECH_REGION')
ENGINE = 'azure' if AZURE_KEY else 'edge'
# بيتغيّر لما طريقة المعالجة تتغيّر عشان كل المقاطع تتسجّل تاني
PIPELINE = 'trim3'


def read_tsv(path, cols):
    rows = []
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line or line.startswith('#'):
            continue
        parts = line.split('\t')
        parts += [''] * (cols - len(parts))
        parts[2:3] = [parts[2] or parts[1]] if cols > 2 else []
        rows.append(parts[:cols])
    return rows


def ssml(text, rate):
    return (
        "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='ar-EG'>"
        f"<voice name='{VOICE}'><prosody rate='{rate}' pitch='{PITCH}'>{escape(text)}</prosody></voice></speak>"
    )


async def tts_edge(text, rate, mp3):
    import edge_tts

    await edge_tts.Communicate(text, VOICE, rate=rate, pitch=PITCH).save(str(mp3))


def tts_azure(text, rate, mp3):
    req = urllib.request.Request(
        f'https://{AZURE_REGION}.tts.speech.microsoft.com/cognitiveservices/v1',
        data=ssml(text, rate).encode('utf-8'),
        headers={
            'Ocp-Apim-Subscription-Key': AZURE_KEY,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
            'User-Agent': 'rehlati-render-voice',
        },
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        mp3.write_bytes(r.read())


def trim(src, dst, lead_ms=40, tail_ms=90, threshold=600):
    """يشيل السكوت من أول وآخر المقطع — المحرّك بيحط حوالي نص ثانية في كل ناحية،
    وده بيبان كفراغ طويل لما مقاطع الحساب بتتركّب ورا بعض."""
    with wave.open(str(src)) as w:
        rate, params = w.getframerate(), w.getparams()
        pcm = array.array('h', w.readframes(w.getnframes()))
    win = rate // 100  # ١٠ مللي ثانية
    loud = [i for i in range(0, len(pcm), win) if max(map(abs, pcm[i:i + win]), default=0) > threshold]
    if loud:
        start = max(0, loud[0] - rate * lead_ms // 1000)
        end = min(len(pcm), loud[-1] + win + rate * tail_ms // 1000)
        pcm = pcm[start:end]
    with wave.open(str(dst), 'wb') as w:
        w.setparams(params)
        w.writeframes(pcm.tobytes())


def convert(*args):
    subprocess.run(['afconvert', *map(str, args)], check=True, capture_output=True)


async def render(key, spoken, rate, tmp, sem):
    mp3 = Path(tmp) / f'{key}.mp3'
    async with sem:
        for attempt in range(4):
            try:
                if ENGINE == 'azure':
                    await asyncio.to_thread(tts_azure, spoken, rate, mp3)
                else:
                    await tts_edge(spoken, rate, mp3)
                break
            except Exception as e:  # الشبكة بتقع أحيانًا — نحاول تاني
                if attempt == 3:
                    raise RuntimeError(f'{key}: {spoken}: {e}') from e
                await asyncio.sleep(2 * (attempt + 1))
        raw, cut = Path(tmp) / f'{key}.wav', Path(tmp) / f'{key}.cut.wav'
        await asyncio.to_thread(convert, '-f', 'WAVE', '-d', 'LEI16', mp3, raw)
        await asyncio.to_thread(trim, raw, cut)
        # AAC ٣٢ كيلوبت مونو: واضح للكلام وحجمه نص الـ mp3
        await asyncio.to_thread(convert, '-f', 'm4af', '-d', 'aac', '-b', '32000', cut, OUT / f'{key}.m4a')


async def main():
    clips = read_tsv(ROOT / 'tool/clips.tsv', 4)
    phrases_path = ROOT / 'tool/phrases.tsv'
    if not phrases_path.exists():
        sys.exit('tool/phrases.tsv missing — run: flutter test tool/voice_phrases_test.dart')
    phrases = read_tsv(phrases_path, 4)
    if ENGINE == 'azure' and not AZURE_REGION:
        sys.exit('set AZURE_SPEECH_REGION too (e.g. westeurope)')

    OUT.mkdir(parents=True, exist_ok=True)
    done = dict(row[:2] for row in read_tsv(CACHE, 2)) if CACHE.exists() else {}
    force = os.environ.get('FORCE') == '1'
    wanted = {}
    for key, _text, spoken, rate in clips + phrases:
        rate = rate or RATE
        h = hashlib.sha1(f'{PIPELINE}|{ENGINE}|{VOICE}|{rate}|{PITCH}|{spoken}'.encode()).hexdigest()
        wanted[key] = (spoken, rate, h)

    todo = [
        (k, s, r) for k, (s, r, h) in wanted.items()
        if force or done.get(k) != h or not (OUT / f'{k}.m4a').exists()
    ]
    print(f'{ENGINE} · {VOICE} · {len(todo)} to render of {len(wanted)}')
    sem = asyncio.Semaphore(6)
    with tempfile.TemporaryDirectory() as tmp:
        jobs = [render(k, s, r, tmp, sem) for k, s, r in todo]
        for i, job in enumerate(asyncio.as_completed(jobs), 1):
            await job
            if i % 50 == 0 or i == len(jobs):
                print(f'  {i}/{len(jobs)}')

    # مقاطع قديمة مابقتش مستخدمة
    for f in OUT.glob('*'):
        if f.stem not in wanted or f.suffix != '.m4a':
            f.unlink()

    CACHE.write_text(
        '# GENERATED by tool/render_voice.py — key, render hash\n'
        + ''.join(f'{k}\t{h}\n' for k, (_, _, h) in sorted(wanted.items())),
        encoding='utf-8',
    )
    clip_keys = [k for k, *_ in clips]
    phrase_keys = sorted(k for k, *_ in phrases)
    MANIFEST.write_text(
        '// GENERATED by tool/render_voice.py — do not edit.\n'
        "const clipKeys = <String>{\n" + ''.join(f"  '{k}',\n" for k in clip_keys) + '};\n\n'
        "/// مقاطع الجُمل الكاملة: SpeechService.phraseKey(نص الجملة).\n"
        "const phraseKeys = <String>{\n" + ''.join(f"  '{k}',\n" for k in phrase_keys) + '};\n',
        encoding='utf-8',
    )
    size = sum(f.stat().st_size for f in OUT.glob('*.m4a'))
    print(f'{len(wanted)} clips, {size / 1e6:.1f} MB → {OUT.relative_to(ROOT)}')


asyncio.run(main())
