#!/usr/bin/env python3
"""يسجّل كل أصوات التطبيق: العربي بصوت شاكر (ar-EG-ShakirNeural) والإنجليزي بصوت Ana
(en-US-AnaNeural) — Microsoft Neural TTS. الاختيار ده من العميل (٣٠ أكتوبر ٢٠٢٦).

المصادر:
  tool/clips.tsv      مقاطع مفاتيح بتتركّب لأسئلة الحساب (n3 + plus + n4 …)
  tool/phrases.tsv    كل جملة كاملة — بيولّده: flutter test tool/voice_phrases_test.dart
  tool/teaching.tsv   الحروف والمقاطع والكلمات مشكولة بالفصحى (lib/core/audio/teaching.dart)
  tool/phrases_en.tsv الإنجليزي جملة جملة — بيولّده نفس الاختبار
  tool/pronounce.tsv  تشكيل للصوت بس: الكلمة زي ما مكتوبة ← إزاي تتنطق (clips و phrases)

الناتج: assets/audio/clips/<key>.m4a و lib/core/audio/clip_manifest.g.dart.
المقاطع اللي نصها وصوتها ماتغيروش مابتتسجلش تاني (tool/voice_rendered.tsv).

تسجيلات بشرية: tool/recordings/<key>.wav بياخد مكان الصوت المولّد للمقطع ده (نفس التقطيع والتحويل).
قايمة التسجيل والمواصفات في tool/HUMAN_VOICE_PILOT.md.

الصوت:
  VOICE=ar-EG-ShakirNeural (الافتراضي، راجل مصري) — نفس الصوت لكل المقاطع العربي
  TEACH_VOICE=VOICE — صوت قسم الحروف (teaching.tsv) لوحده: الفصحى بصوت مش مصري لو العميل اختار كده
  VOICE=gemini:Charon — جمل العربي بمحرك Gemini (صوت Charon أو Kore…)، والحروف بتفضل بشاكر
    والإنجليزي بـ Ana. GEMINI_API_KEY في tool/.env، والموديل GEMINI_TTS_MODEL (افتراضي lite).
    محتاج الباقة المدفوعة (المجانية ١٠ مقاطع في اليوم). --max بيمنع تشغيلة أكبر من العدد ده.
    تجربة من غير ما نلمس التطبيق: --pack pilot --count 300 ← build/voice-preview/gemini/<voice>/pilot/
  FUSHA_VOICE=VOICE — صوت جمل الفصحى (نصوص القراءة والأناشيد وأمثلة القواعد) — is_fusha()
  EN_VOICE=en-US-AnaNeural (صوت طفلة) على EN_RATE=-15% = سرعة "عادي" في الإعدادات
  RATE=-5%  — أبطأ سنة عشان الأطفال؛ المقاطع لوحدها بتاخد سرعتها من phrases.tsv.
  من غير تغيير طبقة الصوت: الـ pitch بيخلّي الصوت العصبي يبان آلي

المحرّك:
  - من غير مفاتيح: edge-tts (pip install edge-tts) — نفس أصوات Azure، للتجربة بس.
    خدمة Edge مش مرخّصة للاستخدام التجاري.
  - للنشر: AZURE_SPEECH_KEY و AZURE_SPEECH_REGION على مورد مدفوع S0. حقوق الاستخدام التجاري
    للصوت الناتج مخصصة للباقة المدفوعة حسب شروط Microsoft، مش F0.
    شغّل بـ FORCE=1 أول مرة بالمفتاح عشان كل المقاطع تتسجّل من Azure.
"""
import argparse
import array
import asyncio
import hashlib
import html
import os
import re
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
RECORDINGS = ROOT / 'tool/recordings'
HUMAN = 'human'
MANIFEST = ROOT / 'lib/core/audio/clip_manifest.g.dart'

VOICE = os.environ.get('VOICE', 'ar-EG-ShakirNeural')
# الحروف والمقاطع: شاكر اتقيّم صح فيها، فبتفضل بيه حتى لو الجمل راحت لـ Gemini
TEACH_VOICE = os.environ.get('TEACH_VOICE') or ('ar-EG-ShakirNeural' if VOICE.startswith('gemini:') else VOICE)
GEMINI_KEY = os.environ.get('GEMINI_API_KEY')
GEMINI_MODEL = os.environ.get('GEMINI_TTS_MODEL', 'gemini-3.8-flash-lite-tts')
FUSHA_VOICE = os.environ.get('FUSHA_VOICE') or VOICE
EN_VOICE = os.environ.get('EN_VOICE', 'en-US-AnaNeural')
EN_RATE = os.environ.get('EN_RATE', '-15%')
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


