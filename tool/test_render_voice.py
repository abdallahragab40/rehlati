"""Offline checks: python3 -m unittest discover -s tool -p 'test_render_voice.py'."""
import asyncio
import contextlib
import io
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest.mock import AsyncMock, patch

import render_voice as voice


class RenderVoiceTests(unittest.TestCase):
    def test_ssml_uses_selected_locale_and_escapes_text(self):
        with patch.object(voice, 'VOICE', 'ar-SA-ZariyahNeural'):
            root = ET.fromstring(voice.ssml('بَ & <', '-15%'))
        self.assertEqual(root.attrib['{http://www.w3.org/XML/1998/namespace}lang'], 'ar-SA')
        self.assertEqual(''.join(root.itertext()), 'بَ & <')

    def test_teaching_words_match_app_inventory(self):
        import re
        source = (voice.ROOT / 'lib/content/language_data.dart').read_text()
        ar_source = source.split('const enLetters')[0]
        letter_words = re.findall(r"Letter\('[^']*', '([^']*)'", ar_source)
        reading_words = re.findall(r"Word\('([^']*)'", ar_source)
        rows = voice.read_tsv(voice.ROOT / 'tool/teaching.tsv', 4)
        strip = lambda s: re.sub(r'[\u064b-\u0652]', '', s)
        self.assertEqual([strip(r[1]) for r in rows if r[0].endswith('_word')], letter_words)
        self.assertEqual([strip(r[1]) for r in rows if r[0].startswith('w_')], reading_words)
        self.assertEqual(len({r[0] for r in rows}), len(rows), 'teaching keys must be unique')
        self.assertEqual(len([r for r in rows if '_tanween_' in r[0]]), 82)
        self.assertEqual(len([r for r in rows if r[0].startswith('sukun_')]), 15)

    def test_dry_run_never_renders_or_writes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'tool').mkdir()
            (root / 'tool/teaching.tsv').write_text('l_ba_fatha\tبَ\tبَ\t-15%\n')
            render = AsyncMock()
            with patch.multiple(voice, ROOT=root, OUT=root / 'assets', CACHE=root / 'cache', VOICE=voice.VOICE, ENGINE='edge'), patch.object(voice, 'render', render), patch('sys.argv', ['render_voice.py', '--pack', 'teaching', '--dry-run']), contextlib.redirect_stdout(io.StringIO()):
                asyncio.run(voice.main())
            render.assert_not_called()
            self.assertFalse((root / 'build').exists())

    def test_preview_preserves_app_audio_manifest_and_unrelated_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'tool').mkdir()
            (root / 'tool/teaching.tsv').write_text('l_ba_fatha\tبَ\tبَ\t-15%\n')
            manifest = root / 'manifest.dart'
            manifest.write_text('existing manifest')
            app_audio = root / 'assets'
            app_audio.mkdir()
            (app_audio / 'existing.m4a').write_bytes(b'app audio')
            out = root / 'build/voice-preview/edge/ar-SA-ZariyahNeural/teaching'
            out.mkdir(parents=True)
            (out / 'review.txt').write_text('keep this')
            async def fake_render(key, *args):
                (voice.OUT / f'{key}.m4a').write_bytes(b'preview')
            with patch.multiple(voice, ROOT=root, OUT=app_audio, CACHE=root / 'cache', MANIFEST=manifest, VOICE=voice.VOICE, ENGINE='edge'), patch.object(voice, 'render', fake_render), patch('sys.argv', ['render_voice.py', '--pack', 'teaching', '--engine', 'edge']), contextlib.redirect_stdout(io.StringIO()):
                asyncio.run(voice.main())
            self.assertEqual(manifest.read_text(), 'existing manifest')
            self.assertEqual((app_audio / 'existing.m4a').read_bytes(), b'app audio')
            self.assertTrue((out / 'review.txt').exists())
            self.assertIn('l_ba_fatha.m4a', (out / 'index.html').read_text())
            self.assertTrue((out / 'rendered.tsv').exists())


if __name__ == '__main__':
    unittest.main()