def read_lexicon(path):
    """tool/pronounce.tsv: الكلمة زي ما مكتوبة ← نطقها المشكول."""
    if not path.exists():
        return {}
    return {w: say for w, say in (r[:2] for r in read_tsv(path, 2)) if w and say}


_WORD = re.compile('[\u0621-\u0652\u0640]+')


def voiced(text, lexicon):
    """بيبدّل الكلمات اللي مالهاش تشكيل بنطقها من القاموس — الكلمة المشكولة بتفضل زي ما هي."""
    return _WORD.sub(lambda m: lexicon.get(m.group(), m.group()), text)


# كلمات بتقول إن الجملة عامية مصرية، وكلمات بتقول إنها فصحى
_EGY = set('ده دي دول اللي إيه ايه مش كام عشان علشان بتاع يلا إزاي ازاي فين زي بقى كده دلوقتي عايز عايزة '
           'مفيش ليه بص خلي خلّي إحنا احنا برضه أوي خالص تاني يبقى لسه بس مين امتى إمتى اتنين تلاتة '
           'معاها معاه معاك أخد أخدت بقوا بقت عندي عنده كمان يعني طب'.split())
# من غير الكلمات اللي العامية بتستخدمها كمان (كان، لأن، عن، قد، إن)
_FUSHA = set('ثم إذن الذي التي الذين ماذا لماذا كيف هذا هذه هؤلاء ذلك تلك أين متى نحن لكن أن '
             'لم لن ليس ليست عندما أيضًا أيضا إلى'.split())
_EGY_VERB = re.compile('^(?:و?)(?:بي|بت|بن|هي|هت|هن|ها)[\u0621-\u064A]{2,}$')
_CASE = re.compile('[\u0621-\u064A][\u064B-\u0650]$')
# «فـ» لازقة في فعل للمتكلم (فأجد، فأعرف) أسلوب فصحى
_FA_VERB = re.compile('^فأ[\u0621-\u064A]{2,}$')


def is_fusha(text):
    """جملة فصحى: قاموس النطق المصري مايتطبقش عليها، وبتاخد FUSHA_VOICE.

    فيها كلمات فصحى (أو كلمتين بعلامة إعراب في آخرهم) ومفيهاش ولا كلمة عامية."""
    words = [re.sub('[^\u0621-\u0652]', '', w) for w in text.split()]
    bare = [re.sub('[\u064B-\u0652]', '', w) for w in words]
    if any(w in _EGY or _EGY_VERB.match(w) for w in bare):
        return False
    return (any(w in _FUSHA or _FA_VERB.match(w) for w in bare)
            or sum(1 for w in words if _CASE.search(w)) >= 2)


GEMINI_STYLE = {
    'egy': 'Say the following in Egyptian Arabic (Cairo), like a friendly teacher talking to a child, '
           'at a natural, brisk everyday pace. Say only the text, exactly:\n',
    'fusha': 'Say the following in Modern Standard Arabic, like a friendly teacher, at a natural, brisk pace, '
             'with every vowel exactly as marked. Say only the text, exactly:\n',
}


def tts_gemini(text, voice, wav):
    """voice = 'gemini:Charon' أو 'gemini:Charon|fusha'. الناتج WAV مونو ٢٤ كيلوهرتز."""
    import base64, json
    name, _, reg = voice.split(':', 1)[1].partition('|')
    body = {'contents': [{'parts': [{'text': GEMINI_STYLE[reg or 'egy'] + text}]}],
            'generationConfig': {'responseModalities': ['AUDIO'],
                                 'speechConfig': {'voiceConfig': {'prebuiltVoiceConfig': {'voiceName': name}}}}}
    req = urllib.request.Request(
        f'https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent',
        data=json.dumps(body).encode(), headers={'x-goog-api-key': GEMINI_KEY, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=120) as r:
        d = json.load(r)
    pcm = base64.b64decode(d['candidates'][0]['content']['parts'][0]['inlineData']['data'])
    if pcm[:4] == b'RIFF':
        wav.write_bytes(pcm)
    else:
        with wave.open(str(wav), 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(24000)
            w.writeframes(pcm)


def ssml(text, rate, voice=None):
    voice = voice or VOICE
    locale = '-'.join(voice.split('-')[:2])
    return (
        f"<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='{escape(locale)}'>"
        f"<voice name='{voice}'><prosody rate='{rate}' pitch='{PITCH}'>{escape(text)}</prosody></voice></speak>"
    )


async def tts_edge(text, rate, mp3, voice=None):
    import edge_tts

    await edge_tts.Communicate(text, voice or VOICE, rate=rate, pitch=PITCH).save(str(mp3))


def tts_azure(text, rate, mp3, voice=None):
    req = urllib.request.Request(
        f'https://{AZURE_REGION}.tts.speech.microsoft.com/cognitiveservices/v1',
        data=ssml(text, rate, voice).encode('utf-8'),
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


PAUSE, PAUSE_MS = 'pause', 350


def silence(tmp):
    """فاصل سكوت بين الحرف ومقاطعه في لوحة الحروف — المقاطع بعد التقطيع بتلزق في بعض."""
    wav = tmp / f'{PAUSE}.wav'
    with wave.open(str(wav), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(24000)
        w.writeframes(b'\0\0' * (24000 * PAUSE_MS // 1000))
    convert('-f', 'm4af', '-d', 'aac', '-b', '32000', wav, OUT / f'{PAUSE}.m4a')


def convert(*args):
    subprocess.run(['afconvert', *map(str, args)], check=True, capture_output=True)


async def render(key, spoken, rate, tmp, sem, voice=None):
    if voice == HUMAN:
        return await render_recording(key, tmp, sem)
    mp3 = Path(tmp) / f'{key}.mp3'
    gemini = (voice or '').startswith('gemini:')
    raw = Path(tmp) / f'{key}.wav'
    async with sem:
        for attempt in range(6):
            try:
                if gemini:
                    await asyncio.to_thread(tts_gemini, spoken, voice, raw)
                elif ENGINE == 'azure':
                    await asyncio.to_thread(tts_azure, spoken, rate, mp3, voice)
                else:
                    await tts_edge(spoken, rate, mp3, voice)
                break
            except Exception as e:  # الشبكة بتقع أحيانًا — نحاول تاني
                if attempt == 5:
                    raise RuntimeError(f'{key}: {spoken}: {e}') from e
                # Gemini بيقول 429 لما الحد يخلص — نستنى أطول
                await asyncio.sleep((20 if gemini else 3) * (attempt + 1))
        cut = Path(tmp) / f'{key}.cut.wav'
        if not gemini:
            await asyncio.to_thread(convert, '-f', 'WAVE', '-d', 'LEI16', mp3, raw)
        await asyncio.to_thread(trim, raw, cut)
        # AAC ٣٢ كيلوبت مونو: واضح للكلام وحجمه نص الـ mp3
        await asyncio.to_thread(convert, '-f', 'm4af', '-d', 'aac', '-b', '32000', cut, OUT / f'{key}.m4a')


def recording_hash(key):
    """بصمة التسجيل البشري للمقطع، أو None لو مفيش تسجيل."""
    wav = RECORDINGS / f'{key}.wav'
    if not wav.exists():
        return None
    return f'{HUMAN}|{PIPELINE}|' + hashlib.sha1(wav.read_bytes()).hexdigest()


async def render_recording(key, tmp, sem):
    """تسجيل المعلّمة: مونو ١٦ بت (أي معدل أو عدد قنوات داخل) ← تقطيع السكوت ← AAC."""
    async with sem:
        raw, cut = Path(tmp) / f'{key}.wav', Path(tmp) / f'{key}.cut.wav'
        await asyncio.to_thread(convert, '-f', 'WAVE', '-d', 'LEI16@24000', '-c', '1', RECORDINGS / f'{key}.wav', raw)
        await asyncio.to_thread(trim, raw, cut)
        await asyncio.to_thread(convert, '-f', 'm4af', '-d', 'aac', '-b', '32000', cut, OUT / f'{key}.m4a')


async def main():
    global OUT, CACHE, VOICE, ENGINE
    parser = argparse.ArgumentParser(description='Render existing app audio or isolated teaching previews.')
    parser.add_argument('--pack', choices=['existing', 'teaching', 'pilot'], default='existing')
    parser.add_argument('--count', type=int, default=300, help='pilot: how many random Arabic lines')
    parser.add_argument('--max', type=int, default=400, help='refuse a Gemini run larger than this (cost guard)')
    parser.add_argument('--voice', default=None, help='Teaching preview voice; defaults to VOICE')
    parser.add_argument('--engine', choices=['azure', 'edge'], default=None)
    parser.add_argument('--dry-run', action='store_true', help='List inputs without network calls or file writes')
    args = parser.parse_args()
    if args.engine:
        ENGINE = args.engine
    preview = args.pack != 'existing'
    if preview:
        VOICE = args.voice or VOICE
        if not all(c.isalnum() or c in '-_:' for c in VOICE):
            sys.exit('voice must contain only letters, digits, hyphens, underscores or a gemini: prefix')
        OUT = ROOT / 'build/voice-preview' / ('gemini' if VOICE.startswith('gemini:') else ENGINE) / VOICE.replace(':', '-') / args.pack
        CACHE = OUT / 'rendered.tsv'
        phrases = english = []
        if args.pack == 'pilot':
            # عيّنة عشوائية ثابتة من جمل التطبيق العربي — نفس الجمل في كل تشغيلة عشان المقارنة
            import random
            rows = [r for r in read_tsv(ROOT / 'tool/phrases.tsv', 4) if not re.search('[A-Za-z]', r[1])]
            clips = random.Random(14).sample(rows, min(args.count, len(rows)))
            lexicon = read_lexicon(ROOT / 'tool/pronounce.tsv')
            if not VOICE.startswith('gemini:'):
                clips = [[k, t, s if is_fusha(t) else voiced(s, lexicon), r] for k, t, s, r in clips]
            fusha_keys = {k for k, t, *_ in clips if is_fusha(t)}
        else:
            clips = read_tsv(ROOT / 'tool/teaching.tsv', 4)
            fusha_keys = set()
    else:
        lexicon = read_lexicon(ROOT / 'tool/pronounce.tsv')
        clips = [[k, t, voiced(s, lexicon), r] for k, t, s, r in read_tsv(ROOT / 'tool/clips.tsv', 4)]
        phrases_path = ROOT / 'tool/phrases.tsv'
        if not phrases_path.exists():
            sys.exit('tool/phrases.tsv missing — run: flutter test tool/voice_phrases_test.dart')
        # الفصحى مابتعدّيش على قاموس النطق المصري (الموز ← المُوز كان بيبوّظ «والموزَ»)
        # Gemini بيقرا العامية صح من غير القاموس، فالقاموس لصوت Azure بس
        plain = VOICE.startswith('gemini:')
        phrases = [[k, t, s if plain or is_fusha(t) else voiced(s, lexicon), r] for k, t, s, r in read_tsv(phrases_path, 4)]
        fusha_keys = {k for k, t, *_ in phrases if is_fusha(t)}
        teaching = read_tsv(ROOT / 'tool/teaching.tsv', 4)
        en_path = ROOT / 'tool/phrases_en.tsv'
        english = [[k, t, s, EN_RATE] for k, t, s, _ in read_tsv(en_path, 4)] if en_path.exists() else []
    if args.dry_run:
        rows = clips + phrases + ([] if preview else teaching) + english
        print(f'{ENGINE} · {VOICE} · {len(rows)} clips · {OUT.relative_to(ROOT)}')
        for key, text, spoken, rate in rows:
            print(f'{key}\t{text}\t{spoken}\t{rate or RATE}')
        return
    if ENGINE == 'azure' and not AZURE_KEY:
        sys.exit('set AZURE_SPEECH_KEY locally; never commit it')
    if ENGINE == 'azure' and not AZURE_REGION:
        sys.exit('set AZURE_SPEECH_REGION too (e.g. westeurope)')

    OUT.mkdir(parents=True, exist_ok=True)
    done = dict(row[:2] for row in read_tsv(CACHE, 2)) if CACHE.exists() else {}
    force = os.environ.get('FORCE') == '1'
    wanted = {}
    en_keys = {k for k, *_ in english}
    teach_keys = set() if preview else {k for k, *_ in teaching}
    for key, _text, spoken, rate in clips + phrases + ([] if preview else teaching) + english:
        voice = (EN_VOICE if key in en_keys else TEACH_VOICE if key in teach_keys
                 else FUSHA_VOICE if key in fusha_keys else VOICE)
        if voice.startswith('gemini:') and key in fusha_keys:
            voice += '|fusha'
        rate = rate or RATE
        h = hashlib.sha1(f'{PIPELINE}|{ENGINE}|{voice}|{rate}|{PITCH}|{spoken}'.encode()).hexdigest()
        human = None if preview else recording_hash(key)
        wanted[key] = (spoken, rate, HUMAN, human) if human else (spoken, rate, voice, h)
    if not preview:
        wanted[PAUSE] = (None, None, None, f'silence|{PAUSE_MS}')

    todo = [
        (k, s, r, v) for k, (s, r, v, h) in wanted.items()
        if s is not None and (force or done.get(k) != h or not (OUT / f'{k}.m4a').exists())
    ]
    print(f'{ENGINE} · {VOICE} + {EN_VOICE} · {len(todo)} to render of {len(wanted)}')
    on_gemini = [t for t in todo if (t[3] or '').startswith('gemini:')]
    if on_gemini:
        if not GEMINI_KEY:
            sys.exit('set GEMINI_API_KEY in tool/.env; never commit it')
        chars = sum(len(t[1]) for t in on_gemini)
        print(f'gemini {GEMINI_MODEL}: {len(on_gemini)} clips, {chars} characters')
        if len(on_gemini) > args.max:
            sys.exit(f'{len(on_gemini)} Gemini clips is more than --max {args.max}; raise --max on purpose')
    sem = asyncio.Semaphore(6)
    failed = {}

    async def attempt(k, s, r, v):
        try:
            await render(k, s, r, tmp, sem, v)
        except RuntimeError as e:  # مقطع واحد مايوقفش الباقي؛ بيتسجل في التشغيلة الجاية
            failed[k] = str(e)

    with tempfile.TemporaryDirectory() as tmp:
        jobs = [attempt(k, s, r, v) for k, s, r, v in todo]
        if not preview:
            silence(Path(tmp))
        for i, job in enumerate(asyncio.as_completed(jobs), 1):
            await job
            if i % 50 == 0 or i == len(jobs):
                print(f'  {i}/{len(jobs)}')

    # مقاطع قديمة مابقتش مستخدمة
    for f in OUT.glob('*.m4a'):
        if f.stem not in wanted:
            f.unlink()

    CACHE.write_text(
        '# GENERATED by tool/render_voice.py — key, render hash\n'
        + ''.join(f'{k}\t{h}\n' for k, (*_, h) in sorted(wanted.items()) if k not in failed),
        encoding='utf-8',
    )
    clip_keys = [k for k, *_ in clips] + ([] if preview else [k for k, *_ in teaching] + [PAUSE])
    phrase_keys = sorted(k for k, *_ in phrases)
    if not preview:
        version = hashlib.sha1(''.join(f'{k}{h}' for k, (*_, h) in sorted(wanted.items())).encode()).hexdigest()[:12]
        MANIFEST.write_text(
            '// GENERATED by tool/render_voice.py — do not edit.\n'
            "/// بصمة المقاطع: بتتغيّر لما أي مقطع يتسجّل تاني — refreshAudioAssetCache بيمسح الكاش ساعتها.\n"
            f"const clipsVersion = '{version}';\n\n"
            "const clipKeys = <String>{\n" + ''.join(f"  '{k}',\n" for k in clip_keys) + '};\n\n'
            "/// مقاطع الجُمل الكاملة: SpeechService.phraseKey(نص الجملة).\n"
            "const phraseKeys = <String>{\n" + ''.join(f"  '{k}',\n" for k in phrase_keys) + '};\n\n'
            "/// مقاطع الإنجليزي جملة جملة: SpeechService.enKey(الجملة).\n"
            "const enPhraseKeys = <String>{\n" + ''.join(f"  '{k}',\n" for k in sorted(en_keys)) + '};\n',
            encoding='utf-8',
        )
    if preview:
        rows = ''.join(
            f'<tr><td>{html.escape(key)}</td><td lang="ar" dir="rtl">{html.escape(text)}</td>'
            f'<td><audio controls preload="none" src="{key}.m4a"></audio></td></tr>'
            for key, text, _, _ in clips
        )
        page = ('<!doctype html><html lang="en"><meta charset="utf-8">'
                '<meta name="viewport" content="width=device-width,initial-scale=1">'
                '<title>Arabic pronunciation review</title>'
                '<style>body{font:18px system-ui;margin:24px}td{padding:12px;border-bottom:1px solid #ddd}'
                '[lang=ar]{font-size:32px}audio{max-width:100%}</style>'
                f'<h1>{html.escape(VOICE)}</h1><p>Engine: {ENGINE}. Preview audio has not been approved for shipping.</p>'
                '<p>Check consonants, short vowels, shadda, word endings, and clipping. '
                'أَ / أُ / إِ demonstrate hamza, not long alif.</p>'
                '<table><tr><th>Clip</th><th>Intended pronunciation</th><th>Listen</th></tr>'
                + rows + '</table></html>')
        (OUT / 'index.html').write_text(page, encoding='utf-8')
    size = sum(f.stat().st_size for f in OUT.glob('*.m4a'))
    print(f'{len(wanted)} clips, {size / 1e6:.1f} MB → {OUT.relative_to(ROOT)}')
    if failed:
        for msg in failed.values():
            print(f'  ✗ {msg}')
        sys.exit(f'{len(failed)} clips failed — run again to retry just those')


if __name__ == '__main__':
    asyncio.run(main())
